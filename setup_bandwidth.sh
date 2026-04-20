#!/usr/bin/env bash
set -e

sed -i '
s/200 mbps/0 mbps/g;
s/200 Mbps/0 Mbps/g;
s/200mbps/0mbps/g;
s/200Mbps/0Mbps/g;
s/"ignoreClientBandwidth":[[:space:]]*false/"ignoreClientBandwidth": true/g
' /etc/hysteria/config.json

systemctl restart hysteria-server

echo
echo "Готово."
