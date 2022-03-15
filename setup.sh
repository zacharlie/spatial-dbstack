#!/bin/bash

if [ "$EUID" = 0 ]; then
  echo "Running with super user privileges"
else
    # expects sudo caching enabled
    sudo -k # ask for password
    if sudo true; then
        echo "Correct password entered."
    else
        echo "Wrong password. Exiting."
        exit 1
    fi
fi

# install dependencies
# check for gitpod user
if id "gitpod" &>/dev/null; then
    echo 'provisioning for gitpod'
    install-packages apt-transport-https ca-certificates gnupg pwgen openssl apache2-utils sqlite3
else
    echo 'setup dependencies'
    apt update && apt-transport-https ca-certificates gnupg pwgen openssl apache2-utils sqlite3
fi

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Exclude files from git that might leak sensitive info after setup
git update-index --assume-unchanged $THISDIR/config/nginx/webusers
git update-index --assume-unchanged $THISDIR/config/sql/setup.sql

this_user=$(id -u)
this_group=$(id -g)

chown -R $this_user:$this_group $THISDIR/data
chmod +x $THISDIR/config/ssl/generate-dhparam.sh
$THISDIR/config/ssl/generate-dhparam.sh
chmod +x $THISDIR/config/ssl/generate-sscerts.sh
$THISDIR/config/ssl/generate-sscerts.sh

# write out variables/ results to config/secrets file that users can review
secrets_file=$THISDIR/secrets/secrets
echo > $secrets_file
chown $this_user:$this_group $secrets_file
echo "System Secrets" > $secrets_file  # instantiate with header

# bcrypt password for filemanager
FILES_CONF=$THISDIR/config/filebrowser/filebrowser.json
FILES_PW=sEi4uA89V0i7pio0KFyW
echo "FILES_PW: ${FILES_PW}" >> $secrets_file
FILES_PW_HASH=`htpasswd -bnBC 10 "" ${FILES_PW} | tr -d ':\n' | sed 's/$2y/$2a/'`
sed -i "s/^\"password\".*/\"password\"\: \"${FILES_PW_HASH}\"/g" $FILES_CONF

# Set secrets and add to secrets file
WEB_U=dbstack
WEB_PW=vZLqAMychaH4nBwfOtTb
DB_USER=dbstack
DB_PW=$(pwgen -s 64 1)
PGRST_U=api_user
PGRST_PW=$(pwgen -s 64 1)
PGADMIN_U=dbstack@local.host
PGADMIN_PW=$(pwgen -s 64 1)
GRAFANA_ADMIN_USER=${WEB_U}
GRAFANA_ADMIN_PASS=${WEB_PW}

echo "WEB_U: ${WEB_U}" >> $secrets_file
echo "WEB_PW: ${WEB_PW}" >> $secrets_file
echo "DB_USER: ${DB_USER}" >> $secrets_file
echo "DB_PW: ${DB_PW}" >> $secrets_file
echo "PGRST_U: ${PGRST_U}" >> $secrets_file
echo "PGRST_PW: ${PGRST_PW}" >> $secrets_file
echo "PGADMIN_U: ${PGADMIN_U}" >> $secrets_file
echo "PGADMIN_PW: ${PGADMIN_PW}" >> $secrets_file
echo "GRAFANA_ADMIN_USER: ${GRAFANA_ADMIN_USER}" >> $secrets_file
echo "GRAFANA_ADMIN_PASS: ${GRAFANA_ADMIN_PASS}" >> $secrets_file

# create web users
htpasswd -b -B -C10 -c $THISDIR/config/nginx/webusers ${WEB_U} ${WEB_PW}
# htpasswd -b -B -C10 $THISDIR/config/nginx/webusers ${GRAFANA_ADMIN_USER} ${GRAFANA_ADMIN_PASS}  # currently duplicates web user

# Copy ENV and configure secrets
cp $THISDIR/.env.example $THISDIR/.env
sed -i "s/^POSTGRES_USER=.*/POSTGRES_USER=$DB_USER/g" $THISDIR/.env
sed -i "s/^POSTGRES_PASS=.*/POSTGRES_PASS=$DB_PW/g" $THISDIR/.env
sed -i "s/^PGRST_DB_USER=.*/PGRST_DB_USER=$PGRST_U/g" $THISDIR/.env
sed -i "s/^PGRST_DB_PASS=.*/PGRST_DB_PASS=$PGRST_PW/g" $THISDIR/.env
sed -i "s/^GRAFANA_ADMIN_USER=.*/GRAFANA_ADMIN_USER=$GRAFANA_ADMIN_USER/g" $THISDIR/.env
sed -i "s/^GRAFANA_ADMIN_PASS=.*/GRAFANA_ADMIN_PASS=$GRAFANA_ADMIN_PASS/g" $THISDIR/.env

# Replace sensitive data in SQL files
sed -i "s/'{{API_USER_PASSWORD}}'/'${PGRST_PW}'/g" $THISDIR/config/sql/setup.sql

# configure uptime kuma using sample database as a template
KUMA_DB=$THISDIR/config/kuma/kuma.db
cp $THISDIR/config/kuma/kuma.db.example $KUMA_DB

KUMA_PW=$(pwgen -s 64 1)
echo "KUMA_PW: ${KUMA_PW}" >> $secrets_file
# Get password as bcrypt hash value
KUMA_PW_HASH=`htpasswd -bnBC 10 "" ${KUMA_PW} | tr -d ':\n' | sed 's/$2y/$2a/'`

# Set unique JWT secret
KUMA_JWT=`htpasswd -bnBC 10 "" $(pwgen -s 64 1) | tr -d ':\n' | sed 's/$2y/$2a/'`
# echo "KUMA_JWT: ${KUMA_JWT}" >> $secrets_file

KUMA_SQL="
UPDATE user
SET \"username\" = 'dbstack',
    \"password\" = '${KUMA_PW_HASH}'
WHERE
    \"username\" = 'dbstack'
LIMIT 1;

UPDATE setting
SET \"jwtSecret\" = '${KUMA_JWT}'
WHERE
    \"key\" = 'jwtSecret'
LIMIT 1;
"

# execute sql
sqlite3 $KUMA_DB $KUMA_SQL
