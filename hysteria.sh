elif [ "$SERVER_TYPE" == "iran" ]; then
  colorEcho "Setting up Iranian server..." green

  read -p "How many foreign servers do you have? " SERVER_COUNT

  for (( i=1; i<=SERVER_COUNT; i++ )); do
    colorEcho "Foreign server #$i:" cyan
    while true; do
      read -p "Enter IP Address for Foreign server: " SERVER_ADDRESS
      if [[ "$SERVER_ADDRESS" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ || "$SERVER_ADDRESS" =~ ^[0-9a-fA-F:]+$ ]]; then
        break
      else
        colorEcho "Invalid IP address" red
      fi
    done

    read -p "Hysteria Port ex.(443): " PORT
    read -p "Password: " PASSWORD
    read -p "SNI ex.(google.com): " SNI
    read -p "Number of ports for Forward ex.(1): " PORT_COUNT

    TCP_FORWARD=""
    UDP_FORWARD=""

    for (( p=1; p<=PORT_COUNT; p++ )); do
      read -p "Tunnel ports for Forward ex.(2053) #$p: " TUNNEL_PORT

      if sudo lsof -i :$TUNNEL_PORT > /dev/null; then
        colorEcho "Port $TUNNEL_PORT is in use. Proceeding anyway..." yellow
      fi

      FORWARD_ENTRY="  - listen: 0.0.0.0:$TUNNEL_PORT\n    remote: \"$REMOTE_IP:$TUNNEL_PORT\"\n"

      TCP_FORWARD+="$FORWARD_ENTRY"
      UDP_FORWARD+="$FORWARD_ENTRY"
    done

    CONFIG_FILE="/etc/hysteria/iran-config${i}.yaml"
    SERVICE_FILE="/etc/systemd/system/hysteria${i}.service"

    cat << EOF | sudo tee "$CONFIG_FILE" > /dev/null
server: "$SERVER_ADDRESS:$PORT"
auth: "$PASSWORD"
tls:
  sni: "$SNI"
  insecure: true
quic:
  initStreamReceiveWindow: 67108864
  maxStreamReceiveWindow: 67108864
  initConnReceiveWindow: 134217728
  maxConnReceiveWindow: 134217728
  maxIdleTimeout: 20s
  keepAliveInterval: 15s
  disablePathMTUDiscovery: false
speedTest: true
tcpForwarding: |
$TCP_FORWARD
udpForwarding: |
$UDP_FORWARD
EOF

    cat << EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=Hysteria2 Client $i
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/hysteria client -c $CONFIG_FILE
Restart=always
RestartSec=5
LimitNOFILE=1048576
StandardOutput=file:/var/log/hysteria${i}.log
StandardError=file:/var/log/hysteria${i}.err

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable hysteria${i}
    sudo systemctl start hysteria${i}
  done

  colorEcho "Tunnels set up successfully." green
