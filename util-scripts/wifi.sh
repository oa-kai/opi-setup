#!/bin/bash

echo "========== SETTING UP WIFI =========="

# Get the directory of the current script and find the config file
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WIFI_CONFIG_FILE="$(dirname "$CURRENT_DIR")/config/wifi.conf"

# Default values
SSID="orangead_wifi"
PASSWORD="orangead_wifi"
CON_NAME="OrangeAd_Debug_Wifi"

# If the config file exists, source it to get SSID and PASSWORD
if [[ -f $WIFI_CONFIG_FILE ]]; then
    source "$WIFI_CONFIG_FILE"
else
    echo "Using default WiFi credentials as configuration file not found!"
fi

echo "Updating WiFi Credentials with nmcli..."
# Check if the connection already exists, if it does, delete it
if nmcli con show | grep -q "$CON_NAME"; then
    nmcli con delete "$CON_NAME"
fi

# Add a new connection with the provided credentials
if nmcli con add con-name "$CON_NAME" ifname wlan0 type wifi ssid "$SSID"; then
    # Only continue if the connection was successfully created
    nmcli con modify "$CON_NAME" wifi-sec.key-mgmt wpa-psk
    nmcli con modify "$CON_NAME" wifi-sec.psk "$PASSWORD"
    nmcli con modify "$CON_NAME" connection.autoconnect yes
    
    # Set the WiFi connection to the highest priority
    nmcli con modify "$CON_NAME" connection.autoconnect-priority 999
    
    echo "WiFi credentials updated with nmcli!"
else
    echo "Failed to add new connection."
fi

# Lower the priority of all Ethernet connections starting with "Wired connection"
echo "========== SETTING UP ETHERNET PRIORITY =========="

# Loop through each "Wired connection" and set their metric higher than WiFi
while IFS= read -r ETH_CON_NAME; do
    if [[ ! -z "$ETH_CON_NAME" ]]; then
        nmcli con modify "$ETH_CON_NAME" ipv4.route-metric 700
        nmcli con modify "$ETH_CON_NAME" ipv6.route-metric 700
        echo "Lowered priority for Ethernet connection: $ETH_CON_NAME"
    fi
done < <(nmcli -t -f NAME con show | grep "^Wired connection")

echo "========== WIFI SETUP COMPLETE =========="
