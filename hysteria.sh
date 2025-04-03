#!/bin/bash

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
    white)   echo -e "\e[37m${text}\e[0m" ;;
    *)       echo "${text}" ;;
  esac
}


ARCH=$(uname -m)


HYSTERIA_VERSION_AMD64="https://github.com/apernet/hysteria/releases/download/app%2Fv2.6.1/hysteria-linux-amd64"
HYSTERIA_VERSION_ARM="https://github.com/apernet/hysteria/releases/download/app%2Fv2.6.1/hysteria-linux-arm"
HYSTERIA_VERSION_ARM64="https://github.com/apernet/hysteria/releases/download/app%2Fv2.6.1/hysteria-linux-arm64"

DOWNLOAD_URL=""

case "$ARCH" in
  x86_64)
    DOWNLOAD_URL="$HYSTERIA_VERSION_AMD64"
    ;;
  armv7l|armv6l)
    DOWNLOAD_URL="$HYSTERIA_VERSION_ARM"
    ;;
  aarch64)
    DOWNLOAD_URL="$HYSTERIA_VERSION_ARM64"
    ;;
  *)
    colorEcho "System architecture '$ARCH' was not recognized or is not supported in this script." red
    colorEcho "Please replace with the correct link manually." yellow
    exit 1
    ;;
esac

colorEcho "Downloading hysteria binary for architecture: $ARCH" cyan
wget -O hysteria "$DOWNLOAD_URL"
if [ $? -ne 0 ]; then
  colorEcho "Failed to download hysteria file. Please check." red
  exit 1
fi

chmod +x hysteria
sudo mv hysteria /usr/local/bin/
sudo mkdir /etc/hysteria/

read -p "Are you installing on the Iranian server or the Foreign server? (Iran/Foreign): " SERVER_TYPE

SERVER_TYPE=$(echo "$SERVER_TYPE" | tr '[:upper:]' '[:lower:]')

declare -A SERVER_INFO_INDEXED=()

if [ "$SERVER_TYPE" == "foreign" ]; then

  colorEcho "You are setting up the foreign server..." green

  sudo mkdir -p /etc/hysteria/

  sudo apt update -y
  sudo apt install -y openssl

  colorEcho "Creating a self-signed certificate..." cyan
  sudo openssl req -x509 -nodes -days 3650 -newkey ed25519 \
    -keyout /etc/hysteria/self.key \
    -out /etc/hysteria/self.crt \
    -subj "/CN=myserver"

  read -p "Please enter the Hysteria port (e.g. 443): " H_PORT
  read -p "Please enter a password for Hysteria: " H_PASSWORD

  cat << EOF | sudo tee /etc/hysteria/server-config.yaml > /dev/null
listen: ":$H_PORT"
tls:
  cert: /etc/hysteria/self.crt
  key: /etc/hysteria/self.key
auth:
  type: password
  password: "$H_PASSWORD"
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

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable hysteria
  sudo systemctl start hysteria
  (crontab -l 2>/dev/null; echo "0 */3 * * * /usr/bin/systemctl restart hysteria") | crontab -

  colorEcho "Foreign server has been successfully configured." green

elif [ "$SERVER_TYPE" == "iran" ]; then

  colorEcho "You are setting up the Iranian server..." green

  read -p "Do you want to use IPv4 or IPv6 for remote addresses? (IPv4/IPv6): " IP_VERSION
  IP_VERSION=$(echo "$IP_VERSION" | tr '[:upper:]' '[:lower:]')

  if [[ "$IP_VERSION" == "ipv4" ]]; then
    REMOTE_IP="localhost"
  else
    REMOTE_IP="[::]"
  fi

  read -p "How many foreign servers do you have? " SERVER_COUNT

  for (( i=1; i<=$SERVER_COUNT; i++ ))
  do
    colorEcho "Foreign server number $i:" cyan
    
    if [[ "$IP_VERSION" == "ipv4" ]]; then
      read -p "Please enter the IPv4 of this foreign server: " FOREIGN_IP
      SERVER_ADDRESS="$FOREIGN_IP"
    else
      read -p "Please enter the IPv6 of this foreign server: " FOREIGN_IPV6
      SERVER_ADDRESS="[$FOREIGN_IPV6]"
    fi
    
    read -p "Please enter the Hysteria port used on the foreign server: " FOREIGN_PORT
    read -p "Please enter the Hysteria password used on the foreign server: " FOREIGN_PASSWORD
    read -p "Please enter the SNI (e.g. example.com): " FOREIGN_SNI

    read -p "How many ports do you want to tunnel for this server? " PORT_FORWARD_COUNT

    TCP_FORWARD=""
    UDP_FORWARD=""
    FORWARDED_PORTS=""

    for (( p=1; p<=$PORT_FORWARD_COUNT; p++ ))
    do
      read -p "Enter port number #$p you want to tunnel: " TUNNEL_PORT
      
      TCP_FORWARD+="  - listen: 0.0.0.0:$TUNNEL_PORT
    remote: '$REMOTE_IP:$TUNNEL_PORT'
"
      UDP_FORWARD+="  - listen: 0.0.0.0:$TUNNEL_PORT
    remote: '$REMOTE_IP:$TUNNEL_PORT'
"

      if [ -z "$FORWARDED_PORTS" ]; then
        FORWARDED_PORTS="$TUNNEL_PORT"
      else
        FORWARDED_PORTS="$FORWARDED_PORTS, $TUNNEL_PORT"
      fi
    done

    IRAN_CONFIG="/etc/hysteria/iran-config${i}.yaml"
    sudo bash -c "cat << EOF > $IRAN_CONFIG
server: \"$SERVER_ADDRESS:$FOREIGN_PORT\"
auth: \"$FOREIGN_PASSWORD\"
tls:
  sni: \"$FOREIGN_SNI\"
  insecure: true

quic:
  initStreamReceiveWindow: 8388608
  maxIdleTimeout: 10s
  keepAliveInterval: 10s

tcpForwarding:
$TCP_FORWARD
udpForwarding:
$UDP_FORWARD
EOF"

    IRAN_SERVICE="/etc/systemd/system/hysteria${i}.service"
    sudo bash -c "cat << EOF > $IRAN_SERVICE
[Unit]
Description=Hysteria2 Foreign Server ${i}
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/hysteria client -c /etc/hysteria/iran-config${i}.yaml
Restart=always
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF"

    (crontab -l 2>/dev/null; echo "0 4 * * * /usr/bin/systemctl restart hysteria${i}") | crontab -

    sudo systemctl daemon-reload
    sudo systemctl enable hysteria${i}
    sudo systemctl start hysteria${i}

    SERVER_INFO_INDEXED["server_${i}_info"]="$FOREIGN_PORT|$FOREIGN_PASSWORD|$FOREIGN_SNI|$FORWARDED_PORTS"
  done

  colorEcho "Iranian server has been successfully configured." green

  colorEcho "===================================" magenta
  colorEcho "   Tunnels Created on Iran Server  " magenta
  colorEcho "===================================" magenta

  echo -e "\e[34m| Server # | Hysteria Port | Password         | SNI             | Forwarded Ports          |\e[0m"
  echo -e "\e[34m----------------------------------------------------------------------------------------\e[0m"

  for (( i=1; i<=$SERVER_COUNT; i++ ))
  do
    INFO="${SERVER_INFO_INDEXED["server_${i}_info"]}"
    IFS='|' read -r port pass sni forwards <<< "$INFO"

    echo -e "|     \e[32m$i\e[0m     |     \e[32m$port\e[0m      | \e[32m$pass\e[0m | \e[32m$sni\e[0m | \e[32m$forwards\e[0m "
  done

  echo ""
  colorEcho "Done." cyan

else
  colorEcho "Invalid answer. Please enter only 'Iran' or 'Foreign'." red
  exit 1
fi
