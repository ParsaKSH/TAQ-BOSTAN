#!/bin/bash


read -p "Are you running this script on the IRAN server or the FOREIGN server? (IRAN/FOREIGN): " server_location_en
echo -e "\033[1;33mUpdating and installing required packages...\033[0m"
sudo apt update
sudo apt-get install iproute2 -y
sudo apt install nano -y
sudo apt install netplan.io -y

function ask_yes_no() {
    local prompt=$1
    local answer=""
    while true; do
        read -p "$prompt (yes/no): " answer
        if [[ "$answer" == "yes" || "$answer" == "no" ]]; then
            echo "$answer"
            break
        else
            echo -e "\033[1;31mOnly yes or no allowed.\033[0m"
        fi
    done
}

if [[ "$server_location_en" == "IRAN" || "$server_location_en" == "iran" ]]; then
    read -p "Please enter the IPv4 address of the IRAN server: " iran_ip
    read -p "Please enter the MTU (press Enter for default 1420): " mtu
    mtu=${mtu:-1420}
    read -p "How many FOREIGN servers do you have? " n_server
    declare -a foreign_ips
    for (( i=1; i<=$n_server; i++ )); do
        read -p "Enter IPv4 of FOREIGN server #$i: " temp_ip
        foreign_ips[i]=$temp_ip
    done

    for (( i=1; i<=$n_server; i++ )); do
        if (( i % 2 == 1 )); then
            y=$i
        else
            y=$((i+1))
        fi
        netplan_file="/etc/netplan/pdtun${i}.yaml"
        tunnel_name="tunel0$y"
        sudo bash -c "cat > $netplan_file <<EOF
network:
  version: 2
  tunnels:
    $tunnel_name:
      mode: sit
      local: $iran_ip
      remote: ${foreign_ips[i]}
      addresses:
        - 2619:db8:85a3:1b2e::$((2*i))/64
      mtu: $mtu
      routes:
        - to: 2619:db8:85a3:1b2e::$y/128
          scope: link
EOF"
        network_file="/etc/systemd/network/tun${i}.network"
        sudo bash -c "cat > $network_file <<EOF
[Network]
Address=2619:db8:85a3:1b2e::$((2*i))/64
Gateway=2619:db8:85a3:1b2e::$((2*i - 1))
EOF"
        echo -e "\033[1;37mThis is your Private-IPv6 for IRAN server #$i: 2619:db8:85a3:1b2e::$((2*i))\033[0m"
    done

    # Apply all network changes once after creating all configs
    sudo systemctl unmask systemd-networkd.service
    sudo systemctl start systemd-networkd
    sudo netplan apply
    sudo systemctl restart systemd-networkd
    reboot_choice=$(ask_yes_no "Operation completed successfully. Please reboot the system")
    if [ "$reboot_choice" == "yes" ]; then
        echo -e "\033[1;33mRebooting the system...\033[0m"
        sudo reboot
    else
        echo -e "\033[1;33mOperation completed successfully. Reboot required.\033[0m"
    fi
else
    read -p "Please enter the IPv4 address of the FOREIGN server: " foreign_ip
    read -p "Please enter the IPv4 address of the IRAN server: " iran_ip
    read -p "Please enter the MTU (press Enter for default 1420): " mtu
    mtu=${mtu:-1420}
    read -p "Which number is this FOREIGN server? (If you have multiple foreign servers, type which one this is. If only one, type 1): " server_number
    if (( server_number % 2 == 0 )); then
        this_server=$((server_number + 1))
    else
        this_server=$server_number
    fi
    sudo bash -c "cat > /etc/netplan/pdtun.yaml <<EOF
network:
  version: 2
  tunnels:
    tunel01:
      mode: sit
      local: $foreign_ip
      remote: $iran_ip
      addresses:
        - 2619:db8:85a3:1b2e::$this_server/64
      mtu: $mtu
      routes:
        - to: 2619:db8:85a3:1b2e::$this_server/128
          scope: link
EOF"
    sudo netplan apply
    sudo systemctl unmask systemd-networkd.service
    sudo systemctl start systemd-networkd
    sudo netplan apply
    gateway_for_foreign=$((this_server + 1))
    sudo bash -c "cat > /etc/systemd/network/tun0.network <<EOF
[Network]
Address=2619:db8:85a3:1b2e::$this_server/64
Gateway=2619:db8:85a3:1b2e::$gateway_for_foreign
EOF"
    echo -e "\033[1;37mThis is your Private-IPv6 for your FOREIGN server: 2619:db8:85a3:1b2e::$this_server\033[0m"
    sudo systemctl restart systemd-networkd
    reboot_choice=$(ask_yes_no "Operation completed successfully. Please reboot the system")
    if [ "$reboot_choice" == "yes" ]; then
        echo -e "\033[1;33mRebooting the system...\033[0m"
        sudo reboot
    else
        echo -e "\033[1;33mOperation completed successfully. Reboot required.\033[0m"
    fi
fi
