#!/bin/bash

# Check OpenLinkHub service status
ICON=$'\uf0e7'  # Lightning bolt icon

# Check if the service is active
if systemctl is-active --quiet openlinkhub.service; then
    echo "{\"text\": \"$ICON\", \"class\": \"running\", \"tooltip\": \"OpenLinkHub: Running\"}"
else
    echo "{\"text\": \"$ICON\", \"class\": \"stopped\", \"tooltip\": \"OpenLinkHub: Stopped\"}"
fi
