#!/bin/bash
set -e

# ------------------ Color Output Function ------------------
colorEcho() {
  local text="$1"
  local color="$2"
  case "$color" in
    red)     echo -e "\e[31m${text}\e[0m" ;;
    green)   echo -e "\e[32m${text}\e[0m" ;;
    yellow)  echo -e "\e[33m${text}\e[0m" ;;
    blue)    echo -e "\e[34m${text}\e[0m" ;;
    magenta) echo -e "\e[35m${text}\e[0m" ;;
    cyan)    echo -e "\e[36m${text}\e[0m" ;;
    *)       echo "$text" ;;
  esac
}

# ------------------ Initialization ------------------
ARCH=$(uname -m)
HYSTERIA_VERSION_AMD64="https://github.com/apernet/hysteria/releases/download/app%2Fv2.6.1/hysteria-linux-amd64"
HYSTERIA_VERSION_ARM="https://github.com/apernet/hysteria/releases/download/app%2Fv2.6.1/hysteria-linux-arm"
HYSTERIA_VERSION_ARM64="https://github.com/apernet/hysteria/releases/download/app%2Fv2.6.1/hysteria-linux-arm64"

case "$ARCH" in
  x86_64)   DOWNLOAD_URL="$HYSTERIA_VERSION_AMD64" ;;
  armv7l|armv6l) DOWNLOAD_URL="$HYSTERIA_VERSION_ARM" ;;
  aarch64)  DOWNLOAD_URL="$HYSTERIA_VERSION_ARM64" ;;
  *)
    colorEcho "Unsupported architecture: $ARCH" red
    exit 1
    ;;
esac

colorEcho "Downloading Hysteria binary for: $ARCH" cyan
if ! curl -fsSL "$DOWNLOAD_URL" -o hysteria; then
  colorEcho "Failed to download hysteria binary." red
  exit 1
fi
chmod +x hysteria
sudo mv hysteria /usr/local/bin/

sudo mkdir -p /etc/hysteria/

# ------------------ Server Type Input ------------------
while true; do
  read -p "installing Iranian server or Foreign server? (Iran/Foreign): " SERVER_TYPE
  SERVER_TYPE=$(echo "$SERVER_TYPE" | tr '[:upper:]' '[:lower:]')
  if [[ "$SERVER_TYPE" == "iran" || "$SERVER_TYPE" == "foreign" ]]; then
    break
  else
    colorEcho "Invalid input. Please enter 'Iran' or 'Foreign'." red
  fi
done

if [ "$SERVER_TYPE" == "foreign" ]; then
  colorEcho "Setting up foreign server..." green

  if ! command -v openssl &> /dev/null; then
    sudo apt update -y && sudo apt install -y openssl
  fi

  colorEcho "Generating self-signed certificate..." cyan
  sudo openssl req -x509 -nodes -days 3650 -newkey ed25519 \
    -keyout /etc/hysteria/self.key \
    -out /etc/hysteria/self.crt \
    -subj "/CN=myserver"

  while true; do
    read -p "Enter Hysteria port ex.(443) or (1-65535): " H_PORT
    if [[ "$H_PORT" =~ ^[0-9]+$ ]] && (( H_PORT > 0 && H_PORT < 65536 )); then
      break
    else
      colorEcho "Invalid port. Try again." red
    fi
  done

  read -p "Enter password: " H_PASSWORD

  cat << EOF | sudo tee /etc/hysteria/server-config.yaml > /dev/null
listen: ":$H_PORT"
tls:
  cert: /etc/hysteria/self.crt
  key: /etc/hysteria/self.key
auth:
  type: password
  password: "$H_PASSWORD"
quic:
  initStreamReceiveWindow: 67108864
  maxStreamReceiveWindow: 67108864
  initConnReceiveWindow: 134217728
  maxConnReceiveWindow: 134217728
  maxIdleTimeout: 5s
  keepAliveInterval: 3s
  disablePathMTUDiscovery: false
speedTest: true
EOF

  cat << EOF | sudo tee /etc/systemd/system/hysteria.service > /dev/null
[Unit]
Description=Hysteria2 Tunnel Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/hysteria server -c /etc/hysteria/server-config.yaml
Restart=always
RestartSec=5
LimitNOFILE=1048576
StandardOutput=append:/var/log/hysteria${i}.log
StandardError=append:/var/log/hysteria${i}.err

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable hysteria
  sudo systemctl start hysteria

  (crontab -l 2>/dev/null | grep -v 'restart hysteria'; echo "0 */12 * * * /usr/bin/systemctl restart hysteria") | crontab -
  colorEcho "Foreign server setup completed." green

elif [ "$SERVER_TYPE" == "iran" ]; then
  colorEcho "Setting up Iranian server..." green

  read -p "Use IPv4 or IPv6 for remote? (IPv4/IPv6): " IP_VERSION
  IP_VERSION=$(echo "$IP_VERSION" | tr '[:upper:]' '[:lower:]')
  REMOTE_IP="localhost"
  [[ "$IP_VERSION" == "ipv6" ]] && REMOTE_IP="[::]"

  read -p "How many foreign servers do you have? " SERVER_COUNT

  for (( i=1; i<=SERVER_COUNT; i++ )); do
    colorEcho "Foreign server #$i:" cyan
    while true; do
      read -p "Enter IP Address for Foreign server: " SERVER_ADDRESS
      if [[ "$SERVER_ADDRESS" =~ ^[0-9a-fA-F:\.]+$ ]]; then
        break
      else
        colorEcho "Invalid IP address " red
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
      TCP_FORWARD+="  - listen: 0.0.0.0:$TUNNEL_PORT
    remote: '$REMOTE_IP:$TUNNEL_PORT'
"
      UDP_FORWARD+="  - listen: 0.0.0.0:$TUNNEL_PORT
    remote: '$REMOTE_IP:$TUNNEL_PORT'
"
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
  maxIdleTimeout: 5s
  keepAliveInterval: 3s
  disablePathMTUDiscovery: false
speedTest: true
tcpForwarding:
$TCP_FORWARD
udpForwarding:
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
StandardOutput=append:/var/log/hysteria${i}.log
StandardError=append:/var/log/hysteria${i}.err

[Install]
WantedBy=multi-user.target
EOF

    (crontab -l 2>/dev/null | grep -v "restart hysteria${i}"; echo "0 6 * * * /usr/bin/systemctl restart hysteria${i}") | crontab -
    sudo systemctl daemon-reload
    sudo systemctl enable hysteria${i}
    sudo systemctl start hysteria${i}
  done

  colorEcho "Tunnels set up successfully." green
else
  colorEcho "Invalid server type. Please enter 'Iran' or 'Foreign'." red
  exit 1
fi
