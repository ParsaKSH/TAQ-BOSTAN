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
# ------------------ draw_menu ------------------
draw_menu() {
  local title="$1"
  shift
  local options=("$@")

  local GREEN='\e[32m'
  local WHITE='\e[97m'
  local RESET='\e[0m'

  local width=42
  local inner_width=$((width - 2))
  local line=$(printf "%${inner_width}s" "" | sed "s/ /═/g")

  local border_top="╔"
  local border_mid="╠"
  local border_bottom="╚"
  local border_side="║"
  local border_right="╗"
  local border_mid_right="╣"
  local border_bottom_right="╝"

  local title_length=${#title}
  local padding_left=$(( (inner_width - title_length) / 2 ))
  local padding_right=$(( inner_width - title_length - padding_left ))
  local title_line="$(printf "%${padding_left}s" "")${title}$(printf "%${padding_right}s" "")"

  echo -e "${GREEN}${border_top}${line}${border_right}${RESET}"
  echo -e "${GREEN}${border_side}${WHITE}${title_line}${GREEN}${border_side}${RESET}"
  echo -e "${GREEN}${border_mid}${line}${border_mid_right}${RESET}"

  for opt in "${options[@]}"; do
    printf "${GREEN}${border_side} ${WHITE}%-*s${GREEN} ${border_side}${RESET}\n" $((inner_width - 2)) "$opt"
  done

  echo -e "${GREEN}${border_mid}${line}${border_mid_right}${RESET}"
  printf "${GREEN}${border_side} ${GREEN}%-*s${GREEN} ${border_side}${RESET}\n" $((inner_width - 2)) "Enter your choice:"
  echo -e "${GREEN}${border_bottom}${line}${border_bottom_right}${RESET}"
  echo -ne "${WHITE}> ${RESET}"
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

if [ -f "/usr/local/bin/hysteria" ]; then
 colorEcho "Hysteria binary already exists at /usr/local/bin/hysteria. Skipping download." yellow
 else
 colorEcho "Downloading Hysteria binary for: $ARCH" cyan
 if ! curl -fsSL "$DOWNLOAD_URL" -o hysteria; then
   colorEcho "Failed to download hysteria binary." red
   exit 1
 fi
 chmod +x hysteria
 sudo mv hysteria /usr/local/bin/
 fi
sudo mkdir -p /etc/hysteria/
MAPPING_FILE="/etc/hysteria/port_mapping.txt"
if [ ! -f "$MAPPING_FILE" ]; then
  sudo touch "$MAPPING_FILE"
fi
sudo mkdir -p /var/log/hysteria/

if [ ! -f /etc/hysteria/hysteria-monitor.py ]; then
  sudo curl -fsSL https://raw.githubusercontent.com/ParsaKSH/TAQ-BOSTAN/main/hysteria-monitor.py \
    -o /etc/hysteria/hysteria-monitor.py
  sudo chmod +x /etc/hysteria/hysteria-monitor.py
fi

# ------------------ Manage Tunnels Function ------------------
manage_tunnels() {
  set +e
  set +o pipefail
  colorEcho "Managing existing tunnels..." cyan
  echo "Existing tunnels:"
  shopt -s nullglob
  local config_files=(/etc/hysteria/iran-config*.yaml)
  shopt -u nullglob
  for cfg in "${config_files[@]}"; do
    local i="${cfg##*iran-config}"
    i="${i%.yaml}"
    echo -e "\n=== Tunnel #${i} ==="
    grep "server:" "$cfg" | cut -d'"' -f2
    grep "auth:"   "$cfg" | cut -d'"' -f2
    echo "Status: $(systemctl is-active hysteria${i})"
  done

  echo -e "\nWhat would you like to do?"
  echo "1) Edit a tunnel"
  echo "2) Delete a tunnel"
  echo "3) Back to previous menu"
  read -rp "> " MANAGE_CHOICE

  case "$MANAGE_CHOICE" in
    1)
      read -rp "Enter tunnel number to edit (1-9): " TUNNEL_NUM
      if [ -f "/etc/hysteria/iran-config${TUNNEL_NUM}.yaml" ]; then
        read -rp "Enter new server address (or press Enter to keep current): " NEW_SERVER
        read -rp "Enter new password       (or press Enter to keep current): " NEW_PASSWORD
        read -rp "Enter new SNI            (or press Enter to keep current): " NEW_SNI

        [ -n "$NEW_SERVER"   ] && sed -i "s|server: .*|server: \"$NEW_SERVER\"|"   "/etc/hysteria/iran-config${TUNNEL_NUM}.yaml"
        [ -n "$NEW_PASSWORD" ] && sed -i "s|auth: .*|auth: \"$NEW_PASSWORD\"|"     "/etc/hysteria/iran-config${TUNNEL_NUM}.yaml"
        [ -n "$NEW_SNI"      ] && sed -i "s|sni: .*|sni: \"$NEW_SNI\"|"           "/etc/hysteria/iran-config${TUNNEL_NUM}.yaml"

        systemctl restart hysteria${TUNNEL_NUM}
        colorEcho "Tunnel #${TUNNEL_NUM} updated and restarted." green
      else
        colorEcho "Tunnel #${TUNNEL_NUM} does not exist." red
      fi
      ;;
    2)
      read -rp "Enter tunnel number to delete (1-9): " TUNNEL_NUM
      if [ -f "/etc/hysteria/iran-config${TUNNEL_NUM}.yaml" ]; then
        systemctl stop   hysteria${TUNNEL_NUM}
        systemctl disable hysteria${TUNNEL_NUM}
        rm "/etc/hysteria/iran-config${TUNNEL_NUM}.yaml"
        rm "/etc/systemd/system/hysteria${TUNNEL_NUM}.service"
        systemctl daemon-reload
        colorEcho "Tunnel #${TUNNEL_NUM} deleted." green
      else
        colorEcho "Tunnel #${TUNNEL_NUM} does not exist." red
      fi
      sed -i "\%^iran-config${TUNNEL_NUM}\.yaml|%d" "$MAPPING_FILE"
      ;;
    3)
      return
      ;;
    *)
      colorEcho "Invalid choice. Returning..." red
      ;;
  esac
  set -e
  set -o pipefail
}

# ------------------ Monitor Ports Function ------------------
monitor_ports() {

  set +e
  set +o pipefail

  clear
  colorEcho "=== Monitoring Traffic Ports ===" cyan
  echo ""


  if ! command -v netstat &> /dev/null; then
    colorEcho "Installing net-tools..." yellow
    sudo apt-get update -qq
    sudo apt-get install -y net-tools >/dev/null 2>&1
  fi

  local found=0
  # Cache netstat output once for all port checks
  local tcp_ports
  local udp_ports
  tcp_ports=$(netstat -tln 2>/dev/null)
  udp_ports=$(netstat -uln 2>/dev/null)
  
  # Use glob-based discovery instead of iterating 1..9
  shopt -s nullglob
  local config_files=(/etc/hysteria/iran-config*.yaml)
  shopt -u nullglob
  
  for cfg in "${config_files[@]}"; do
    local i="${cfg##*iran-config}"
    i="${i%.yaml}"
    ((found++))

    echo "🔵 Tunnel #${i}"
    echo "----------------------------------------"

    local srv
    srv=$(grep "server:" "$cfg" | cut -d'"' -f2)
    echo "📡 Server: $srv"
    if systemctl is-active --quiet hysteria${i}; then
      echo "🟢 Service: Active"
    else
      echo "🔴 Service: Inactive"
    fi

    echo -e "\n🔌 Ports Status:"

    echo "TCP Ports:"
    while read -r line; do
      port=$(echo "$line" | grep -o '[0-9]\+')
      if echo "$tcp_ports" | grep -q ":$port "; then
        echo "   ✅ $port (Active)"
      else
        echo "   ❌ $port (Inactive)"
      fi
    done < <(
      grep -A50 "tcpForwarding:" "$cfg" 2>/dev/null \
      | grep "listen:" 2>/dev/null
    )

    echo -e "\nUDP Ports:"
    while read -r line; do
      port=$(echo "$line" | grep -o '[0-9]\+')
      if echo "$udp_ports" | grep -q ":$port "; then
        echo "   ✅ $port (Active)"
      else
        echo "   ❌ $port (Inactive)"
      fi
    done < <(
      grep -A50 "udpForwarding:" "$cfg" 2>/dev/null \
      | grep "listen:" 2>/dev/null
    )

    echo "----------------------------------------"
    echo ""
  done

  if [ $found -eq 0 ]; then
    colorEcho "No tunnels found!" yellow
  fi

  colorEcho "Press Enter to return..." green
  read -r

  set -e
  set -o pipefail
}

# ------------------ Server Type Menu ------------------
while true; do
draw_menu "Server Type Selection" \
    "1 | Setup Iranian Server" \
    "2 | Setup Foreign Server" \
    "3 | Exit"
  read -r SERVER_CHOICE
  case "$SERVER_CHOICE" in
    1)
      while true; do
        draw_menu "Iranian Server Options" \
          "1 | Create New Tunnel" \
          "2 | Edit tunnel list" \
          "3 | Monitor Traffic Ports" \
          "4 | Exit"
        read -rp "> " IRAN_CHOICE
        case "$IRAN_CHOICE" in
          1) 
            SERVER_TYPE="iran"; break 2
            ;;
          2) 
            manage_tunnels 
            ;;
          3) 
            monitor_ports     
            ;;
          4) 
            colorEcho "Exiting..." yellow; exit 0 
            ;;
          *) 
            colorEcho "Invalid selection. Please enter 1, 2, 3, or 4." red 
            ;;
        esac
      done
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
    # Scan for existing tunnels and find the next available number using glob
    NEXT_TUNNEL=1
    shopt -s nullglob
    for cfg in /etc/hysteria/iran-config*.yaml; do
      num="${cfg##*iran-config}"
      num="${num%.yaml}"
      if (( num >= NEXT_TUNNEL )); then
        NEXT_TUNNEL=$((num + 1))
      fi
    done
    shopt -u nullglob
    
    colorEcho "Next available tunnel number: $NEXT_TUNNEL" cyan
    
    draw_menu "IP Version Selection" \
      "1 | IPv4" \
      "2 | IPv6" \
      "3 | Exit"
    read -r IP_VERSION_CHOICE

    case "$IP_VERSION_CHOICE" in
      1)
        REMOTE_IP="0.0.0.0"
        export NEXT_TUNNEL
        break
        ;;
      2)
        REMOTE_IP="[::]"
        export NEXT_TUNNEL
        break
        ;;
      3)
        # Return to previous menu
        continue 2
        ;;
      *)
        colorEcho "Invalid selection. Please enter 1, 2, or 3." red
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

# ------------------ QUIC Settings Based on Usage ------------------
draw_menu "Expected Simultaneous Users" \
  "1 | 1 to 50 users (Light load)" \
  "2 | 50 to 100 users (Medium load)" \
  "3 | 100 to 300 users (Heavy load)"
read -r USAGE_CHOICE

case "$USAGE_CHOICE" in
  1)
    QUIC_SETTINGS=$(cat <<EOF
quic:
  initStreamReceiveWindow: 25165824
  maxStreamReceiveWindow: 50331648
  initConnReceiveWindow: 50331648
  maxConnReceiveWindow: 100663296
  maxIdleTimeout: 15s
  keepAliveInterval: 10s
  maxIncomingStreams: 4096
  disablePathMTUDiscovery: false
EOF
)
    ;;
  2)
    QUIC_SETTINGS=$(cat <<EOF
quic:
  initStreamReceiveWindow: 50331648
  maxStreamReceiveWindow: 100663296
  initConnReceiveWindow: 100663296
  maxConnReceiveWindow: 201326592
  maxIdleTimeout: 15s
  keepAliveInterval: 10s
  maxIncomingStreams: 8192
  disablePathMTUDiscovery: false
EOF
)
    ;;
  3)
    QUIC_SETTINGS=$(cat <<EOF
quic:
  initStreamReceiveWindow: 100663296
  maxStreamReceiveWindow: 201326592
  initConnReceiveWindow: 201326592
  maxConnReceiveWindow: 402653184
  maxIdleTimeout: 15s
  keepAliveInterval: 10s
  maxIncomingStreams: 24576
  disablePathMTUDiscovery: false
EOF
)
    ;;
  *)
    echo "Invalid option. Defaulting to 1-50 users (light load)."
    QUIC_SETTINGS=$(cat <<EOF
quic:
  initStreamReceiveWindow: 25165824
  maxStreamReceiveWindow: 50331648
  initConnReceiveWindow: 50331648
  maxConnReceiveWindow: 100663296
  maxIdleTimeout: 15s
  keepAliveInterval: 10s
  maxIncomingStreams: 4096
  disablePathMTUDiscovery: false
EOF
)
    ;;
esac

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
$(echo "$QUIC_SETTINGS")
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
  sudo systemctl enable --now hysteria
  sudo systemctl reload-or-restart hysteria
  CRON_CMD='0 4 * * * /usr/bin/systemctl restart hysteria'
  TMP_FILE=$(mktemp)

  crontab -l 2>/dev/null | grep -vF "$CRON_CMD" > "$TMP_FILE" || true
  echo "$CRON_CMD" >> "$TMP_FILE"
  crontab "$TMP_FILE"
  rm -f "$TMP_FILE"

  colorEcho "Foreign server setup completed." green

# ------------------ Iranian Client Setup ------------------
elif [ "$SERVER_TYPE" == "iran" ]; then
  colorEcho "Setting up Iranian server..." green

  read -p "How many foreign servers do you have? " SERVER_COUNT

  for (( i=1; i<=SERVER_COUNT; i++ )); do
    colorEcho "Foreign server #$i:" cyan
    while true; do
      read -p "Enter IP Address or Domain for Foreign server: " SERVER_ADDRESS
      if [[ "$SERVER_ADDRESS" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        break
      elif [[ "$SERVER_ADDRESS" =~ ^[0-9a-fA-F:]+$ ]]; then
        SERVER_ADDRESS="[${SERVER_ADDRESS}]"
        break
      elif [[ "$SERVER_ADDRESS" =~ ^[a-zA-Z0-9.-]+$ ]]; then
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
    read -p "How many ports do you have for forwarding? ex.(1) " PORT_FORWARD_COUNT

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
        FORWARDED_PORTS="$FORWARDED_PORTS,$TUNNEL_PORT"
      fi
    done

    # Create configuration and service files for each tunnel
    CONFIG_FILE="/etc/hysteria/iran-config${i}.yaml"
    SERVICE_FILE="/etc/systemd/system/hysteria${i}.service"

    cat << EOF | sudo tee "$CONFIG_FILE" > /dev/null
server: "$SERVER_ADDRESS:$PORT"
auth: "$PASSWORD"
tls:
  sni: "$SNI"
  insecure: true
$(echo "$OBFS_CONFIG" | sed "s/__REPLACE_PASSWORD__/$PASSWORD/")
$(echo "$QUIC_SETTINGS")
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
    sudo systemctl enable --now hysteria${i}
    sudo systemctl reload-or-restart hysteria${i}

    
    # Add cron job for each tunnel

    echo "iran-config${i}.yaml|hysteria${i}|${FORWARDED_PORTS}" \
    | sudo tee -a "$MAPPING_FILE" > /dev/null
    colorEcho "Tunnel $i setup completed." green
  done
# ====== Set up per-config iptables counters ======
while IFS='|' read -r cfg service ports; do
  idx="${cfg##*config}"      # => "1.yaml"
  idx="${idx%%.*}"           # => "1"
  chain="HYST${idx}"         # => "HYST1"
  sudo iptables -t mangle -N "$chain" 2>/dev/null || sudo iptables -t mangle -F "$chain"
  sudo iptables -t mangle -A "$chain" -j RETURN
  IFS=',' read -ra PARR <<< "$ports"
  for p in "${PARR[@]}"; do
    sudo iptables -t mangle -A OUTPUT -p tcp --dport "$p" -j "$chain"
    sudo iptables -t mangle -A OUTPUT -p udp --dport "$p" -j "$chain"
  done
done < "$MAPPING_FILE"

sudo tee /etc/systemd/system/hysteria-monitor.service > /dev/null <<'EOF'
[Unit]
Description=Hysteria Monitor Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /etc/hysteria/hysteria-monitor.py
Restart=always
RestartSec=10
StandardOutput=file:/var/log/hysteria/monitor.log
StandardError=file:/var/log/hysteria/monitor.err

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable hysteria-monitor
sudo systemctl start hysteria-monitor


  colorEcho "All tunnels set up successfully." green
else
  colorEcho "Invalid server type. Please enter 'Iran' or 'Foreign'." red
  exit 1
fi
