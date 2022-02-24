#!/usr/bin/env bash

if [[ "$EUID" = 0 ]]; then
    true  # running as root
else
    sudo -k # prompt for password
    if sudo true; then
        true  # running as root
    else
        echo "Script requires root privileges"
        exit 1
    fi
fi

apt install wireguard
cd /etc/wireguard/
umask 077; wg genkey | tee privatekey | wg pubkey > publickey

vpn_server_addr=$(ip -o -f inet addr show | awk '/scope global/ {print $4}')
wg_publickey=$(cat /etc/wireguard/publickey)
wg_privatekey=$(cat /etc/wireguard/privatekey)
vpn_port=41194

echo "
[Interface]
Address = ${vpn_server_addr}
ListenPort = ${vpn_port}
PrivateKey = ${wg_privatekey}

# Enable NAT routing of all traffice through VPN
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

## Client details

[Peer]
## Client VPN public key ##
PublicKey = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
## Cient VPN IP address (note  the /32 subnet) ##
AllowedIPs = 192.168.7.2/32
" > /etc/wireguard/wg0.conf
