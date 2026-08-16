# Custom overlay

Keep fork-specific configuration here so upstream changes remain isolated.

- `defaults/`: optional shell, alias, Git, Vim, SpaceVim, and encrypted environment overrides.
- `bin/`: commands placed before the default `bin/` on `PATH`; an executable `deploy.sh` runs after the default deployment.
- `agents/`: optional `AGENTS.md`, `claude_settings.json`, and skills. A custom skill replaces a default skill with the same directory name.

There is intentionally no `custom/core/`: installation, updating, locking, and deployment always use upstream-controlled code.
