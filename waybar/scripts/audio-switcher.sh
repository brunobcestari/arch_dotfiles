#!/bin/bash
# Audio device switcher using rofi and wpctl

# Get current default sink
current_sink=$(wpctl status | grep -A 1 "Sinks:" | grep "*" | awk '{print $2}' | sed 's/\.//')

# Get list of all sinks with their IDs and names
sinks=$(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep -E "^\s+[0-9]+\." | sed 's/^[[:space:]]*//' | sed 's/^\([0-9]*\)\. /\1: /')

# Show rofi menu and get selection
selected=$(echo "$sinks" | rofi -dmenu -i -p "Select Audio Output" -theme-str 'window {width: 500px;}')

if [ -n "$selected" ]; then
    # Extract ID from selection
    id=$(echo "$selected" | cut -d: -f1)
    # Set as default sink
    wpctl set-default "$id"
    notify-send "Audio Output" "Switched to: $(echo "$selected" | cut -d: -f2-)"
fi
