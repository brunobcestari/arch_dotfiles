#!/bin/bash

# Check ProtonVPN status
ICON_VPN=$'\uf023'

VPN_STATUS=$(nmcli connection show --active | grep -i "protonvpn\|wireguard" | grep -v "killswitch")

# Fetch public IP with timeout and error handling
PUBLIC_IP_ADDRESS=$(curl -s --max-time 3 'https://api.ipify.org?format=json' 2>/dev/null | jq -r '.ip' 2>/dev/null)

# If IP fetch failed, use placeholder
if [ -z "$PUBLIC_IP_ADDRESS" ] || [ "$PUBLIC_IP_ADDRESS" = "null" ]; then
    PUBLIC_IP_ADDRESS="Fetching..."
fi

if [ -n "$VPN_STATUS" ]; then
    VPN_NAME=$(echo "$VPN_STATUS" | head -1 | awk '{print $1, $2}')
    echo "{\"text\": \"$ICON_VPN $VPN_NAME\", \"class\": \"connected\", \"tooltip\": \"VPN: Connected to $VPN_NAME\\nPublic Address: $PUBLIC_IP_ADDRESS\"}"
else
    echo "{\"text\": \"$ICON_VPN\", \"class\": \"disconnected\", \"tooltip\": \"VPN: Not connected\\nPublic Address: $PUBLIC_IP_ADDRESS\"}"
fi
