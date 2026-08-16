# Dotfiles

These dotfiles separate upstream-managed behavior from fork-specific customization. The repository is expected at `~/dotfiles` and uses `master` for both upstream and fork branches.

## Install

```bash
git clone https://github.com/your-name/dotfiles.git ~/dotfiles
~/dotfiles/core/install.sh
```

The installer:

- adds `source "$HOME/dotfiles/defaults/shellrc"` to Bash and Zsh startup files;
- configures the official HTTPS repository as the `upstream` remote;
- deploys Git, Vim, and agent configuration.

Fish users should add this line to `~/.config/fish/config.fish`:

```fish
source "$HOME/dotfiles/defaults/common_config.fish"
```

## Layout

```text
dotfiles/
├── core/       # Install, update, refresh, and deploy; upstream-controlled
├── defaults/   # Default shell, Git, Vim, and SpaceVim configuration
├── bin/        # Ordinary commands and utility scripts
├── agents/     # Default agent rules, settings, and skills
├── custom/     # Fork-specific overlay for defaults, bin, and agents
└── README.md
```

There is no `custom/core/`. Fork configuration cannot replace update, locking, installation, or deployment behavior.

## Customization

Keep personal changes in `custom/` rather than editing upstream defaults:

```text
custom/
├── defaults/
│   ├── shellrc
│   ├── aliases
│   ├── common_config.fish
│   └── gitconfig
├── bin/
└── agents/
    ├── AGENTS.md
    ├── claude_settings.json
    └── skills/
```

Shell, alias, Fish, and Git fragments load after their default equivalents. `custom/bin/` precedes `bin/` on `PATH`, so a custom command can replace an ordinary command with the same name. An executable `custom/bin/deploy.sh` runs after the default deployment.

Default and custom agent instructions are regenerated into `~/.local/state/dotfiles/generated/AGENTS.md`, then linked into Claude, Codex, and Cursor. A custom skill replaces the default skill with the same directory name. A custom Claude settings file replaces the default settings file.

The encrypted environment used by the `=` helper belongs at `custom/defaults/env.gpg`; it is not part of the upstream defaults.

## Updating

Each interactive shell displays the previous refresh result, clears that cache, and starts one background refresh. Refresh always runs update before deploy.

```bash
~/dotfiles/core/update.sh
~/dotfiles/core/deploy.sh
```

The updater fetches and merges `upstream/master`. It skips merging on a dirty worktree or a branch other than `master`, aborts merge conflicts automatically, and never pushes to the fork remote. Atomic directory locks prevent overlapping updates and refreshes.

## Commands

Ordinary utilities live in `bin/` and are available through the shell configuration, including `bootstrap`, `git_acm`, `macos`, `pyrun`, and `trash`.

Run the isolated regression suite with:

```bash
./tests/test_dotfiles.sh
```
