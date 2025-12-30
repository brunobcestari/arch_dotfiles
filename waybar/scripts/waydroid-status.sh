#!/bin/bash

# Check Waydroid session status
ICON=$'\uf17b'  # Android icon (nerd font)

# Get waydroid status
WAYDROID_STATUS=$(waydroid status 2>&1 | grep "Session:" | awk '{print $2}')

# Get installed apps count
APPS_COUNT=$(waydroid app list 2>/dev/null | grep -c "^Name:")

if [ "$WAYDROID_STATUS" = "RUNNING" ]; then
    TOOLTIP="Waydroid: Running\n${APPS_COUNT} apps installed\n\nLeft-click: Control menu\nRight-click: Quick launch apps"
    echo "{\"text\": \"$ICON\", \"class\": \"running\", \"tooltip\": \"$TOOLTIP\"}"
else
    TOOLTIP="Waydroid: Stopped\n${APPS_COUNT} apps installed\n\nLeft-click: Control menu\nRight-click: Quick launch apps"
    echo "{\"text\": \"$ICON\", \"class\": \"stopped\", \"tooltip\": \"$TOOLTIP\"}"
fi
