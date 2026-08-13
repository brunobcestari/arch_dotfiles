---------------------
---- MY PROGRAMS ----
---------------------

-- Returns a table so other modules can do: local programs = require("programs")
return {
    terminal    = "alacritty",
    fileManager = "alacritty -e yazi",
    menu        = "rofi -show drun -show-icons",
    lock        = "hyprlock",
}
