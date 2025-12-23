#!/usr/bin/env python3
import gi
import subprocess
import sys

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GLib, Pango

try:
    gi.require_version("GtkLayerShell", "0.1")
    from gi.repository import GtkLayerShell
    HAS_LAYER_SHELL = True
except (ValueError, ImportError):
    HAS_LAYER_SHELL = False

# Fetch weather from wttr.in
city = "Sao_Carlos"
try:
    weather = subprocess.check_output(
        ["curl", f"http://wttr.in/{city}?0&T"],
        text=True,
        timeout=5
    )
except subprocess.TimeoutExpired:
    weather = "Error: Could not fetch weather (timeout)"
except Exception as e:
    weather = f"Error: Could not fetch weather\n{str(e)}"

# Create window
win = Gtk.Window()
win.set_decorated(False)
win.set_resizable(False)
win.set_type_hint(Gdk.WindowTypeHint.DIALOG)

# Setup layer shell if available (for Wayland)
if HAS_LAYER_SHELL:
    GtkLayerShell.init_for_window(win)
    GtkLayerShell.set_layer(win, GtkLayerShell.Layer.OVERLAY)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.TOP, True)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.RIGHT, True)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.TOP, 35)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.RIGHT, 10)

# Create content box
box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
box.set_border_width(15)

# Header with close button
header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
header = Gtk.Label(label=f"Weather Report: {city}")
header.set_xalign(0)
header.set_markup(f"<b>Weather Report: {city}</b>")
header.set_hexpand(True)

close_button = Gtk.Button(label="✕")
close_button.connect("clicked", lambda *_: Gtk.main_quit())
close_button.get_style_context().add_class("close-button")

header_box.pack_start(header, True, True, 0)
header_box.pack_start(close_button, False, False, 0)

# Weather content with monospace font
content = Gtk.Label(label=weather)
content.set_xalign(0)
content.set_selectable(True)
content.set_line_wrap(False)
content.get_style_context().add_class("weather-content")

box.pack_start(header_box, False, False, 0)
box.pack_start(content, False, False, 0)

win.add(box)

# Style the window
css_provider = Gtk.CssProvider()
css_provider.load_from_data(b"""
window {
    background-color: rgba(30, 30, 46, 0.95);
    border: 2px solid rgba(137, 180, 250, 0.8);
    border-radius: 8px;
}
label {
    color: #cdd6f4;
    padding: 5px;
}
.weather-content {
    font-family: monospace;
    font-size: 10pt;
}
.close-button {
    background-color: rgba(243, 139, 168, 0.3);
    border: 1px solid rgba(243, 139, 168, 0.5);
    border-radius: 4px;
    color: #f38ba8;
    min-width: 30px;
    min-height: 30px;
    padding: 0;
}
.close-button:hover {
    background-color: rgba(243, 139, 168, 0.5);
}
""")
Gtk.StyleContext.add_provider_for_screen(
    Gdk.Screen.get_default(),
    css_provider,
    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
)

win.show_all()

# Close on Escape key
win.connect("key-press-event", lambda w, e: Gtk.main_quit() if e.keyval == Gdk.KEY_Escape else None)

# Auto-close after 30 seconds
GLib.timeout_add_seconds(30, Gtk.main_quit)

Gtk.main()
