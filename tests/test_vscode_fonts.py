import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("vscode_fonts", Path(__file__).resolve().parents[1] / "core/vscode-fonts.py")
fonts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fonts)


class FontSettingsTests(unittest.TestCase):
    def test_jsonc_preserves_comments_strings_and_nested_overrides(self):
        original = '''{
  // keep this comment and the language override
  "editor.fontFamily": "monospace",
  "[python]": {"editor.fontFamily": "Other Font",},
  "example": "https://example.test/*literal*/\\\"quoted\\\"",
  "editor.fontWeight": "600" // keep this trailing comment
}
'''
        updated = fonts.set_fonts(original)
        for line in original.splitlines():
            if line not in ("{", "}") and not line.startswith('  "editor.fontFamily"'):
                self.assertIn(line.replace('"600" //', '"600", //'), updated)
        for key, value in fonts.FONTS.items():
            self.assertIn(f'{json.dumps(key)}: {json.dumps(value)}', updated)
        self.assertEqual(fonts.set_fonts(updated), updated)

    def test_replaces_values_without_changing_other_json(self):
        original = {"editor.fontFamily": None, "terminal.integrated.fontFamily": ["old"], "other": {"a": [1, 2]}}
        result = json.loads(fonts.set_fonts(json.dumps(original)))
        self.assertEqual(result, {**original, **fonts.FONTS})
        self.assertEqual(json.loads(fonts.set_fonts("{}")), fonts.FONTS)

    def test_platform_paths_backup_and_repeat_runs(self):
        for platform in ("darwin", "linux"):
            with self.subTest(platform=platform), tempfile.TemporaryDirectory() as directory:
                home = Path(directory)
                config = home / "config with spaces"
                user_dir = home / "Library/Application Support/Code/User" if platform == "darwin" else config / "Code/User"
                settings = user_dir / "settings.json"
                original = '{\n// preserve me\n"window.zoomLevel": 1,\n}\n'
                user_dir.mkdir(parents=True)
                settings.write_text(original)
                with patch.dict(os.environ, {"HOME": directory, "XDG_CONFIG_HOME": str(config)}), patch.object(fonts.sys, "platform", platform), contextlib.redirect_stdout(io.StringIO()):
                    fonts.main()
                    first = settings.read_text()
                    fonts.main()
                self.assertEqual(settings.read_text(), first)
                self.assertIn('// preserve me', first)
                self.assertEqual(settings.with_name("settings.json.dotfiles-backup").read_text(), original)

    def test_malformed_settings_are_not_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            settings = Path(directory) / "Code/User/settings.json"
            settings.parent.mkdir(parents=True)
            original = '{"editor.fontFamily": "unfinished}'
            settings.write_text(original)
            with patch.dict(os.environ, {"XDG_CONFIG_HOME": directory}), patch.object(fonts.sys, "platform", "linux"):
                with self.assertRaises(json.JSONDecodeError):
                    fonts.main()
            self.assertEqual(settings.read_text(), original)
            self.assertFalse(settings.with_name("settings.json.dotfiles-backup").exists())


if __name__ == "__main__":
    unittest.main()
