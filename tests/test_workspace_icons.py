"""Tests for hypr/scripts/workspace-icons.py.

Run with: python3 -m unittest discover tests
"""

import importlib.util
import unittest
from pathlib import Path

_SCRIPT = Path(__file__).resolve().parent.parent / "hypr" / "scripts" / "workspace-icons.py"
_spec = importlib.util.spec_from_file_location("workspace_icons", _SCRIPT)
wi = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(wi)

CONFIG_TEXT = """
"github" = "G"
"firefox" = "F"
"alacritty" = "A"

[other]
fallback_icon = "?"
deduplicate_icons = true
separator = ": "
"""


def client(ws_id: int, cls: str, title: str = "", mapped: bool = True) -> dict:
    return {"workspace": {"id": ws_id}, "class": cls, "initialClass": cls, "title": title, "mapped": mapped}


class LoadConfigTest(unittest.TestCase):
    def test_keeps_file_order_and_other_section(self):
        config = wi.load_config(CONFIG_TEXT)
        self.assertEqual(config.icons, [("github", "G"), ("firefox", "F"), ("alacritty", "A")])
        self.assertEqual(config.fallback_icon, "?")
        self.assertEqual(config.separator, ": ")

    def test_defaults_without_other_section(self):
        config = wi.load_config('"Foo" = "x"')
        self.assertEqual(config.icons, [("foo", "x")])
        self.assertTrue(config.deduplicate_icons)
        self.assertEqual(config.fallback_icon, "")


class IconForTest(unittest.TestCase):
    config = wi.load_config(CONFIG_TEXT)

    def test_earlier_pattern_wins(self):
        self.assertEqual(wi.icon_for(client(1, "firefox", "GitHub - repo"), self.config), "G")

    def test_case_insensitive_class_match(self):
        self.assertEqual(wi.icon_for(client(1, "Alacritty"), self.config), "A")

    def test_fallback_and_missing_fields(self):
        self.assertEqual(wi.icon_for({"class": None}, self.config), "?")


class WorkspaceNamesTest(unittest.TestCase):
    config = wi.load_config(CONFIG_TEXT)

    def test_icons_deduplicated_in_order(self):
        clients = [client(1, "alacritty"), client(1, "firefox"), client(1, "alacritty")]
        self.assertEqual(wi.workspace_names(clients, [1], self.config), {1: "1: A F"})

    def test_no_deduplication(self):
        config = wi.load_config(CONFIG_TEXT.replace("deduplicate_icons = true", "deduplicate_icons = false"))
        clients = [client(1, "alacritty"), client(1, "alacritty")]
        self.assertEqual(wi.workspace_names(clients, [1], config), {1: "1: A A"})

    def test_empty_workspace_is_plain_id(self):
        self.assertEqual(wi.workspace_names([], [2], self.config), {2: "2"})

    def test_skips_special_workspaces_and_unmapped_windows(self):
        clients = [client(-98, "firefox"), client(3, "firefox", mapped=False)]
        self.assertEqual(wi.workspace_names(clients, [-98, 3], self.config), {3: "3"})


class RenameDispatchTest(unittest.TestCase):
    def test_escapes_quotes_and_keeps_utf8(self):
        self.assertEqual(
            wi.rename_dispatch(1, '1: "x" 󰇮'),
            'hl.dsp.workspace.rename({ workspace = "1", name = "1: \\"x\\" 󰇮" })',
        )


if __name__ == "__main__":
    unittest.main()
