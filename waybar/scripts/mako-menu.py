#!/usr/bin/env python3
import gi
import subprocess
import json

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GLib

try:
    gi.require_version("GtkLayerShell", "0.1")
    from gi.repository import GtkLayerShell
    HAS_LAYER_SHELL = True
except (ValueError, ImportError):
    HAS_LAYER_SHELL = False

# Check if DND is active
def is_dnd_active():
    try:
        result = subprocess.run(['makoctl', 'mode'], capture_output=True, text=True)
        return 'do-not-disturb' in result.stdout
    except:
        return False

# Get notification history
def get_notification_history():
    try:
        result = subprocess.run(['makoctl', 'history'], capture_output=True, text=True)
        data = json.loads(result.stdout)
        notifications = data.get('data', [[]])[0]
        return notifications
    except:
        return []

# Global state
mouse_entered = False
close_timeout_id = None
dnd_active = is_dnd_active()
notifications = get_notification_history()

# Create main window
win = Gtk.Window()
win.set_title("Notifications")
win.set_decorated(False)
win.set_resizable(False)
win.set_type_hint(Gdk.WindowTypeHint.DIALOG)
win.set_default_size(350, -1)

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

def execute_action(action_id):
    """Execute a mako action"""
    try:
        if action_id == 'toggle-dnd':
            subprocess.run(['makoctl', 'mode', '-t', 'do-not-disturb'])
            subprocess.run([
                'notify-send', '-u', 'low', '-a', 'Mako',
                '-i', 'preferences-system-notifications',
                '-t', '2000', '-r', '9020',
                'Do Not Disturb: ' + ('OFF' if dnd_active else 'ON')
            ])
        elif action_id == 'dismiss-all':
            subprocess.run(['makoctl', 'dismiss', '--all'])
            subprocess.run([
                'notify-send', '-u', 'low', '-a', 'Mako',
                '-i', 'edit-clear-all',
                '-t', '2000', '-r', '9021',
                'All notifications dismissed'
            ])
        elif action_id == 'restore':
            subprocess.run(['makoctl', 'restore'])
        elif action_id == 'invoke-last':
            subprocess.run(['makoctl', 'invoke'])
        Gtk.main_quit()
    except Exception as e:
        print(f"Error executing action: {e}")
        subprocess.run([
            'notify-send', '-u', 'critical', '-a', 'Mako',
            '-i', 'dialog-error', '-t', '3000', '-r', '9022',
            'Mako Error', str(e)
        ])

# Actions
ACTIONS = [
    {
        'id': 'toggle-dnd',
        'label': 'Do Not Disturb: ' + ('ON' if dnd_active else 'OFF'),
        'icon': '' if dnd_active else '',
        'key': 'd',
        'description': 'Turn ' + ('off' if dnd_active else 'on') + ' Do Not Disturb mode'
    },
    {
        'id': 'dismiss-all',
        'label': 'Dismiss All',
        'icon': '',
        'key': 'x',
        'description': 'Dismiss all visible notifications'
    },
    {
        'id': 'restore',
        'label': 'Restore Last',
        'icon': '',
        'key': 'r',
        'description': 'Restore last dismissed notification'
    },
    {
        'id': 'invoke-last',
        'label': 'Invoke Action',
        'icon': '',
        'key': 'i',
        'description': 'Invoke default action on last notification'
    }
]

# Header with close button
header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
header_box.set_border_width(15)

status_icon = "" if dnd_active else ""
status_text = "Do Not Disturb" if dnd_active else f"{len(notifications)} in history"

header_label = Gtk.Label()
header_label.set_xalign(0)
header_label.set_markup(f"<span size='large'><b>{status_icon} Notifications</b></span> <small>({status_text})</small>")
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
        execute_action(act['id'])

    event_box.connect("button-press-event", on_action_click)

    # Hover effect
    def on_enter(widget, event):
        widget.get_style_context().add_class("action-button-hover")

    def on_leave(widget, event):
        widget.get_style_context().remove_class("action-button-hover")

    event_box.connect("enter-notify-event", on_enter)
    event_box.connect("leave-notify-event", on_leave)

    actions_box.pack_start(event_box, False, False, 0)

main_box.pack_start(actions_box, False, False, 0)

# Notification history section
if notifications:
    separator2 = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
    main_box.pack_start(separator2, False, False, 0)

    history_header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
    history_header.set_border_width(10)

    history_label = Gtk.Label()
    history_label.set_markup("<b>Recent Notifications</b>")
    history_label.set_xalign(0)
    history_header.pack_start(history_label, True, True, 0)

    main_box.pack_start(history_header, False, False, 0)

    # Scrollable notification list
    scrolled = Gtk.ScrolledWindow()
    scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
    scrolled.set_max_content_height(200)
    scrolled.set_propagate_natural_height(True)

    history_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
    history_box.set_border_width(8)

    # Show last 5 notifications
    for notif in notifications[:5]:
        notif_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        notif_box.set_border_width(8)
        notif_box.get_style_context().add_class("notification-item")

        # App name and summary
        app_name = notif.get('app-name', {}).get('data', 'Unknown')
        summary = notif.get('summary', {}).get('data', '')
        body = notif.get('body', {}).get('data', '')

        header = Gtk.Label()
        header.set_markup(f"<small><b>{app_name}</b></small>")
        header.set_xalign(0)
        header.set_ellipsize(3)  # PANGO_ELLIPSIZE_END

        if summary:
            summary_label = Gtk.Label()
            summary_label.set_text(summary)
            summary_label.set_xalign(0)
            summary_label.set_ellipsize(3)
            summary_label.get_style_context().add_class("notification-summary")

        if body:
            body_label = Gtk.Label()
            body_label.set_text(body[:100] + ('...' if len(body) > 100 else ''))
            body_label.set_xalign(0)
            body_label.set_line_wrap(True)
            body_label.set_max_width_chars(40)
            body_label.get_style_context().add_class("notification-body")

        notif_box.pack_start(header, False, False, 0)
        if summary:
            notif_box.pack_start(summary_label, False, False, 0)
        if body:
            notif_box.pack_start(body_label, False, False, 0)

        history_box.pack_start(notif_box, False, False, 0)

    scrolled.add(history_box)
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
.notification-item {
    background-color: rgba(137, 180, 250, 0.1);
    border-radius: 6px;
    margin: 2px 0;
}
.notification-summary {
    color: #cdd6f4;
}
.notification-body {
    color: #a6adc8;
    font-size: 0.9em;
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

    # Escape closes
    if key == Gdk.KEY_Escape:
        Gtk.main_quit()
        return True

    # Handle action shortcuts
    for action in ACTIONS:
        if keyname == action['key']:
            execute_action(action['id'])
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
