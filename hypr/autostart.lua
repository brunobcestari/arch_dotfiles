-----------------
---- AUTOSTART --
-----------------

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
-- Using UWSM for session management - apps run as systemd user units
hl.on("hyprland.start", function()
    -- Start gnome-keyring with secrets component (for VS Code, etc.)
    hl.exec_cmd("gnome-keyring-daemon --start --components=pkcs11,secrets,ssh")
    hl.exec_cmd("systemctl --user start xdg-desktop-portal.service")

    -- Start Waybar (top and bottom bars)
    -- Environment variables (MONITOR_PRIMARY, etc.) come from ~/.config/uwsm/env
    hl.exec_cmd("uwsm app -- waybar -c <(envsubst < ~/.config/waybar/config-top.jsonc.tpl)")
    hl.exec_cmd("uwsm app -- waybar -c <(envsubst < ~/.config/waybar/config-bottom.jsonc.tpl)")
    hl.exec_cmd("uwsm app -- waybar -c <(envsubst < ~/.config/waybar/config-bottom-secondary.jsonc.tpl)")

    -- Start Mako (notifications)
    hl.exec_cmd("uwsm app -- mako")
end)
