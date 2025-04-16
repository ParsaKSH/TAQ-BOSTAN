#!/bin/bash
set -Eeuo pipefail
trap 'colorEcho "Script terminated prematurely." red' ERR SIGINT SIGTERM

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
sudo mkdir -p /var/log/hysteria/
sudo mkdir -p /var/log/

# ------------------ Server Type Menu ------------------
while true; do
  echo ""
  echo "Select server type:"
  echo "  [1] Iran"
  echo "  [2] Foreign"
  echo "  [3] Exit"
  read -rp "Enter your choice [1-3]: " SERVER_CHOICE

  case "$SERVER_CHOICE" in
    1)
      SERVER_TYPE="iran"
      break
      ;;
    2)
      SERVER_TYPE="foreign"
      break
      ;;
    3)
      colorEcho "Exiting..." yellow
      exit 0
      ;;
    *)
      colorEcho "Invalid selection. Please enter 1, 2, or 3." red
      ;;
  esac
done

# ------------------ IP Version Menu (Only for Iran) ------------------
if [ "$SERVER_TYPE" == "iran" ]; then
  while true; do
    echo ""
    echo "Select IP version for remote connection:"
    echo "  [1] IPv4"
    echo "  [2] IPv6"
    read -rp "Enter your choice [1-2]: " IP_VERSION_CHOICE

    case "$IP_VERSION_CHOICE" in
      1)
        REMOTE_IP="0.0.0.0"
        break
        ;;
      2)
        REMOTE_IP="[::]"
        break
        ;;
      *)
        colorEcho "Invalid selection. Please enter 1 or 2." red
        ;;
    esac
  done
fi

# ------------------ Obfuscation Option ------------------
read -p "Do you want to enable Obfuscation (obfs)? [y/N]: " ENABLE_OBFS
ENABLE_OBFS=$(echo "$ENABLE_OBFS" | tr '[:upper:]' '[:lower:]')

if [[ "$ENABLE_OBFS" == "y" || "$ENABLE_OBFS" == "yes" ]]; then
  OBFS_CONFIG=$(cat <<EOF
obfs:
  type: salamander
  salamander:
    password: "__REPLACE_PASSWORD__"
EOF
)
else
  OBFS_CONFIG=""
fi

# ------------------ Foreign Server Setup ------------------
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
  sudo chmod 600 /etc/hysteria/self.*

  while true; do
    read -p "Enter Hysteria port ex.(443) or (1-65535): " H_PORT
    if [[ "$H_PORT" =~ ^[0-9]+$ ]] && (( H_PORT > 0 && H_PORT < 65536 )); then
      break
    else
      colorEcho "Invalid port. Try again." red
    fi
  done

  while true; do
    read -p "Enter password: " H_PASSWORD
    if [[ -z "$H_PASSWORD" ]]; then
      colorEcho "Password cannot be empty. Please enter a valid password." red
    else
      break
    fi
  done

  cat << EOF | sudo tee /etc/hysteria/server-config.yaml > /dev/null
listen: ":$H_PORT"
tls:
  cert: /etc/hysteria/self.crt
  key: /etc/hysteria/self.key
auth:
  type: password
  password: "$H_PASSWORD"
$(echo "$OBFS_CONFIG" | sed "s/__REPLACE_PASSWORD__/$H_PASSWORD/")
quic:
  initStreamReceiveWindow: 8388608
  maxStreamReceiveWindow: 16777216
  initConnReceiveWindow: 16777216
  maxConnReceiveWindow: 33554432
  maxIdleTimeout: 15s
  keepAliveInterval: 10s
  disablePathMTUDiscovery: true
  congestionControl: bbr
  maxIncomingStreams: 1024
  maxIncomingUniStreams: 512
  maxDatagramFrameSize: 8940

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
StandardOutput=file:/var/log/hysteria.log
StandardError=file:/var/log/hysteria.err

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable hysteria
  sudo systemctl start hysteria
  sudo systemctl reload-or-restart hysteria
  (crontab -l 2>/dev/null | grep -v 'systemctl restart hysteria'; echo "0 */3 * * * /usr/bin/systemctl restart hysteria") | crontab -


  colorEcho "Foreign server setup completed." green

# ------------------ Iranian Client Setup ------------------
elif [ "$SERVER_TYPE" == "iran" ]; then
  colorEcho "Setting up Iranian server..." green

  read -p "How many foreign servers do you have? " SERVER_COUNT

  for (( i=1; i<=SERVER_COUNT; i++ )); do
    colorEcho "Foreign server #$i:" cyan
    while true; do
      read -p "Enter IP Address or Domain for Foreign server: " SERVER_ADDRESS
      if [[ "$SERVER_ADDRESS" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ || "$SERVER_ADDRESS" =~ ^[0-9a-fA-F:]+$ || "$SERVER_ADDRESS" =~ ^[a-zA-Z0-9.-]+$ ]]; then
        break
      else
        colorEcho "Invalid input. Please enter a valid IP or domain." red
      fi
    done

    read -p "Hysteria Port ex.(443): " PORT

    while true; do
      read -p "Password: " PASSWORD
      if [[ -z "$PASSWORD" ]]; then
        colorEcho "Password cannot be empty. Please enter a valid password." red
      else
        break
      fi
    done

    read -p "SNI ex.(google.com): " SNI
    read -p "Total request forwarding ports ex.(1) " PORT_FORWARD_COUNT

    TCP_FORWARD=""
    UDP_FORWARD=""
    FORWARDED_PORTS=""

    for (( p=1; p<=$PORT_FORWARD_COUNT; p++ ))
    do
      read -p "Enter port number #$p you want to tunnel: " TUNNEL_PORT

      TCP_FORWARD+="  - listen: 0.0.0.0:$TUNNEL_PORT\n    remote: '$REMOTE_IP:$TUNNEL_PORT'\n"
      UDP_FORWARD+="  - listen: 0.0.0.0:$TUNNEL_PORT\n    remote: '$REMOTE_IP:$TUNNEL_PORT'\n"

      if [ -z "$FORWARDED_PORTS" ]; then
        FORWARDED_PORTS="$TUNNEL_PORT"
      else
        FORWARDED_PORTS="$FORWARDED_PORTS, $TUNNEL_PORT"
      fi
    done

    CONFIG_FILE="/etc/hysteria/iran-config${i}.yaml"
    SERVICE_FILE="/etc/systemd/system/hysteria${i}.service"

    cat << EOF | sudo tee "$CONFIG_FILE" > /dev/null
server: "$SERVER_ADDRESS:$PORT"
auth: "$PASSWORD"
tls:
  sni: "$SNI"
  insecure: true
$(echo "$OBFS_CONFIG" | sed "s/__REPLACE_PASSWORD__/$PASSWORD/")
quic:
  initStreamReceiveWindow: 8388608
  maxStreamReceiveWindow: 16777216
  initConnReceiveWindow: 16777216
  maxConnReceiveWindow: 33554432
  maxIdleTimeout: 15s
  keepAliveInterval: 10s
  disablePathMTUDiscovery: true
  congestionControl: bbr
  maxIncomingStreams: 1024
  maxIncomingUniStreams: 512
  maxDatagramFrameSize: 8940

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
StandardOutput=file:/var/log/hysteria${i}.log
StandardError=file:/var/log/hysteria${i}.err

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable hysteria${i}
    sudo systemctl start hysteria${i}
    sudo systemctl reload-or-restart hysteria${i}
    (crontab -l 2>/dev/null | grep -v 'systemctl restart hysteria'; echo "0 */4 * * * /usr/bin/systemctl restart hysteria${i}") | crontab -

  done

  colorEcho "Tunnels set up successfully." green
else
  colorEcho "Invalid server type. Please enter 'Iran' or 'Foreign'." red
  exit 1
fi
