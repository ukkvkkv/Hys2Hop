#!/usr/bin/env bash
set -e

sed -i 's/200 mbps/500 mbps/g; s/200 Mbps/500 Mbps/g; s/200mbps/500mbps/g; s/200Mbps/500Mbps/g' /etc/hysteria/config.json

systemctl restart hysteria-server

echo
echo "Готово."