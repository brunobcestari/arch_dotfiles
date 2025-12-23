#!/bin/bash

# Check for system updates (Arch + AUR)
ICON_UPDATE=$'\uf019'

# Get official repo updates
OFFICIAL_UPDATES=$(checkupdates 2>/dev/null | wc -l)

# Get AUR updates
AUR_UPDATES=$(paru -Qua 2>/dev/null | wc -l)

TOTAL_UPDATES=$((OFFICIAL_UPDATES + AUR_UPDATES))

if [ "$TOTAL_UPDATES" -eq 0 ]; then
    echo "{\"text\": \"$ICON_UPDATE 0\", \"class\": \"updated\", \"tooltip\": \"System is up to date\"}"
elif [ "$TOTAL_UPDATES" -lt 10 ]; then
    echo "{\"text\": \"$ICON_UPDATE $TOTAL_UPDATES\", \"class\": \"pending\", \"tooltip\": \"$OFFICIAL_UPDATES official, $AUR_UPDATES AUR updates\"}"
else
    echo "{\"text\": \"$ICON_UPDATE $TOTAL_UPDATES\", \"class\": \"urgent\", \"tooltip\": \"$OFFICIAL_UPDATES official, $AUR_UPDATES AUR updates\\nClick to update\"}"
fi
