#!/usr/bin/env bash
:'
# expects sudo caching enabled
if [ "$EUID" = 0 ]; then
  echo "Running with super user privileges"
else
    sudo -k # ask for password
    if sudo true; then
        echo "Correct password entered."
    else
        echo "Wrong password. Exiting."
        exit 1
    fi
fi

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# groupadd docker
# usermod -aG docker $(id -u)
# chown -R $(id -u):$(id -g docker) $THISDIR/config
# chown -R 1000:1000 $THISDIR/config
# chmod +x $THISDIR/config/ssl/generate-dhparam.sh
# $THISDIR/generate-dhparam.sh
# chmod +x $THISDIR/config/ssl/generate-sscerts.sh
# $THISDIR/generate-sscerts.sh

apt update && apt upgrade -y && docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions

cp $THISDIR/.env.example $THISDIR/.env

WEBU="dbstack"
WEBPW="vZLqAMychaH4nBwfOtTb"
DBUSER="dbstack"
# DBPW="$(pwgen -s 64 1)"
DBPW="secure_password"

# htpasswd -b -B -C10 -c $THISDIR/config/nginx/webusers username password


# write out variables/ results to config/secrets file that users can review
echo "System Secrets" > $THISDIR/config/secrets
echo "WEBU: ${WEBU}" >> $THISDIR/config/secrets
echo "WEBPW: ${WEBPW}" >> $THISDIR/config/secrets
echo "DBUSER: ${DBUSER}" >> $THISDIR/config/secrets
echo "DBPW: ${DBPW}" >> $THISDIR/config/secrets

sed -i "s/^PGRST_DB_USER=.*/PGRST_DB_USER=$DBUSER/g" $THISDIR/.env
sed -i "s/^PGRST_DB_PASS=.*/PGRST_DB_PASS=$DBPW/g" $THISDIR/.env
sed -i "s/^GRAFANA_ADMIN_USER=.*/GRAFANA_ADMIN_USER=$WEBU/g" $THISDIR/.env
sed -i "s/^GRAFANA_ADMIN_PASS=.*/GRAFANA_ADMIN_USER=$WEBPW/g" $THISDIR/.env

cp $THISDIR/config/kuma/kuma.db.example $THISDIR/config/kuma/kuma.db

# sqlite3 database.db "$sql"
# kuma/kuma.db setting.key = jwtSecret
# kuma/kuma.db setting.key = primaryBaseURL (value="http://127.0.0.1:3001/uptime"	type=general)
# kuma/kuma.db user id=1 username=dbstack password=hash
#
# bcrypt password for filemanager
# htpasswd -bnBC 10 "" password | tr -d ':\n' | sed 's/$2y/$2a/'
# sed -i "s/^\"password\".*/\"password\"\: \"${passwordvar}\"/g" $THISDIR/config/filebrowser/filebrowser.json

