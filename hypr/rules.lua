------------------------------
---- WINDOWS AND WORKSPACES --
------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/ for more
-- See https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/ for workspace rules

-- Workstyle https://github.com/pierrechevalier83/workstyle
hl.on("hyprland.start", function()
    hl.exec_cmd("workstyle &> /tmp/workstyle.log")
end)

-- Window rules
hl.window_rule({
    name  = "float-pavucontrol",
    match = { class = ".+\\.pavucontrol$" },
    float = true,
})

hl.window_rule({
    name  = "float-baobab",
    match = { class = ".+\\.baobab$" },
    float = true,
    size  = {950, 580},
})

hl.window_rule({
    name  = "float-nm-connection-editor",
    match = { class = "nm-connection-editor" },
    float = true,
    size  = {600, 500},
})

hl.window_rule({
    name  = "float-psensor",
    match = { class = "psensor" },
    float = true,
    size  = {1360, 700},
})

-- Waydroid rules
hl.window_rule({
    name  = "float-waydroid",
    match = { class = "^waydroid\\..+" },
    float = true,
})

-- Ignore maximize requests from apps. You'll probably like this.
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})
