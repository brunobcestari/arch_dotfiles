#!/bin/bash

# Thunderbird email widget for Waybar
ICON_MAIL=$'\uf0e0'

# Check if Thunderbird is running
if pgrep -x thunderbird > /dev/null 2>&1; then
    # Thunderbird is running
    echo "{\"text\": \"$ICON_MAIL\", \"class\": \"running\", \"tooltip\": \"Thunderbird is running\\nClick to open/focus\"}"
else
    # Thunderbird is not running
    echo "{\"text\": \"$ICON_MAIL\", \"class\": \"stopped\", \"tooltip\": \"Thunderbird is not running\\nClick to start\"}"
fi
