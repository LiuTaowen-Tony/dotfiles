# Custom overlay

Keep fork-specific configuration here so upstream changes remain isolated. This is a limited, additive overlay: missing custom entries continue to use their defaults, while same-named entries take priority.

- `defaults/`: optional shell, alias, Git, Vim, SpaceVim, and encrypted environment overrides. A same-named file replaces the entire default file.
- `bin/`: commands placed before the default `bin/` on `PATH`; an executable `deploy.sh` runs after the default deployment.
- `agents/`: optional `AGENTS.md`, `claude_settings.json`, and skills. Same-named files and skills replace their default counterparts; other skills coexist.

There is intentionally no `custom/core/`: installation, updating, locking, and deployment always use upstream-controlled code.
