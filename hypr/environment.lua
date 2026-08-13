-----------------------------
---- ENVIRONMENT VARIABLES ---
-----------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Electron apps (Slack, Discord, etc.) - Better Wayland support
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
