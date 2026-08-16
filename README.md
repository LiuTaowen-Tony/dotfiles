# Dotfiles

These dotfiles separate upstream-managed behavior from fork-specific customization. The repository is expected at `~/dotfiles` and uses `master` for both upstream and fork branches.

## Install

```bash
git clone https://github.com/your-name/dotfiles.git ~/dotfiles
~/dotfiles/core/install.sh
```

The installer:

- adds `source "$HOME/dotfiles/core/shellrc"` to Bash and Zsh startup files;
- configures the official HTTPS repository as the `upstream` remote;
- deploys Git, Vim, and agent configuration.

Fish users should add this line to `~/.config/fish/config.fish`:

```fish
source "$HOME/dotfiles/core/config.fish"
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

The overlay is limited and additive: only `defaults/`, `agents/`, and `bin/` can be customized, and entries without a custom counterpart continue to use the defaults. A file under `custom/defaults/` replaces the whole same-named default file; it is never merged with that file. This applies to shell, aliases, Fish, Git, Vim, and SpaceVim configuration.

Agent files follow the same overlay rule: a custom `AGENTS.md`, Claude settings file, or same-named skill replaces the default counterpart, while other default and custom skills coexist. The selected `AGENTS.md` is copied to `~/.local/state/dotfiles/generated/AGENTS.md`, then linked into Claude, Codex, and Cursor.

`custom/bin/` precedes `bin/` on `PATH`, so a same-named custom command wins while all other commands remain available. An executable `custom/bin/deploy.sh` runs after the default deployment.

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
