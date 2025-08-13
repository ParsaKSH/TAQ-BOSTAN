GREEN="\e[32m"
BOLD_GREEN="\e[1;32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
MAGENTA="\e[35m"
WHITE="\e[37m"
RED="\e[31m"
RESET="\e[0m"

draw_green_line() {
  echo -e "${GREEN}+--------------------------------------------------------+${RESET}"
}

# Function to check if a port is in use
check_port_availability() {
  local port="$1"
  if command -v netstat >/dev/null 2>&1; then
    if netstat -tuln | grep -q ":${port} "; then
      echo -e "${RED}⚠️  Warning: Port ${port} appears to be in use!${RESET}"
      echo -e "${YELLOW}Please choose a different port or stop the service using this port.${RESET}"
      return 1
    fi
  elif command -v ss >/dev/null 2>&1; then
    if ss -tuln | grep -q ":${port} "; then
      echo -e "${RED}⚠️  Warning: Port ${port} appears to be in use!${RESET}"
      echo -e "${YELLOW}Please choose a different port or stop the service using this port.${RESET}"
      return 1
    fi
  else
    echo -e "${YELLOW}⚠️  Warning: Cannot check port availability (netstat/ss not found)${RESET}"
    echo -e "${YELLOW}Please manually verify that port ${port} is not in use.${RESET}"
  fi
  return 0
}

# Function to check system resources and warn if below recommended thresholds
check_system_resources() {
  echo -e "${CYAN}Checking system resources...${RESET}"
  
  # Check available memory (in MB)
  if command -v free >/dev/null 2>&1; then
    local free_mem_mb=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    local recommended_mem=512
    
    if [ "$free_mem_mb" -lt "$recommended_mem" ]; then
      echo -e "${RED}⚠️  Warning: Low available memory detected!${RESET}"
      echo -e "${YELLOW}Available: ${free_mem_mb}MB | Recommended: ${recommended_mem}MB+${RESET}"
      echo -e "${YELLOW}This may affect tunnel performance. Consider upgrading your server.${RESET}"
    else
      echo -e "${GREEN}✅ Memory check passed: ${free_mem_mb}MB available${RESET}"
    fi
  fi
  
  # Check CPU cores
  if command -v nproc >/dev/null 2>&1; then
    local cpu_cores=$(nproc)
    local recommended_cores=1
    
    if [ "$cpu_cores" -lt "$recommended_cores" ]; then
      echo -e "${RED}⚠️  Warning: Insufficient CPU cores detected!${RESET}"
      echo -e "${YELLOW}Available: ${cpu_cores} cores | Recommended: ${recommended_cores}+ cores${RESET}"
      echo -e "${YELLOW}This may affect tunnel performance under load.${RESET}"
    else
      echo -e "${GREEN}✅ CPU check passed: ${cpu_cores} cores available${RESET}"
    fi
  fi
  
  # Check system load if uptime is available
  if command -v uptime >/dev/null 2>&1; then
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local cpu_cores=${cpu_cores:-1}
    
    # Compare 1-minute load average to number of CPU cores
    if command -v bc >/dev/null 2>&1; then
      local load_ratio=$(echo "scale=2; $load_avg / $cpu_cores" | bc)
      local high_load=$(echo "$load_ratio > 1.5" | bc)
      
      if [ "$high_load" -eq 1 ]; then
        echo -e "${YELLOW}⚠️  Notice: High system load detected (${load_avg})${RESET}"
        echo -e "${YELLOW}Consider reducing server load before running intensive operations.${RESET}"
      fi
    fi
  fi
  
  echo ""
}

print_art() {
  echo -e "\033[1;32m                                                           "
  echo -e "@@@@@@@   @@@@@@    @@@@@@                                 "
  echo -e "@@@@@@@  @@@@@@@@  @@@@@@@@                                "
  echo -e "  @@!    @@!  @@@  @@!  @@@                                "
  echo -e "  !@!    !@!  @!@  !@!  @!@                                "
  echo -e "  @!!    @!@!@!@!  @!@  !@!                                "
  echo -e "  !!!    !!!@!!!!  !@!  !!!                                "
  echo -e "  !!:    !!:  !!!  !!:!!:!:                                "
  echo -e "  :!:    :!:  !:!  :!: :!:                                 "
  echo -e "   ::    ::   :::  ::::: :!                                "
  echo -e "   :      :   : :   : :  :::                               "
  echo -e "@@@@@@@    @@@@@@    @@@@@@  @@@@@@@   @@@@@@   @@@  @@@   "
  echo -e "@@@@@@@@  @@@@@@@@  @@@@@@@  @@@@@@@  @@@@@@@@  @@@@ @@@   "
  echo -e "@@!  @@@  @@!  @@@  !@@        @@!    @@!  @@@  @@!@!@@@   "
  echo -e "!@   @!@  !@!  @!@  !@!        !@!    !@!  @!@  !@!!@!@!   "
  echo -e "@!@!@!@   @!@  !@!  !!@@!!     @!!    @!@!@!@!  @!@ !!@!   "
  echo -e "!!!@!!!!  !@!  !!!   !!@!!!    !!!    !!!@!!!!  !@!  !!!   "
  echo -e "!!:  !!!  !!:  !!!       !:!   !!:    !!:  !!!  !!:  !!!   "
  echo -e ":!:  !:!  :!:  !:!      !:!    :!:    :!:  !:!  :!:  !:!   "
  echo -e " :: ::::  ::::: ::  :::: ::     ::    ::   :::   ::   ::   "
  echo -e ":: : ::    : :  :   :: : :      :      :   : :  ::    :    "
  echo -e "                                                           \033[0m"
  echo -e "\033[1;33m=========================================================="
  echo -e "Developed by Parsa => https://github.com/ParsaKSH"
  echo -e "\033[0m${RED}Sponsored by DigitalVPS.ir${RED}${RESET}"
  echo -e "\033[1;33mLove Iran :)"
  echo -e "\033[0m"
}
print_menu() {
  draw_green_line
  echo -e "${GREEN}|${RESET}              ${BOLD_GREEN}TAQ-BOSTAN Main Menu${RESET}                  ${GREEN}|${RESET}"
  draw_green_line
  echo -e "${GREEN}|${RESET} ${BLUE}1)${RESET} Create best and safest tunnel                   ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET} ${YELLOW}2)${RESET} Create local IPv6 with Sit                      ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET} ${MAGENTA}3)${RESET} Create local IPv6 with Wireguard                ${GREEN}|${RESET}"
  draw_green_line
  echo -e "${GREEN}|${RESET} ${BLUE}4)${RESET} Delete tunnel                                   ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET} ${YELLOW}5)${RESET} Delete local IPv6 with Sit                      ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET} ${MAGENTA}6)${RESET} Delete local IPv6 with Wireguard                ${GREEN}|${RESET}"
  draw_green_line
  echo -e "${GREEN}|${RESET} ${RED}7)${RESET} hysteria Tunnel Speedtest (Run in iran server)  ${GREEN}|${RESET}"
  draw_green_line
}

execute_option() {
  local choice="$1"
  
  # Check system resources before executing resource-intensive operations
  if [[ "$choice" =~ ^[123]$ ]]; then
    check_system_resources
  fi
  
  case "$choice" in
    1)
      echo -e "${CYAN}Executing: Create best and safest tunnel...${RESET}"
      bash <(curl -Ls https://raw.githubusercontent.com/ParsaKSH/TAQ-BOSTAN/main/hysteria.sh)
      ;;
    2)
      echo -e "${CYAN}Executing: Create local IPv6 with Sit...${RESET}"
      bash <(curl -Ls https://raw.githubusercontent.com/ParsaKSH/TAQ-BOSTAN/main/sit.sh)
      ;;
    3)
      echo -e "${CYAN}Executing: Create local IPv6 with Wireguard...${RESET}"
      bash <(curl -Ls https://raw.githubusercontent.com/ParsaKSH/TAQ-BOSTAN/main/wireguard.sh)
      ;;
    4)
      echo -e "${CYAN}Deleting Hysteria tunnel...${RESET}"
      sudo systemctl daemon-reload 2>/dev/null
      for i in {1..9}; do
        sudo systemctl disable hysteria$i 2>/dev/null
        sudo systemctl disable hysteria 2>/dev/null
      done
      sudo rm /etc/hysteria/server-config.yaml 2>/dev/null
      sudo rm /etc/hysteria/iran-config*.yaml 2>/dev/null
      sudo rm /etc/hysteria/port_mapping.txt 2>/dev/null
      
      # Check if mapping data persists and warn user
      if [ -f /etc/hysteria/port_mapping.txt ]; then
        echo -e "${YELLOW}⚠️  Warning: Mapping data still exists at /etc/hysteria/port_mapping.txt${RESET}"
        echo -e "${YELLOW}This may cause the monitor to continue acting on deleted tunnels.${RESET}"
      fi
      
      echo -e "${GREEN}Hysteria tunnel successfully deleted.${RESET}"
      read -p "Do you want to reboot now? [y/N]: " REBOOT_CHOICE
      if [[ "$REBOOT_CHOICE" =~ ^[Yy]$ ]]; then
        sudo shutdown -r now
      fi
      ;;
     5)
       echo -e "${CYAN}Deleting local IPv6 with Sit...${RESET}"
       for i in {1..8}; do
         sudo rm /etc/netplan/pdtun$i.yaml 2>/dev/null
         sudo rm /etc/systemd/network/tun$i.network 2>/dev/null
         sudo rm /etc/netplan/pdtun.yaml 2>/dev/null
         sudo rm /etc/systemd/network/tun0.network 2>/dev/null
       done
       sudo netplan apply 
       sudo systemctl restart systemd-networkd
       echo -e "${GREEN}Local IPv6 with Sit successfully deleted.${RESET}"
       read -p "Do you want to reboot now? [y/N]: " REBOOT_CHOICE
       if [[ "$REBOOT_CHOICE" =~ ^[Yy]$ ]]; then
         sudo shutdown -r now
       fi
       ;;
     6)
       echo -e "${CYAN}Deleting local IPv6 with Wireguard...${RESET}"
       sudo wg-quick down TAQBOSTANwg 2>/dev/null
       sudo systemctl disable wg-quick@TAQBOSTANwg 2>/dev/null
       sudo rm /etc/wireguard/TAQBOSTANwg.conf 2>/dev/null
       echo -e "${GREEN}Local IPv6 with Wireguard successfully deleted.${RESET}"
       read -p "Do you want to reboot now? [y/N]: " REBOOT_CHOICE
       if [[ "$REBOOT_CHOICE" =~ ^[Yy]$ ]]; then
         sudo shutdown -r now
       fi
       ;;
     7)
       read -p "For which foreign server number do you want to run the speedtest? " server_number
       /usr/local/bin/hysteria -c /etc/hysteria/iran-config${server_number}.yaml speedtest
       ;;
     *)
       echo -e "${RED}Invalid option. Exiting...${RESET}"
       exit 1
       ;;
   esac
 }
 
 print_art
 print_menu
 read -p "$(echo -e "${WHITE}Select an option [1-7]: ${RESET}")" user_choice
 execute_option "$user_choice"
