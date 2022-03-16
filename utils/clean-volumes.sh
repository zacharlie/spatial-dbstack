#! /usr/bin/env bash

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

echo "WARNING! This will delete all docker data from data/volumes"
read -p "Are you sure you want to continue this operation? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then

  THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

  rm -rf ${THISDIR}/../data/volumes/db-backup/
  rm -rf ${THISDIR}/../data/volumes/grafana-data/
  rm -rf ${THISDIR}/../data/volumes/log-data/
  rm -rf ${THISDIR}/../data/volumes/pg-admin-data/
  rm -rf ${THISDIR}/../data/volumes/postgis-data/

fi
