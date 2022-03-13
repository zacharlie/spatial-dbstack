#!/usr/bin/bash

# run from the volume mount for /etc/nginx/ssl/

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

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

echo "Generating Diffie-Hellman parameters for OpenSSL."
sudo openssl dhparam -out $THISDIR/dhparam.pem 4096
