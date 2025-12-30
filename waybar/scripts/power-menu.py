#!/usr/bin/env python3
import gi
import subprocess
import sys
import os
import getpass
from datetime import timedelta

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GLib

try:
    gi.require_version("GtkLayerShell", "0.1")
    from gi.repository import GtkLayerShell
    HAS_LAYER_SHELL = True
except (ValueError, ImportError):
    HAS_LAYER_SHELL = False

# Get system uptime
def get_uptime():
    try:
        with open('/proc/uptime', 'r') as f:
            uptime_seconds = float(f.readline().split()[0])
            uptime = timedelta(seconds=int(uptime_seconds))
            days = uptime.days
            hours, remainder = divmod(uptime.seconds, 3600)
            minutes, _ = divmod(remainder, 60)

            if days > 0:
                return f"{days}d {hours}h {minutes}m"
            elif hours > 0:
                return f"{hours}h {minutes}m"
            else:
                return f"{minutes}m"
    except:
        return "Unknown"

# Power actions
ACTIONS = [
    {
        'id': 'lock',
        'label': 'Lock Screen',
        'icon': '',
        'key': 'l',
        'command': 'hyprlock',
        'confirm': False,
        'description': 'Lock your screen'
    },
    {
        'id': 'suspend',
        'label': 'Suspend',
        'icon': '',
        'key': 's',
        'command': 'systemctl suspend',
        'confirm': False,
        'description': 'Suspend to RAM'
    },
    {
        'id': 'hibernate',
        'label': 'Hibernate',
        'icon': '󰒲',
        'key': 'h',
        'command': 'systemctl hibernate',
        'confirm': False,
        'description': 'Suspend to disk'
    },
    {
        'id': 'logout',
        'label': 'Logout',
        'icon': '󰩈',
        'key': 'o',
        'command': 'hyprctl dispatch exit',
        'confirm': True,
        'description': 'End your session'
    },
    {
        'id': 'reboot',
        'label': 'Reboot',
        'icon': '',
        'key': 'r',
        'command': 'systemctl reboot',
        'confirm': True,
        'description': 'Restart your computer'
    },
    {
        'id': 'shutdown',
        'label': 'Shutdown',
        'icon': '⏻',
        'key': 'p',
        'command': 'systemctl poweroff',
        'confirm': True,
        'description': 'Power off your computer'
    }
]

# Global state
current_view = 'main'  # 'main' or 'confirm'
pending_action = None
mouse_entered = False
close_timeout_id = None

# Create main window
win = Gtk.Window()
win.set_title("Power Menu")
win.set_decorated(False)
win.set_resizable(False)
win.set_type_hint(Gdk.WindowTypeHint.DIALOG)
win.set_default_size(350, -1)

# Setup layer shell if available
if HAS_LAYER_SHELL:
    GtkLayerShell.init_for_window(win)
    GtkLayerShell.set_layer(win, GtkLayerShell.Layer.OVERLAY)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.BOTTOM, True)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.RIGHT, True)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.BOTTOM, 35)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.RIGHT, 10)
    GtkLayerShell.set_keyboard_mode(win, GtkLayerShell.KeyboardMode.ON_DEMAND)

# Create main container (will switch between main view and confirm view)
main_container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)

def execute_action(action):
    """Execute a power action"""
    try:
        # For logout, just run the command directly
        if action['id'] == 'logout':
            subprocess.Popen(action['command'], shell=True)
        else:
            subprocess.run(action['command'], shell=True, check=True)
        Gtk.main_quit()
    except Exception as e:
        print(f"Error executing {action['label']}: {e}")

def show_main_view():
    """Show the main power menu"""
    global current_view, mouse_entered, close_timeout_id
    current_view = 'main'

    # Reset hover state to prevent auto-close when switching views
    mouse_entered = True
    if close_timeout_id is not None:
        GLib.source_remove(close_timeout_id)
        close_timeout_id = None

    # Clear container
    for child in main_container.get_children():
        main_container.remove(child)

    main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)

    # Header with close button
    header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
    header_box.set_border_width(15)

    header_label = Gtk.Label()
    header_label.set_xalign(0)
    header_label.set_markup("<span size='large'><b>⏻ Power Menu</b></span>")
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

    # System info
    info_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
    info_box.set_border_width(12)
    info_box.get_style_context().add_class("info-box")

    # User info
    user_label = Gtk.Label()
    username = getpass.getuser()
    user_label.set_markup(f"<small>User: <b>{username}</b></small>")
    user_label.set_xalign(0)

    # Uptime info
    uptime_label = Gtk.Label()
    uptime_label.set_markup(f"<small>Uptime: <b>{get_uptime()}</b></small>")
    uptime_label.set_xalign(0)

    info_box.pack_start(user_label, False, False, 0)
    info_box.pack_start(uptime_label, False, False, 0)
    main_box.pack_start(info_box, False, False, 0)

    # Add another separator
    separator2 = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
    main_box.pack_start(separator2, False, False, 0)

    # Action buttons
    actions_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
    actions_box.set_border_width(8)

    for action in ACTIONS:
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        button_box.set_border_width(10)
        button_box.get_style_context().add_class("action-button")

        # Make it a button
        event_box = Gtk.EventBox()
        event_box.add(button_box)
        event_box.set_name(action['id'])

        # Icon
        icon_label = Gtk.Label(label=action['icon'])
        icon_label.set_width_chars(3)
        icon_label.get_style_context().add_class("action-icon")

        # Text container
        text_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        text_box.set_hexpand(True)

        # Action label
        label = Gtk.Label()
        label.set_markup(f"<b>{action['label']}</b>")
        label.set_xalign(0)

        # Description
        desc_label = Gtk.Label()
        desc_label.set_markup(f"<small>{action['description']}</small>")
        desc_label.set_xalign(0)
        desc_label.get_style_context().add_class("action-description")

        text_box.pack_start(label, False, False, 0)
        text_box.pack_start(desc_label, False, False, 0)

        # Keyboard shortcut hint
        key_label = Gtk.Label()
        key_label.set_markup(f"<small><tt>{action['key'].upper()}</tt></small>")
        key_label.get_style_context().add_class("key-hint")

        button_box.pack_start(icon_label, False, False, 0)
        button_box.pack_start(text_box, True, True, 0)
        button_box.pack_start(key_label, False, False, 0)

        # Click handler
        def on_action_click(widget, event, act=action):
            if act['confirm']:
                show_confirm_view(act)
            else:
                execute_action(act)

        event_box.connect("button-press-event", on_action_click)

        # Hover effect
        def on_enter(widget, event):
            widget.get_style_context().add_class("action-button-hover")

        def on_leave(widget, event):
            widget.get_style_context().remove_class("action-button-hover")

        event_box.connect("enter-notify-event", on_enter)
        event_box.connect("leave-notify-event", on_leave)

        actions_box.pack_start(event_box, False, False, 0)

    main_box.pack_start(actions_box, True, True, 0)

    main_container.pack_start(main_box, True, True, 0)
    main_container.show_all()

def show_confirm_view(action):
    """Show confirmation dialog for destructive actions"""
    global current_view, pending_action, mouse_entered, close_timeout_id
    current_view = 'confirm'
    pending_action = action

    # Reset hover state to prevent auto-close when switching views
    mouse_entered = True
    if close_timeout_id is not None:
        GLib.source_remove(close_timeout_id)
        close_timeout_id = None

    # Clear container
    for child in main_container.get_children():
        main_container.remove(child)

    confirm_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)

    # Header
    header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
    header_box.set_border_width(15)

    header_label = Gtk.Label()
    header_label.set_xalign(0)
    header_label.set_markup(f"<b>{action['icon']} Confirm {action['label']}</b>")
    header_label.set_hexpand(True)

    close_button = Gtk.Button(label="✕")
    close_button.connect("clicked", lambda *_: Gtk.main_quit())
    close_button.get_style_context().add_class("close-button")

    header_box.pack_start(header_label, True, True, 0)
    header_box.pack_start(close_button, False, False, 0)

    confirm_box.pack_start(header_box, False, False, 0)

    # Add separator
    separator = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
    confirm_box.pack_start(separator, False, False, 0)

    # Confirmation message
    message_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
    message_box.set_border_width(30)
    message_box.set_halign(Gtk.Align.CENTER)

    icon_label = Gtk.Label()
    icon_label.set_markup(f"<span font='48'>{action['icon']}</span>")

    message_label = Gtk.Label()
    message_label.set_markup(f"<big>Are you sure you want to <b>{action['label'].lower()}</b>?</big>")
    message_label.set_line_wrap(True)
    message_label.set_max_width_chars(30)
    message_label.set_justify(Gtk.Justification.CENTER)

    message_box.pack_start(icon_label, False, False, 0)
    message_box.pack_start(message_label, False, False, 10)

    confirm_box.pack_start(message_box, True, True, 0)

    # Buttons
    button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
    button_box.set_border_width(15)
    button_box.set_homogeneous(True)

    cancel_btn = Gtk.Button(label="Cancel")
    cancel_btn.get_style_context().add_class("cancel-button")
    cancel_btn.connect("clicked", lambda *_: show_main_view())

    confirm_btn = Gtk.Button(label=f"{action['label']} Now")
    confirm_btn.get_style_context().add_class("confirm-button")
    confirm_btn.connect("clicked", lambda *_: execute_action(action))

    button_box.pack_start(cancel_btn, True, True, 0)
    button_box.pack_start(confirm_btn, True, True, 0)

    confirm_box.pack_start(button_box, False, False, 0)

    main_container.pack_start(confirm_box, True, True, 0)
    main_container.show_all()

# Initialize with main view
show_main_view()
win.add(main_container)

# Style the window
css_provider = Gtk.CssProvider()
css_provider.load_from_data(b"""
window {
    background-color: rgba(30, 30, 46, 0.95);
    border: 2px solid rgba(137, 180, 250, 0.8);
    border-radius: 8px;
}
.info-box {
    background-color: rgba(137, 180, 250, 0.1);
    border-radius: 4px;
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
.action-description {
    color: #a6adc8;
}
.key-hint {
    color: #89b4fa;
    background-color: rgba(137, 180, 250, 0.2);
    border: 1px solid rgba(137, 180, 250, 0.3);
    border-radius: 3px;
    padding: 2px 6px;
    font-family: monospace;
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
.cancel-button {
    background-color: rgba(166, 173, 200, 0.3);
    border: 1px solid rgba(166, 173, 200, 0.5);
    border-radius: 4px;
    color: #a6adc8;
    padding: 10px;
}
.cancel-button:hover {
    background-color: rgba(166, 173, 200, 0.5);
}
.confirm-button {
    background-color: rgba(243, 139, 168, 0.3);
    border: 1px solid rgba(243, 139, 168, 0.5);
    border-radius: 4px;
    color: #f38ba8;
    padding: 10px;
    font-weight: bold;
}
.confirm-button:hover {
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
    keyname = Gdk.keyval_name(key).lower()

    # Escape always closes or goes back
    if key == Gdk.KEY_Escape:
        if current_view == 'confirm':
            show_main_view()
        else:
            Gtk.main_quit()
        return True

    # In main view, handle action shortcuts
    if current_view == 'main':
        for action in ACTIONS:
            if keyname == action['key']:
                if action['confirm']:
                    show_confirm_view(action)
                else:
                    execute_action(action)
                return True

    # In confirm view, Y confirms, N/Esc cancels
    elif current_view == 'confirm':
        if keyname == 'y':
            execute_action(pending_action)
            return True
        elif keyname == 'n':
            show_main_view()
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
    global close_timeout_id
    # Always close on focus loss after a short delay
    # If focus returns (clicking internal widgets), it will be cancelled
    if close_timeout_id is not None:
        GLib.source_remove(close_timeout_id)
    close_timeout_id = GLib.timeout_add(150, Gtk.main_quit)
    return False

def on_focus_in(widget, event):
    global close_timeout_id
    # Cancel close if we regain focus (internal button clicks)
    if close_timeout_id is not None:
        GLib.source_remove(close_timeout_id)
        close_timeout_id = None
    return False

win.connect("enter-notify-event", on_enter_notify)
win.connect("leave-notify-event", on_leave_notify)
win.connect("focus-out-event", on_focus_out)
win.connect("focus-in-event", on_focus_in)

Gtk.main()
