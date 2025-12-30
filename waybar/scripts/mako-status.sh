#!/bin/bash

# Check Mako notification daemon status
ICON_BELL=$'\uf0f3'      # Bell icon
ICON_DND=$'\uf1f6'       # Bell slash (Do Not Disturb)

# Get current mode
MODE=$(makoctl mode)

# Get notification count from history
NOTIF_COUNT=$(makoctl history | jq -r '.data[0] | length' 2>/dev/null || echo "0")

# Check if DND is active
if echo "$MODE" | grep -q "do-not-disturb"; then
    TOOLTIP="Do Not Disturb: ON\nNotifications in history: $NOTIF_COUNT\n\nLeft-click: Open menu\nRight-click: Toggle DND"
    echo "{\"text\": \"$ICON_DND\", \"class\": \"dnd\", \"tooltip\": \"$TOOLTIP\"}"
else
    if [ "$NOTIF_COUNT" -gt 0 ]; then
        TOOLTIP="Notifications: $NOTIF_COUNT in history\n\nLeft-click: Open menu\nRight-click: Toggle DND"
        echo "{\"text\": \"$ICON_BELL $NOTIF_COUNT\", \"class\": \"has-notifications\", \"tooltip\": \"$TOOLTIP\"}"
    else
        TOOLTIP="No notifications\n\nLeft-click: Open menu\nRight-click: Toggle DND"
        echo "{\"text\": \"$ICON_BELL\", \"class\": \"no-notifications\", \"tooltip\": \"$TOOLTIP\"}"
    fi
fi
