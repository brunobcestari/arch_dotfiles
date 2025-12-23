#!/bin/bash
# Microphone/input device switcher using rofi and wpctl

# Get list of all sources (input devices)
sources=$(wpctl status | sed -n '/Sources:/,/Sinks:/p' | grep -E "^\s+[0-9]+\." | sed 's/^[[:space:]]*//' | sed 's/^\([0-9]*\)\. /\1: /')

# Show rofi menu and get selection
selected=$(echo "$sources" | rofi -dmenu -i -p "Select Audio Input" -theme-str 'window {width: 500px;}')

if [ -n "$selected" ]; then
    # Extract ID from selection
    id=$(echo "$selected" | cut -d: -f1)
    # Set as default source
    wpctl set-default "$id"
    notify-send "Audio Input" "Switched to: $(echo "$selected" | cut -d: -f2-)"
fi
