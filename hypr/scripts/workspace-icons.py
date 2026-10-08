#!/usr/bin/env python3
"""Rename Hyprland workspaces to show icons of the windows they contain.

Drop-in replacement for workstyle, which broke with Hyprland's Lua config:
it still sends legacy `renameworkspace` dispatches, which Lua mode rejects.
Reads the same ~/.config/workstyle/config.toml so the icon mapping is unchanged.
"""

import json
import os
import socket
import subprocess
import sys
import tomllib
from dataclasses import dataclass
from pathlib import Path

CONFIG_PATH = Path.home() / ".config" / "workstyle" / "config.toml"

# Events that can change which windows (or titles) live on a workspace
RELEVANT_EVENTS = {
    "openwindow",
    "closewindow",
    "movewindow",
    "movewindowv2",
    "windowtitle",
    "windowtitlev2",
    "createworkspace",
    "createworkspacev2",
}


@dataclass(frozen=True)
class Config:
    icons: list[tuple[str, str]]  # (lowercase pattern, icon), in file order = precedence
    fallback_icon: str = ""
    deduplicate_icons: bool = True
    separator: str = ": "


def load_config(text: str) -> Config:
    data = tomllib.loads(text)
    other = data.pop("other", {})
    icons = [(pattern.lower(), icon) for pattern, icon in data.items() if isinstance(icon, str)]
    return Config(
        icons=icons,
        fallback_icon=other.get("fallback_icon", ""),
        deduplicate_icons=other.get("deduplicate_icons", True),
        separator=other.get("separator", ": "),
    )


def icon_for(client: dict, config: Config) -> str:
    haystack = " ".join(
        client.get(key) or "" for key in ("class", "initialClass", "title")
    ).lower()
    for pattern, icon in config.icons:
        if pattern in haystack:
            return icon
    return config.fallback_icon


def workspace_names(clients: list[dict], workspace_ids: list[int], config: Config) -> dict[int, str]:
    """Map each regular workspace id to its desired name."""
    icons_by_ws: dict[int, list[str]] = {ws_id: [] for ws_id in workspace_ids if ws_id > 0}
    for client in clients:
        ws_id = client.get("workspace", {}).get("id", -1)
        if ws_id not in icons_by_ws or not client.get("mapped", True):
            continue
        icon = icon_for(client, config)
        if icon and not (config.deduplicate_icons and icon in icons_by_ws[ws_id]):
            icons_by_ws[ws_id].append(icon)

    return {
        ws_id: f"{ws_id}{config.separator}{' '.join(icons)}" if icons else str(ws_id)
        for ws_id, icons in icons_by_ws.items()
    }


def lua_string(value: str) -> str:
    # JSON string escaping (quotes, backslashes, control chars) is valid Lua;
    # ensure_ascii=False keeps icons as raw UTF-8, since Lua lacks \uXXXX.
    return json.dumps(value, ensure_ascii=False)


def rename_dispatch(ws_id: int, name: str) -> str:
    return f"hl.dsp.workspace.rename({{ workspace = {lua_string(str(ws_id))}, name = {lua_string(name)} }})"


# ---------------------------------------------------------------------------
# Side effects: hyprctl and the event socket
# ---------------------------------------------------------------------------

def hyprctl_json(command: str) -> list[dict]:
    return json.loads(subprocess.check_output(["hyprctl", "-j", command], text=True))


def update(config: Config) -> None:
    workspaces = hyprctl_json("workspaces")
    current = {ws["id"]: ws["name"] for ws in workspaces}
    desired = workspace_names(hyprctl_json("clients"), list(current), config)
    for ws_id, name in desired.items():
        if current.get(ws_id) == name:
            continue
        result = subprocess.run(
            ["hyprctl", "dispatch", rename_dispatch(ws_id, name)],
            capture_output=True, text=True,
        )
        if result.stdout.strip() != "ok":
            print(f"rename {ws_id} -> {name!r} failed: {result.stdout.strip()}", file=sys.stderr)


def event_socket_path() -> str:
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not signature:
        sys.exit("HYPRLAND_INSTANCE_SIGNATURE not set; is Hyprland running?")
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    return f"{runtime_dir}/hypr/{signature}/.socket2.sock"


def main() -> None:
    try:
        config = load_config(CONFIG_PATH.read_text())
    except (OSError, tomllib.TOMLDecodeError) as err:
        sys.exit(f"Could not read {CONFIG_PATH}: {err}")

    update(config)
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
        sock.connect(event_socket_path())
        buffer = ""
        while chunk := sock.recv(4096):
            buffer += chunk.decode(errors="replace")
            *lines, buffer = buffer.split("\n")
            # One update per received chunk coalesces bursts (e.g. title spam)
            if any(line.split(">>", 1)[0] in RELEVANT_EVENTS for line in lines):
                update(config)


if __name__ == "__main__":
    main()
