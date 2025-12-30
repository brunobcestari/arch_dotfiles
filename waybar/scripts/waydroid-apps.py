#!/usr/bin/env python3
import gi
import subprocess
import re

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GLib

try:
    gi.require_version("GtkLayerShell", "0.1")
    from gi.repository import GtkLayerShell
    HAS_LAYER_SHELL = True
except (ValueError, ImportError):
    HAS_LAYER_SHELL = False

# Get list of installed Waydroid apps
def get_installed_apps():
    try:
        result = subprocess.run(['waydroid', 'app', 'list'], capture_output=True, text=True)
        apps = []
        current_app = {}

        for line in result.stdout.split('\n'):
            line = line.strip()
            if line.startswith('Name:'):
                if current_app:
                    apps.append(current_app)
                current_app = {'name': line.replace('Name:', '').strip()}
            elif line.startswith('packageName:'):
                current_app['package'] = line.replace('packageName:', '').strip()

        if current_app and 'package' in current_app:
            apps.append(current_app)

        return sorted(apps, key=lambda x: x['name'])
    except:
        return []

# Check if Waydroid session is running
def get_waydroid_status():
    try:
        result = subprocess.run(['waydroid', 'status'], capture_output=True, text=True)
        for line in result.stdout.split('\n'):
            if 'Session:' in line:
                return 'RUNNING' in line
        return False
    except:
        return False

# App icons mapping (nerd font icons)
APP_ICONS = {
    'Files': '',
    'Contacts': '',
    'Gallery': '',
    'Browser': '',
    'Music': '',
    'Calendar': '',
    'Camera': '',
    'Settings': '',
    'Calculator': '',
    'Clock': '',
    'Recorder': '',
}

# Global state
mouse_entered = False
close_timeout_id = None

# Create main window
win = Gtk.Window()
win.set_title("Waydroid Apps")
win.set_decorated(False)
win.set_resizable(False)
win.set_type_hint(Gdk.WindowTypeHint.DIALOG)
win.set_default_size(300, -1)

# Setup layer shell if available
if HAS_LAYER_SHELL:
    GtkLayerShell.init_for_window(win)
    GtkLayerShell.set_layer(win, GtkLayerShell.Layer.OVERLAY)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.TOP, True)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.RIGHT, True)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.TOP, 35)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.RIGHT, 10)
    GtkLayerShell.set_keyboard_mode(win, GtkLayerShell.KeyboardMode.ON_DEMAND)

# Create main container
main_container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)

def launch_app(package_name, app_name):
    """Launch a Waydroid app"""
    try:
        # Check if session is running
        if not get_waydroid_status():
            subprocess.run(['notify-send', '-a', 'Waydroid', f'Starting container to launch {app_name}...', '-i', 'android', '-t', '3000'])
            subprocess.Popen('waydroid session start', shell=True)
            # Wait a bit then launch the app
            GLib.timeout_add(3000, lambda: subprocess.Popen(['waydroid', 'app', 'launch', package_name]))
        else:
            subprocess.Popen(['waydroid', 'app', 'launch', package_name])
            subprocess.run(['notify-send', '-a', 'Waydroid', f'Opening {app_name}', '-i', 'android', '-t', '2000'])
        Gtk.main_quit()
    except Exception as e:
        print(f"Error launching {app_name}: {e}")
        subprocess.run(['notify-send', '-a', 'Waydroid', f'Failed to launch {app_name}: {str(e)}', '-i', 'error', '-t', '5000'])

# Header with close button
header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
header_box.set_border_width(15)

# Get status for header
is_running = get_waydroid_status()
apps = get_installed_apps()

header_label = Gtk.Label()
header_label.set_xalign(0)
header_label.set_markup(f"<span size='large'><b> Android Apps</b></span> <small>({len(apps)} apps)</small>")
header_label.set_hexpand(True)

close_button = Gtk.Button(label="✕")
close_button.connect("clicked", lambda *_: Gtk.main_quit())
close_button.get_style_context().add_class("close-button")

header_box.pack_start(header_label, True, True, 0)
header_box.pack_start(close_button, False, False, 0)

main_box.pack_start(header_box, False, False, 0)

# Add separator
separator = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
main_box.pack_start(separator, False, False, 0)

# Check if session is running
if not is_running:
    info_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
    info_box.set_border_width(20)
    info_label = Gtk.Label()
    info_label.set_markup("<small>Waydroid session not running.\nApps will start the session automatically.</small>")
    info_label.set_justify(Gtk.Justification.CENTER)
    info_label.get_style_context().add_class("info-text")
    info_box.pack_start(info_label, False, False, 0)
    main_box.pack_start(info_box, False, False, 0)

    separator2 = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
    main_box.pack_start(separator2, False, False, 0)

# Apps list in scrollable window
scrolled = Gtk.ScrolledWindow()
scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
scrolled.set_max_content_height(400)
scrolled.set_propagate_natural_height(True)

apps_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
apps_box.set_border_width(8)

if apps:
    for app in apps:
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        button_box.set_border_width(10)
        button_box.get_style_context().add_class("action-button")

        # Make it a button
        event_box = Gtk.EventBox()
        event_box.add(button_box)

        # Icon
        icon = APP_ICONS.get(app['name'], '')
        icon_label = Gtk.Label(label=icon)
        icon_label.set_width_chars(3)
        icon_label.get_style_context().add_class("action-icon")

        # App name
        label = Gtk.Label()
        label.set_markup(f"<b>{app['name']}</b>")
        label.set_xalign(0)
        label.set_hexpand(True)

        button_box.pack_start(icon_label, False, False, 0)
        button_box.pack_start(label, True, True, 0)

        # Click handler
        def on_app_click(widget, event, pkg=app['package'], name=app['name']):
            launch_app(pkg, name)

        event_box.connect("button-press-event", on_app_click)

        # Hover effect
        def on_enter(widget, event):
            widget.get_style_context().add_class("action-button-hover")

        def on_leave(widget, event):
            widget.get_style_context().remove_class("action-button-hover")

        event_box.connect("enter-notify-event", on_enter)
        event_box.connect("leave-notify-event", on_leave)

        apps_box.pack_start(event_box, False, False, 0)
else:
    no_apps_label = Gtk.Label()
    no_apps_label.set_markup("<small>No apps installed</small>")
    no_apps_label.set_border_width(20)
    apps_box.pack_start(no_apps_label, False, False, 0)

scrolled.add(apps_box)
main_box.pack_start(scrolled, True, True, 0)

main_container.pack_start(main_box, True, True, 0)
win.add(main_container)

# Style the window
css_provider = Gtk.CssProvider()
css_provider.load_from_data(b"""
window {
    background-color: rgba(30, 30, 46, 0.95);
    border: 2px solid rgba(137, 180, 250, 0.8);
    border-radius: 8px;
}
.action-button {
    background-color: transparent;
    color: #cdd6f4;
    padding: 5px;
    border-radius: 6px;
    transition: all 200ms ease;
}
.action-button-hover {
    background-color: rgba(137, 180, 250, 0.2);
}
.action-icon {
    font-size: 24px;
}
.info-text {
    color: #a6adc8;
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

# Keyboard shortcuts
def on_key_press(widget, event):
    key = event.keyval

    # Escape closes
    if key == Gdk.KEY_Escape:
        Gtk.main_quit()
        return True

    return False

win.connect("key-press-event", on_key_press)

# Auto-close after 30 seconds of inactivity
GLib.timeout_add_seconds(30, Gtk.main_quit)

# Smart click-away-to-close with hover delay
def schedule_close():
    """Actually close the window if mouse is still outside"""
    global mouse_entered
    if not mouse_entered:
        Gtk.main_quit()
    return False

def on_enter_notify(widget, event):
    global mouse_entered, close_timeout_id
    if event.detail != Gdk.NotifyType.INFERIOR:
        mouse_entered = True
        if close_timeout_id is not None:
            GLib.source_remove(close_timeout_id)
            close_timeout_id = None
    return False

def on_leave_notify(widget, event):
    global mouse_entered, close_timeout_id
    if event.detail != Gdk.NotifyType.INFERIOR:
        mouse_entered = False
        if close_timeout_id is not None:
            GLib.source_remove(close_timeout_id)
        close_timeout_id = GLib.timeout_add(1000, schedule_close)
    return False

def on_focus_out(widget, event):
    global close_timeout_id
    if close_timeout_id is not None:
        GLib.source_remove(close_timeout_id)
    close_timeout_id = GLib.timeout_add(150, Gtk.main_quit)
    return False

def on_focus_in(widget, event):
    global close_timeout_id
    if close_timeout_id is not None:
        GLib.source_remove(close_timeout_id)
        close_timeout_id = None
    return False

win.connect("enter-notify-event", on_enter_notify)
win.connect("leave-notify-event", on_leave_notify)
win.connect("focus-out-event", on_focus_out)
win.connect("focus-in-event", on_focus_in)

Gtk.main()
