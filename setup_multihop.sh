#!/usr/bin/env bash
set -e

echo "Вставь EU hy2:// ссылку:"
read -r HY2_URL

AUTH_AND_HOST=$(echo "$HY2_URL" | sed -n 's#^hy2://\([^?]*\).*#\1#p')
AUTH=$(echo "$AUTH_AND_HOST" | sed 's#@.*##')
HOSTPORT=$(echo "$AUTH_AND_HOST" | sed 's#.*@##')
HOST=$(echo "$HOSTPORT" | sed 's#:\([0-9]*\)$##')
PORT=$(echo "$HOSTPORT" | grep -o ':[0-9]*$' | tr -d ':')

SNI=$(echo "$HY2_URL" | grep -o 'sni=[^&]*' | head -n1 | cut -d= -f2)
INSECURE=$(echo "$HY2_URL" | grep -o 'insecure=[^&]*' | head -n1 | cut -d= -f2)
OBFS=$(echo "$HY2_URL" | grep -o 'obfs=[^&]*' | head -n1 | cut -d= -f2)
OBFS_PASSWORD=$(echo "$HY2_URL" | grep -o 'obfs-password=[^&]*' | head -n1 | cut -d= -f2-)

if [ -z "$PORT" ]; then
  PORT="443"
fi

if [ "$INSECURE" = "1" ]; then
  INSECURE_BOOL="true"
else
  INSECURE_BOOL="false"
fi

cat > /etc/hysteria-eu-client.yaml <<EOF
server: ${HOST}:${PORT}

auth: "${AUTH}"

tls:
  sni: ${SNI}
  insecure: ${INSECURE_BOOL}
EOF

if [ "$OBFS" = "salamander" ]; then
cat >> /etc/hysteria-eu-client.yaml <<EOF

obfs:
  type: salamander
  salamander:
    password: "${OBFS_PASSWORD}"
EOF
fi

cat >> /etc/hysteria-eu-client.yaml <<'EOF'

socks5:
  listen: 127.0.0.1:1080
  disableUDP: false

lazy: true
EOF

cat > /etc/systemd/system/hysteria-eu-client.service <<'EOF'
[Unit]
Description=Hysteria2 EU Client (multi-hop)
After=network.target

[Service]
ExecStart=/usr/local/bin/hysteria client -c /etc/hysteria-eu-client.yaml
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now hysteria-eu-client

sed -i 's/200 mbps/500 mbps/g; s/200 Mbps/500 Mbps/g; s/200mbps/500mbps/g; s/200Mbps/500Mbps/g' /etc/hysteria/config.json

sed -i '/"outbounds":[[:space:]]*\[/,/\][[:space:]]*,\{0,1\}/c\  "outbounds": [\
    {\
      "name": "eu-hop",\
      "type": "socks5",\
      "socks5": {\
        "addr": "127.0.0.1:1080",\
        "timeout": 10\
      }\
    },\
    {\
      "name": "v4",\
      "type": "direct",\
      "direct": {\
        "mode": 4,\
        "bindDevice": "eth0"\
      }\
    }\
  ],' /etc/hysteria/config.json

systemctl restart hysteria-server

echo
echo "Готово."
echo "Проверь:"
echo "systemctl status hysteria-eu-client --no-pager"
echo "curl --socks5 127.0.0.1:1080 https://ifconfig.me"
echo "Потом подключись к RU и проверь внешний IP."