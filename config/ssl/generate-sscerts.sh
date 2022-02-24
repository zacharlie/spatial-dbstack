#!/usr/bin/bash

# run from the volume mount for /etc/nginx/ssl/

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

OUTKEY="$THISDIR/nginx-selfsigned.key"
OUTCRT="$THISDIR/nginx-selfsigned.crt"

cd "$THISDIR"

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

echo "Generating self signed TLS certificate pair."
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $OUTKEY -out $OUTCRT
