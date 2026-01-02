{
  "output": [ "!$MONITOR_PRIMARY", "*" ],
  "layer": "top",
  "position": "bottom",
  "height": 30,
  "spacing": 4,

  // Import all module definitions from external files
  "include": [
    "~/.config/waybar/modules/workspaces.json"
  ],

  // Layout: Left | Center | Right
  "modules-left": [
    "hyprland/workspaces",
    "hyprland/window"
  ],

  "modules-center": [],

  "modules-right": [
  ]

  // ============================================
  // Group Definitions
  // ============================================

}
