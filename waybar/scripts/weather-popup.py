#!/usr/bin/env python3
import gi
import subprocess
import threading
import re

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GLib

# Basic ANSI 16-color mapping
ANSI_BASIC_COLORS = {
    30: "#45475a", 31: "#f38ba8", 32: "#a6e3a1", 33: "#f9e2af",
    34: "#89b4fa", 35: "#cba6f7", 36: "#94e2d5", 37: "#bac2de",
    90: "#585b70", 91: "#f38ba8", 92: "#a6e3a1", 93: "#f9e2af",
    94: "#89b4fa", 95: "#cba6f7", 96: "#94e2d5", 97: "#cdd6f4",
}

def ansi_256_to_hex(code):
    """Convert ANSI 256-color code to hex color"""
    if code < 16:
        # Basic colors
        basic = [
            "#1e1e2e", "#f38ba8", "#a6e3a1", "#f9e2af",
            "#89b4fa", "#cba6f7", "#94e2d5", "#bac2de",
            "#45475a", "#f38ba8", "#a6e3a1", "#f9e2af",
            "#89b4fa", "#cba6f7", "#94e2d5", "#cdd6f4",
        ]
        return basic[code]
    elif code < 232:
        # 216 color cube (6x6x6)
        code -= 16
        r = (code // 36) * 51
        g = ((code // 6) % 6) * 51
        b = (code % 6) * 51
        return f"#{r:02x}{g:02x}{b:02x}"
    else:
        # Grayscale (24 shades)
        gray = (code - 232) * 10 + 8
        return f"#{gray:02x}{gray:02x}{gray:02x}"

def ansi_to_pango(text):
    """Convert ANSI escape codes to Pango markup"""
    # Escape special XML characters first
    text = text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

    result = []
    open_tags = []

    # Pattern for ANSI escape sequences
    ansi_pattern = re.compile(r'\x1b\[([0-9;]*)m')

    last_end = 0
    for match in ansi_pattern.finditer(text):
        # Add text before this escape sequence
        result.append(text[last_end:match.start()])

        codes_str = match.group(1) if match.group(1) else '0'
        codes = codes_str.split(';')

        i = 0
        while i < len(codes):
            code = int(codes[i]) if codes[i] else 0

            if code == 0:
                # Reset - close all open tags
                while open_tags:
                    result.append(open_tags.pop())
            elif code == 1:
                # Bold
                result.append("<b>")
                open_tags.append("</b>")
            elif code == 3:
                # Italic
                result.append("<i>")
                open_tags.append("</i>")
            elif code == 4:
                # Underline
                result.append("<u>")
                open_tags.append("</u>")
            elif code == 38 and i + 2 < len(codes) and codes[i + 1] == '5':
                # 256-color foreground: 38;5;XXX
                color_code = int(codes[i + 2])
                color = ansi_256_to_hex(color_code)
                result.append(f'<span foreground="{color}">')
                open_tags.append("</span>")
                i += 2  # Skip the next two codes
            elif code == 48 and i + 2 < len(codes) and codes[i + 1] == '5':
                # 256-color background: 48;5;XXX
                color_code = int(codes[i + 2])
                color = ansi_256_to_hex(color_code)
                result.append(f'<span background="{color}">')
                open_tags.append("</span>")
                i += 2  # Skip the next two codes
            elif code in ANSI_BASIC_COLORS:
                # Basic foreground color
                color = ANSI_BASIC_COLORS[code]
                result.append(f'<span foreground="{color}">')
                open_tags.append("</span>")
            elif 40 <= code <= 47:
                # Basic background color
                bg_code = code - 10
                if bg_code in ANSI_BASIC_COLORS:
                    color = ANSI_BASIC_COLORS[bg_code]
                    result.append(f'<span background="{color}">')
                    open_tags.append("</span>")

            i += 1

        last_end = match.end()

    # Add remaining text
    result.append(text[last_end:])

    # Close any remaining open tags
    while open_tags:
        result.append(open_tags.pop())

    return ''.join(result)

try:
    gi.require_version("GtkLayerShell", "0.1")
    from gi.repository import GtkLayerShell
    HAS_LAYER_SHELL = True
except (ValueError, ImportError):
    HAS_LAYER_SHELL = False

# Configuration
CITY = "Sao_Carlos"

# View modes with their wttr.in format codes
VIEW_MODES = [
    {"id": "current", "label": "Current", "code": "0", "icon": ""},
    {"id": "today", "label": "Today", "code": "1", "icon": ""},
    {"id": "3day", "label": "3-Day", "code": "", "icon": ""},
    {"id": "compact", "label": "Compact", "code": "0Fq", "icon": ""},
]

# Global state
mouse_entered = False
close_timeout_id = None
current_view_idx = 0

# Create main window
win = Gtk.Window()
win.set_title("Weather")
win.set_decorated(False)
win.set_resizable(False)
win.set_type_hint(Gdk.WindowTypeHint.DIALOG)
win.set_default_size(450, -1)

# Setup layer shell if available - TOP CENTER
if HAS_LAYER_SHELL:
    GtkLayerShell.init_for_window(win)
    GtkLayerShell.set_layer(win, GtkLayerShell.Layer.OVERLAY)
    # Anchor to top, center horizontally
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.TOP, True)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.BOTTOM, False)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.LEFT, False)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.RIGHT, False)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.TOP, 35)  # Below waybar
    GtkLayerShell.set_keyboard_mode(win, GtkLayerShell.KeyboardMode.ON_DEMAND)

# Main container
main_container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)

# Content area (will be replaced when refreshing)
content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)

def fetch_weather(format_code="0"):
    """Fetch weather data from wttr.in"""
    try:
        # F=no follow line, keep ANSI colors
        url = f"http://wttr.in/{CITY}?{format_code}F"
        result = subprocess.check_output(
            ["curl", "-s", url],
            text=True,
            timeout=10
        )
        return result.strip()
    except subprocess.TimeoutExpired:
        return "Error: Request timed out\n\nPress R to retry"
    except Exception as e:
        return f"Error: {str(e)}\n\nPress R to retry"

def show_loading():
    """Show loading spinner"""
    for child in content_box.get_children():
        content_box.remove(child)

    loading_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
    loading_box.set_border_width(40)
    loading_box.set_halign(Gtk.Align.CENTER)

    spinner = Gtk.Spinner()
    spinner.set_size_request(48, 48)
    spinner.start()

    label = Gtk.Label(label="Fetching weather...")
    label.get_style_context().add_class("loading-text")

    loading_box.pack_start(spinner, False, False, 0)
    loading_box.pack_start(label, False, False, 0)

    content_box.pack_start(loading_box, True, True, 0)
    content_box.show_all()

def show_weather(weather_data):
    """Display weather data with ANSI colors converted to Pango markup"""
    for child in content_box.get_children():
        content_box.remove(child)

    weather_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
    weather_box.set_border_width(15)

    # Convert ANSI colors to Pango markup
    pango_text = ansi_to_pango(weather_data)

    # Weather content with monospace font
    content = Gtk.Label()
    content.set_markup(f'<span font_family="monospace">{pango_text}</span>')
    content.set_xalign(0)
    content.set_selectable(True)
    content.set_line_wrap(False)
    content.get_style_context().add_class("weather-content")

    weather_box.pack_start(content, False, False, 0)
    content_box.pack_start(weather_box, True, True, 0)
    content_box.show_all()

def refresh_weather():
    """Refresh weather in background thread"""
    show_loading()
    format_code = VIEW_MODES[current_view_idx]["code"]

    def fetch_and_update():
        weather = fetch_weather(format_code)
        GLib.idle_add(show_weather, weather)

    thread = threading.Thread(target=fetch_and_update)
    thread.daemon = True
    thread.start()

def cycle_view(direction=1):
    """Cycle through view modes"""
    global current_view_idx
    current_view_idx = (current_view_idx + direction) % len(VIEW_MODES)
    update_view_buttons()
    refresh_weather()

def set_view(idx):
    """Set specific view mode"""
    global current_view_idx
    current_view_idx = idx
    update_view_buttons()
    refresh_weather()

def update_view_buttons():
    """Update view button states"""
    for i, btn in enumerate(view_buttons):
        if i == current_view_idx:
            btn.get_style_context().add_class("active")
        else:
            btn.get_style_context().remove_class("active")

# Header with close button
header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
header_box.set_border_width(15)

header_label = Gtk.Label()
header_label.set_xalign(0)
header_label.set_markup(f"<span size='large'><b> Weather: {CITY.replace('_', ' ')}</b></span>")
header_label.set_hexpand(True)

close_button = Gtk.Button(label="✕")
close_button.connect("clicked", lambda *_: Gtk.main_quit())
close_button.get_style_context().add_class("close-button")

header_box.pack_start(header_label, True, True, 0)
header_box.pack_start(close_button, False, False, 0)

main_container.pack_start(header_box, False, False, 0)

# View mode buttons
view_bar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
view_bar.set_border_width(10)
view_bar.set_halign(Gtk.Align.CENTER)

view_buttons = []
for i, mode in enumerate(VIEW_MODES):
    btn = Gtk.Button(label=f"{mode['icon']} {mode['label']}")
    btn.get_style_context().add_class("view-btn")
    if i == 0:
        btn.get_style_context().add_class("active")
    btn.connect("clicked", lambda w, idx=i: set_view(idx))
    view_bar.pack_start(btn, False, False, 0)
    view_buttons.append(btn)

main_container.pack_start(view_bar, False, False, 0)

# Separator
separator = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
main_container.pack_start(separator, False, False, 0)

# Content area
main_container.pack_start(content_box, True, True, 0)

# Footer
separator2 = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
main_container.pack_start(separator2, False, False, 0)

footer_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
footer_box.set_border_width(10)

refresh_btn = Gtk.Button(label=" Refresh")
refresh_btn.connect("clicked", lambda *_: refresh_weather())
refresh_btn.get_style_context().add_class("action-btn")

# Keyboard hints
hints_label = Gtk.Label()
hints_label.set_markup("<small><tt>R</tt> Refresh  <tt>1-4</tt> Views  <tt>←→</tt> Cycle  <tt>Esc</tt> Close</small>")
hints_label.get_style_context().add_class("hints")
hints_label.set_hexpand(True)
hints_label.set_xalign(1)

footer_box.pack_start(refresh_btn, False, False, 0)
footer_box.pack_start(hints_label, True, True, 0)

main_container.pack_start(footer_box, False, False, 0)

win.add(main_container)

# Style the window
css_provider = Gtk.CssProvider()
css_provider.load_from_data(b"""
window {
    background-color: rgba(30, 30, 46, 0.95);
    border: 2px solid rgba(137, 180, 250, 0.8);
    border-radius: 12px;
}
label {
    color: #cdd6f4;
}
.weather-content {
    font-family: monospace;
    font-size: 11pt;
    padding: 10px;
}
.loading-text {
    color: #a6adc8;
    font-size: 12pt;
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
.view-btn {
    background-color: rgba(69, 71, 90, 0.5);
    border: 1px solid rgba(137, 180, 250, 0.3);
    border-radius: 6px;
    color: #a6adc8;
    padding: 6px 14px;
    font-size: 10pt;
}
.view-btn:hover {
    background-color: rgba(137, 180, 250, 0.3);
    color: #cdd6f4;
}
.view-btn.active {
    background-color: rgba(137, 180, 250, 0.4);
    border: 1px solid rgba(137, 180, 250, 0.8);
    color: #89b4fa;
}
.action-btn {
    background-color: rgba(137, 180, 250, 0.3);
    border: 1px solid rgba(137, 180, 250, 0.5);
    border-radius: 4px;
    color: #89b4fa;
    padding: 6px 12px;
}
.action-btn:hover {
    background-color: rgba(137, 180, 250, 0.5);
}
.hints {
    color: #6c7086;
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

# Initial weather fetch
refresh_weather()

# Keyboard shortcuts
def on_key_press(widget, event):
    key = event.keyval
    keyname = Gdk.keyval_name(key).lower() if Gdk.keyval_name(key) else ""

    if key == Gdk.KEY_Escape:
        Gtk.main_quit()
        return True
    elif keyname == 'r':
        refresh_weather()
        return True
    elif keyname in ['1', '2', '3', '4']:
        idx = int(keyname) - 1
        if idx < len(VIEW_MODES):
            set_view(idx)
        return True
    elif keyname in ['left', 'h']:
        cycle_view(-1)
        return True
    elif keyname in ['right', 'l']:
        cycle_view(1)
        return True

    return False

win.connect("key-press-event", on_key_press)

# Auto-close after 90 seconds (longer for weather reading)
GLib.timeout_add_seconds(90, Gtk.main_quit)

# Smart click-away-to-close with hover delay
def schedule_close():
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
