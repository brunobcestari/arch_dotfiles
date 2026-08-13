-- #######################################################################################
-- Hyprland Configuration - Modular Structure (Lua)
-- #######################################################################################
--
-- This configuration is split into multiple files for better organization and maintainability:
--   monitors.lua       : Monitor configuration
--   environment.lua     : Environment variables
--   programs.lua        : Default applications (required directly by files that use them)
--   look-and-feel.lua  : Visual settings, animations, layouts (incl. scrolling layout)
--   input.lua           : Input devices, keyboard, gestures
--   keybindings.lua     : Keyboard shortcuts
--   rules.lua            : Window and workspace rules
--   autostart.lua        : Startup applications
--
-- See https://wiki.hypr.land/Configuring/Start/ for more information
--
-- #######################################################################################

require("monitors")
require("environment")
require("look-and-feel")
require("input")
require("keybindings")
require("rules")
require("autostart")
