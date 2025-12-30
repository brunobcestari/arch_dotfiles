#!/usr/bin/env python3
import gi
import subprocess
import sys

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GLib

try:
    gi.require_version("GtkLayerShell", "0.1")
    from gi.repository import GtkLayerShell
    HAS_LAYER_SHELL = True
except (ValueError, ImportError):
    HAS_LAYER_SHELL = False

# Get device type from command line argument
if len(sys.argv) < 2 or sys.argv[1] not in ["input", "output"]:
    print("Usage: audio-selector.py [input|output]")
    sys.exit(1)

device_type = sys.argv[1]
is_input = device_type == "input"

# Get audio devices from wpctl
try:
    wpctl_output = subprocess.check_output(["wpctl", "status"], text=True)
except Exception as e:
    print(f"Error: Could not get audio devices: {e}")
    sys.exit(1)

# Parse wpctl output to get devices
devices = []
in_audio = False
in_section = False
current_default = None

for line in wpctl_output.split('\n'):
    # Track Audio section
    if line.strip().startswith('Audio'):
        in_audio = True
        continue
    elif line.strip().startswith('Video'):
        in_audio = False
        continue

    if not in_audio:
        continue

    # Track Sinks/Sources section
    if is_input and 'Sources:' in line:
        in_section = True
        continue
    elif is_input and 'Filters:' in line:
        in_section = False
        continue
    elif not is_input and 'Sinks:' in line:
        in_section = True
        continue
    elif not is_input and 'Sources:' in line:
        in_section = False
        continue

    if not in_section:
        continue

    # Parse device lines
    line_stripped = line.replace('├', '').replace('─', '').replace('│', '').replace('└', '').strip()
    # Check for asterisk (default device marker)
    is_default = '*' in line_stripped
    # Remove asterisk and whitespace
    line_clean = line_stripped.replace('*', '').strip()

    # Check if this is a device line (starts with digit after cleanup)
    if line_clean and line_clean[0].isdigit():
        # Extract ID and name
        parts = line_clean.split('.', 1)
        if len(parts) == 2:
            device_id = parts[0].strip()
            device_name = parts[1].split('[')[0].strip()
            devices.append({
                'id': device_id,
                'name': device_name,
                'is_default': is_default
            })
            if is_default:
                current_default = device_id

# Create window
win = Gtk.Window()
win.set_title(f"Select {'Input' if is_input else 'Output'} Device")
win.set_decorated(False)
win.set_resizable(False)
win.set_type_hint(Gdk.WindowTypeHint.DIALOG)
win.set_default_size(400, -1)

# Setup layer shell if available
if HAS_LAYER_SHELL:
    GtkLayerShell.init_for_window(win)
    GtkLayerShell.set_layer(win, GtkLayerShell.Layer.OVERLAY)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.BOTTOM, True)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.RIGHT, True)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.BOTTOM, 35)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.RIGHT, 10)
    GtkLayerShell.set_keyboard_mode(win, GtkLayerShell.KeyboardMode.ON_DEMAND)

# Create content box
main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)

# Header with close button
header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
header_box.set_border_width(15)
header = Gtk.Label()
header.set_xalign(0)
icon = "" if is_input else "󰓃"
header.set_markup(f"<b>{icon} {'Input' if is_input else 'Output'} Devices</b>")
header.set_hexpand(True)

close_button = Gtk.Button(label="✕")
close_button.connect("clicked", lambda *_: Gtk.main_quit())
close_button.get_style_context().add_class("close-button")

header_box.pack_start(header, True, True, 0)
header_box.pack_start(close_button, False, False, 0)

main_box.pack_start(header_box, False, False, 0)

# Add separator
separator = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
main_box.pack_start(separator, False, False, 0)

# Device list
list_box = Gtk.ListBox()
list_box.set_selection_mode(Gtk.SelectionMode.NONE)
list_box.set_activate_on_single_click(True)  # Enable single-click activation
list_box.get_style_context().add_class("device-list")

def set_device(device_id):
    """Set the audio device as default"""
    try:
        subprocess.run(["wpctl", "set-default", device_id], check=True)
        # Give wpctl a moment to update
        import time
        time.sleep(0.1)

        # Update UI to show the new selection
        for row in list_box.get_children():
            box = row.get_child()
            check_label = box.get_children()[0]
            name_label = box.get_children()[1]

            if row in device_map and device_map[row] == device_id:
                # This is the newly selected device
                check_label.set_text("✓")
                name_label.set_markup(f"<b>{name_label.get_text()}</b>")
            else:
                # Other devices
                check_label.set_text(" ")
                # Remove bold if it was there
                name_label.set_text(name_label.get_text())

        # Window will close based on hover behavior (stays open while mouse is inside)
    except Exception as e:
        print(f"Error setting device: {e}")

# Store device mapping for row activation
device_map = {}

# Add devices to list
for device in devices:
    row = Gtk.ListBoxRow()
    row.set_activatable(True)  # Make row clickable
    row.get_style_context().add_class("device-row")

    box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
    box.set_border_width(10)

    # Checkmark for current device
    check_label = Gtk.Label(label="✓" if device['is_default'] else " ")
    check_label.set_width_chars(2)
    check_label.get_style_context().add_class("check-label")

    # Device name - bold if it's the default device
    name_label = Gtk.Label()
    name_label.set_xalign(0)
    name_label.set_hexpand(True)
    if device['is_default']:
        name_label.set_markup(f"<b>{device['name']}</b>")
    else:
        name_label.set_text(device['name'])

    box.pack_start(check_label, False, False, 0)
    box.pack_start(name_label, True, True, 0)

    row.add(box)
    list_box.add(row)

    # Store device ID for this row
    device_map[row] = device['id']

# Connect to row-activated signal on the ListBox
def on_row_activated(listbox, row):
    if row in device_map:
        set_device(device_map[row])

list_box.connect("row-activated", on_row_activated)

# Wrap list in scrolled window
scrolled = Gtk.ScrolledWindow()
scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
scrolled.set_max_content_height(400)
scrolled.set_propagate_natural_height(True)
scrolled.add(list_box)

main_box.pack_start(scrolled, True, True, 0)

# Add buttons footer
footer_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
footer_box.set_border_width(10)

settings_btn = Gtk.Button(label="⚙️  Settings")
settings_btn.connect("clicked", lambda *_: (subprocess.Popen(["pavucontrol"]), Gtk.main_quit()))
settings_btn.get_style_context().add_class("footer-button")

footer_box.pack_end(settings_btn, False, False, 0)

main_box.pack_start(footer_box, False, False, 0)

win.add(main_box)

# Style the window
css_provider = Gtk.CssProvider()
css_provider.load_from_data(b"""
window {
    background-color: rgba(30, 30, 46, 0.95);
    border: 2px solid rgba(137, 180, 250, 0.8);
    border-radius: 8px;
}
.device-list {
    background-color: transparent;
}
.device-row {
    background-color: transparent;
    color: #cdd6f4;
    padding: 5px;
    border-radius: 4px;
}
.device-row:hover {
    background-color: rgba(137, 180, 250, 0.2);
}
.device-row:active {
    background-color: rgba(137, 180, 250, 0.4);
}
.check-label {
    color: #a6e3a1;
    font-weight: bold;
}
label {
    color: #cdd6f4;
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
.footer-button {
    background-color: rgba(137, 180, 250, 0.3);
    border: 1px solid rgba(137, 180, 250, 0.5);
    border-radius: 4px;
    color: #89b4fa;
    padding: 8px 12px;
}
.footer-button:hover {
    background-color: rgba(137, 180, 250, 0.5);
}
separator {
    background-color: rgba(137, 180, 250, 0.3);
    min-height: 1px;
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

# Auto-close after 30 seconds of inactivity
GLib.timeout_add_seconds(30, Gtk.main_quit)

# Smart click-away-to-close with hover delay
mouse_entered = False
close_timeout_id = None

def schedule_close():
    """Actually close the window if mouse is still outside"""
    global mouse_entered
    if not mouse_entered:
        Gtk.main_quit()
    return False  # Don't repeat the timeout

def on_enter_notify(widget, event):
    global mouse_entered, close_timeout_id
    # Only track actual window entry, not child widget crossings
    if event.detail != Gdk.NotifyType.INFERIOR:
        mouse_entered = True
        # Cancel any pending close timeout
        if close_timeout_id is not None:
            GLib.source_remove(close_timeout_id)
            close_timeout_id = None
    return False

def on_leave_notify(widget, event):
    global mouse_entered, close_timeout_id
    # Only track actual window exit, not child widget crossings
    if event.detail != Gdk.NotifyType.INFERIOR:
        mouse_entered = False
        # Schedule close after 1 second of mouse being outside
        if close_timeout_id is not None:
            GLib.source_remove(close_timeout_id)
        close_timeout_id = GLib.timeout_add(1000, schedule_close)
    return False

def on_focus_out(widget, event):
    global mouse_entered, close_timeout_id
    # If focus is lost and mouse never entered, close after short delay
    # This handles clicking outside the window
    if not mouse_entered:
        if close_timeout_id is not None:
            GLib.source_remove(close_timeout_id)
        close_timeout_id = GLib.timeout_add(200, schedule_close)
    return False

win.connect("enter-notify-event", on_enter_notify)
win.connect("leave-notify-event", on_leave_notify)
win.connect("focus-out-event", on_focus_out)

Gtk.main()
