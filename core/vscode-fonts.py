#!/usr/bin/env python3
"""Select installed fonts in VS Code without replacing unrelated JSONC settings."""
import json
import os
from pathlib import Path
import re
import shutil
import sys

FONTS = {
    "editor.fontFamily": "'Maple Mono NF CN', 'Fira Code', monospace",
    "terminal.integrated.fontFamily": "'Maple Mono NF CN', monospace",
}


def set_fonts(text):
    # Token offsets let us preserve comments/formatting and avoid matching keys
    # inside strings or language-specific settings. Validate before any writes.
    tokens = [
        match for match in re.finditer(r'"(?:\\.|[^"\\])*"|//[^\r\n]*|/\*[\s\S]*?\*/|\s+|.', text)
        if not match[0].isspace() and not match[0].startswith(("//", "/*"))
    ]
    clean = "".join(
        token[0] for i, token in enumerate(tokens)
        if not (token[0] == "," and i + 1 < len(tokens) and tokens[i + 1][0] in ("}", "]"))
    )
    if not isinstance(json.loads(clean), dict):
        raise ValueError("VS Code settings must be a JSON object")
    edits, seen, depth = [], set(), 0
    for i, token in enumerate(tokens):
        value = token[0]
        if value in ("{", "["):
            depth += 1
        elif value in ("}", "]"):
            depth -= 1
        elif depth == 1 and value.startswith('"') and tokens[i + 1][0] == ":":
            key = json.loads(value)
            if key not in FONTS:
                continue
            seen.add(key)
            start, end, nested = i + 2, i + 2, 0
            while end < len(tokens):
                part = tokens[end][0]
                if nested == 0 and part in (",", "}"):
                    break
                if part in ("{", "["):
                    nested += 1
                elif part in ("}", "]"):
                    nested -= 1
                end += 1
            edits.append((tokens[start].start(), tokens[end - 1].end(), json.dumps(FONTS[key])))
    missing = {key: value for key, value in FONTS.items() if key not in seen}
    if missing:
        if len(tokens) > 2 and tokens[-2][0] != ",":
            edits.append((tokens[-2].end(), tokens[-2].end(), ","))
        addition = "\n" + ",\n".join(f"  {json.dumps(k)}: {json.dumps(v)}" for k, v in missing.items()) + "\n"
        edits.append((tokens[-1].start(), tokens[-1].start(), addition))
    for start, end, replacement in sorted(edits, reverse=True):
        text = text[:start] + replacement + text[end:]
    return text


def main():
    if sys.platform == "darwin":
        user_dir = Path.home() / "Library/Application Support/Code/User"
    elif sys.platform.startswith("linux"):
        user_dir = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "Code/User"
    else:
        raise SystemExit("VS Code font setup supports macOS and Linux.")
    settings = user_dir / "settings.json"
    original = settings.read_text(encoding="utf-8-sig") if settings.exists() else "{}\n"
    updated = set_fonts(original)
    if updated == original:
        return
    user_dir.mkdir(parents=True, exist_ok=True)
    backup = settings.with_name("settings.json.dotfiles-backup")
    if settings.exists() and not backup.exists():
        shutil.copy2(settings, backup)
    settings.write_text(updated, encoding="utf-8")
    print(f"VS Code editor and terminal fonts configured: {settings}")


if __name__ == "__main__":
    main()
