#!/bin/bash

# Function to get the primary network interface and its IPv4 address
function get_primary_ipv4() {
    local interface=$(ip route | grep default | awk '{print $5}')
    local ipv4=$(ip addr show $interface | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
    echo "$ipv4"
}

# Function to ask yes/no questions
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

# Function to uninstall all configurations
function uninstall() {
    echo -e "\033[1;33mRemoving all configurations...\033[0m"
    # Remove all Netplan configuration files created by this script
    sudo rm -f /etc/netplan/pdtun*.yaml
    # Remove all systemd network configuration files created by this script
    sudo rm -f /etc/systemd/network/tun*.network
    # Apply Netplan changes
    sudo netplan apply
    # Restart systemd-networkd to clear any remaining configurations
    sudo systemctl restart systemd-networkd
    echo -e "\033[1;32mUninstallation completed. System restored to previous state.\033[0m"
}

# Main script
echo -e "\033[1;33mUpdating and installing required packages...\033[0m"
sudo apt update
sudo apt-get install iproute2 -y
sudo apt install nano -y
sudo apt install netplan.io -y

# Ask if the user wants to uninstall
uninstall_choice=$(ask_yes_no "Do you want to uninstall all configurations?")
if [ "$uninstall_choice" == "yes" ]; then
    uninstall
    exit 0
fi

# Ask if this is IRAN or FOREIGN server
read -p "Are you running this script on the IRAN server or the FOREIGN server? (IRAN/FOREIGN): " server_location_en

# Get primary IPv4 address
primary_ipv4=$(get_primary_ipv4)
echo -e "\033[1;37mDetected primary IPv4 address: $primary_ipv4\033[0m"
use_primary_ipv4=$(ask_yes_no "Do you want to use this IPv4 address?")
if [ "$use_primary_ipv4" == "no" ]; then
    read -p "Please enter the IPv4 address: " primary_ipv4
fi

# Define the IPv6 prefix
ipv6_prefix="fd00:2619:db8:85a3:1b2e"

if [[ "$server_location_en" == "IRAN" || "$server_location_en" == "iran" ]]; then
    iran_ip=$primary_ipv4
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
        - $ipv6_prefix::$(printf '%x' $((2*i)))/64
      mtu: $mtu
      routes:
        - to: $ipv6_prefix::$(printf '%x' $y)/128
          scope: link
EOF"
        sudo netplan apply
        sudo systemctl unmask systemd-networkd.service
        sudo systemctl start systemd-networkd
        sudo netplan apply
        network_file="/etc/systemd/network/tun${i}.network"
        sudo bash -c "cat > $network_file <<EOF
[Network]
Address=$ipv6_prefix::$(printf '%x' $((2*i)))/64
Gateway=$ipv6_prefix::$(printf '%x' $((2*i - 1)))
EOF"
        echo -e "\033[1;37mThis is your Private-IPv6 for IRAN server #$i: $ipv6_prefix::$(printf '%x' $((2*i)))\033[0m"
    done

    sudo systemctl restart systemd-networkd
    reboot_choice=$(ask_yes_no "Operation completed successfully. Please reboot the system")
    if [ "$reboot_choice" == "yes" ]; then
        echo -e "\033[1;33mRebooting the system...\033[0m"
        sudo reboot
    else
        echo -e "\033[1;33mOperation completed successfully. Reboot required.\033[0m"
    fi
else
    foreign_ip=$primary_ipv4
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
        - $ipv6_prefix::$(printf '%x' $this_server)/64
      mtu: $mtu
      routes:
        - to: $ipv6_prefix::$(printf '%x' $this_server)/128
          scope: link
EOF"
    sudo netplan apply
    sudo systemctl unmask systemd-networkd.service
    sudo systemctl start systemd-networkd
    sudo netplan apply
    gateway_for_foreign=$((this_server + 1))
    sudo bash -c "cat > /etc/systemd/network/tun0.network <<EOF
[Network]
Address=$ipv6_prefix::$(printf '%x' $this_server)/64
Gateway=$ipv6_prefix::$(printf '%x' $gateway_for_foreign)
EOF"
    echo -e "\033[1;37mThis is your Private-IPv6 for your FOREIGN server: $ipv6_prefix::$(printf '%x' $this_server)\033[0m"

    sudo systemctl restart systemd-networkd
    reboot_choice=$(ask_yes_no "Operation completed successfully. Please reboot the system")
    if [ "$reboot_choice" == "yes" ]; then
        echo -e "\033[1;33mRebooting the system...\033[0m"
        sudo reboot
    else
        echo -e "\033[1;33mOperation completed successfully. Reboot required.\033[0m"
    fi
fi
