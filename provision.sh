#!/usr/bin/env bash

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

apt update
apt upgrade -y
apt full-upgrade -y
apt autoremove -y

apt install -y unattended-upgrades


apt remove -y docker docker-engine docker.io containerd runc
apt install -y apt-transport-https ca-certificates curl gnupg pwgen openssl apache2-utils sqlite3
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose

sudo service docker start

apt install fail2ban

wget -qO - https://s3-eu-west-1.amazonaws.com/crowdsec.debian.pragmatic/crowdsec.asc |sudo apt-key add - && echo "deb https://s3-eu-west-1.amazonaws.com/crowdsec.debian.pragmatic/$(lsb_release -cs) $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/crowdsec.list > /dev/null;
apt update
apt install crowdsec

ufw allow 80
ufw allow 443
