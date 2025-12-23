#!/bin/bash

# Check ProtonVPN status
ICON_VPN=$'\uf023'

VPN_STATUS=$(nmcli connection show --active | grep -i "vpn\|proton")

if [ -n "$VPN_STATUS" ]; then
    VPN_NAME=$(echo "$VPN_STATUS" | awk '{print $1}')
    echo "{\"text\": \"$ICON_VPN $VPN_NAME\", \"class\": \"connected\", \"tooltip\": \"VPN: Connected to $VPN_NAME\"}"
else
    echo "{\"text\": \"$ICON_VPN\", \"class\": \"disconnected\", \"tooltip\": \"VPN: Not connected\"}"
fi
