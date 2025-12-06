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
      done
      sudo systemctl disable hysteria 2>/dev/null
      sudo rm /etc/hysteria/server-config.yaml 2>/dev/null
      sudo rm /etc/hysteria/iran-config*.yaml 2>/dev/null
      rm /etc/hysteria/hysteria-mapping.txt
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
