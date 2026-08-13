----------------
---- MONITORS ---
----------------

-- Environment variable for waybar (auto-generated)
hl.env("MONITOR_PRIMARY", "DP-1")

hl.monitor({
    output   = "DP-1",
    mode     = "3840x2160@60",
    position = "1920x0",
    scale    = 2,
})

hl.monitor({
    output   = "DP-2",
    mode     = "1920x1080@165",
    position = "0x0",
    scale    = 1,
})
