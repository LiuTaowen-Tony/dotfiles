# Dotfiles

These dotfiles separate upstream-managed behavior from fork-specific customization. The repository is expected at `~/dotfiles` and uses `master` for both upstream and fork branches.

## Install

```bash
git clone https://github.com/your-name/dotfiles.git ~/dotfiles
~/dotfiles/core/install.sh
```

The installer:

- adds `source "$HOME/dotfiles/shellrc"` to Bash and Zsh startup files;
- configures the official HTTPS repository as the `upstream` remote;
- deploys Git, Vim, tmux, Readline, EditorConfig, and agent configuration;
- installs coding-agent CLI tools and Zsh plugins;
- installs Maple Mono NF CN and Fira Code on macOS and Linux;
- sets up an SSH key and uploads its public key to GitHub (login may be required);
- on macOS, installs Rectangle, Dia, VS Code, WeChat, and HapiGo through Homebrew Cask, then applies `bin/macos` preferences.

Fish users should add this line to `~/.config/fish/config.fish`:

```fish
source "$HOME/dotfiles/core/config.fish"
```

On macOS, the installer reuses a Homebrew prefix owned and writable by the current user. If none is usable, it installs a private copy at `~/b` with the official Homebrew installer (`--path`, non-interactive, sudo disabled). `~/b/bin` and `~/b/sbin` take precedence over shared Homebrew installations. New GUI applications go to `~/Applications`. The Mac applications are checked in `/Applications`, `~/Applications`, and Homebrew's cask records so existing installs are reused. Current Rectangle and Dia casks require macOS 14+; Dia also requires Apple Silicon. See [Rectangle](https://formulae.brew.sh/cask/rectangle), [Dia](https://formulae.brew.sh/cask/thebrowsercompany-dia), [VS Code](https://formulae.brew.sh/cask/visual-studio-code), [WeChat](https://formulae.brew.sh/cask/wechat), and [HapiGo](https://formulae.brew.sh/cask/hapigo).

`bin/macos` applies user-level keyboard/input, Finder, Dock, and screenshot preferences. Desktop Spaces keep a fixed order, and screenshots are saved to `~/Pictures/Screenshots` (created automatically). It preserves the existing Fn/Globe and Shuangpin choices. It does not change language/region, disk image verification, Spotlight, automatic updates, or other application settings; it does not request sudo or close applications. Some settings require logout/login. Use `--no-mac-apps` to skip the Mac downloads or `--no-macos-settings` to skip these preferences. `--config-only` skips both. You can also install just the applications with `ensure rectangle dia vscode wechat hapigo`.

Removing the old settings from the script does not undo settings applied by an earlier run. This revision does not automatically reset existing preferences.

The official installer restricts custom prefix lengths for binary-package relocation: on Apple Silicon the resolved path must be no longer than `/opt/homebrew`. `/Users/tony/b` fits; longer home-directory names may not. The installer reports incompatible paths without falling back to another account's Homebrew. See [Homebrew custom prefixes](https://docs.brew.sh/Support-Tiers#custom-prefixes).

## Software and GitHub SSH

`core/install.sh` deploys configuration, ensures `git`, `rg`, `fd`, and `jq` are available for coding agents, installs Zsh plugins, and configures GitHub SSH. Use `--no-github-ssh` to skip GitHub setup, or `--config-only` to deploy configuration without downloading software or setting up GitHub SSH. Shell startup loads plugins but never installs them.

Personal tools have launchers at the **end** of PATH: `codex`, `claude`, `gh`, `tmux`, `fzf`, and `nvitop`. Run the normal command with its normal arguments. An existing executable takes precedence; otherwise the launcher installs the tool and immediately runs it. Installation runs automatically; AppMan uses its assume-yes mode and defaults new app installations to `~/Applications` (existing AppMan configuration is retained). Arguments, stdin, and the program's exit status are preserved; installation messages go to stderr.

```bash
claude                     # Install if missing, then launch
nvitop                     # Install if missing, then launch (NVIDIA GPU hosts)
ensure tmux fzf            # Install explicitly without launching
ensure spacevim            # Optional SpaceVim installation
~/dotfiles/core/install.sh --config-only --github-ssh
```

`ensure` skips installed commands. It uses Homebrew only when its prefix belongs to the current user and is writable, otherwise apt/dnf when running as root, otherwise AppMan on Linux. A Homebrew installation owned by another account is skipped. On macOS it bootstraps the private `~/b` installation when needed; AppMan remains Linux-only. It bootstraps AppMan into `${XDG_BIN_HOME:-~/.local/bin}` when needed. It does not invoke sudo automatically. Run `ensure` as root to use system packages, or run `ensure brew` to prepare user-owned Homebrew on macOS. Debian/Fedora's `fd-find` is exposed as `fd` through a local link.

Packages must be available in the selected backend's configured repositories and for the machine's architecture. In particular, do not assume stock apt/dnf or AppMan carries Codex or Claude Code. A missing package or failed download stops the command; no implicit alternate installer fallback is used. You can install from the tool's official distribution yourself; the launcher then uses that executable normally. Homebrew uses the `codex` and `claude-code` casks on macOS.

`nvitop` is a Python package and always uses pip when installation is needed, regardless of the system package manager. It requires Python 3 with venv/pip support, installs into `~/.local/share/dotfiles/venvs/nvitop`, and links the executable into `~/.local/bin`. Existing installations are reused. No uv is required. See the [nvitop installation instructions](https://github.com/XuehaiPan/nvitop#installation).

Full installation also ensures **Maple Mono NF CN** and **Fira Code** on every supported machine (macOS and Linux). macOS uses the `font-maple-mono-nf-cn` and `font-fira-code` Homebrew casks in `~/Library/Fonts`. Linux downloads official release archives (Maple 7.9 NF CN unhinted and Fira Code 6.2), verifies SHA-256, and copies TTF files into `${XDG_DATA_HOME:-~/.local/share}/fonts`, refreshing the font cache when `fc-cache` is available. Missing `unzip` is installed through the usual software backend. Existing fonts are reused; installing fonts does not change the selected editor or terminal font. `--config-only` skips fonts, while `--no-mac-apps` still installs them. To install only these fonts, run `ensure font-maple-mono-nf-cn font-fira-code`.

GitHub login and SSH setup run by default during a full installation. `--github-ssh` can explicitly enable them with `--config-only`. Setup preserves `~/.ssh/id_ed25519` or generates a new key, prompts for a passphrase, and uploads only the public key. Existing GitHub keys are checked before requesting additional OAuth scopes or uploading. When the key is already uploaded and readable, no authorization refresh is requested. Token authentication needs permission to list and add SSH keys. Codex and Claude account login happens when you run each tool.

`setup` and `bootstrap` have been replaced by `core/install.sh` and `ensure`.

References: [AppMan](https://github.com/ivan-hc/AM#what-is-appman), [Claude Code](https://code.claude.com/docs/en/setup), [GitHub CLI](https://github.com/cli/cli#installation), and [GitHub SSH key upload](https://cli.github.com/manual/gh_ssh-key_add).

## Layout

```text
dotfiles/
├── core/       # Install, update, refresh, and deploy; upstream-controlled
├── defaults/   # Default shell, Git, Vim, and SpaceVim configuration
├── bin/        # ensure and ordinary utility scripts
├── fallback/   # Personal-tool launchers, last on PATH
├── agents/     # Default agent rules, settings, and skills
├── custom/     # Fork-specific overlay for defaults, bin, and agents
├── shellrc     # Stable Bash/Zsh entry point
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
│   ├── gitconfig
│   ├── editorconfig
│   ├── inputrc
│   └── tmux.conf
├── bin/
└── agents/
    ├── AGENTS.md
    ├── claude_settings.json
    └── skills/
```

The overlay is limited and additive: only `defaults/`, `agents/`, and `bin/` can be customized, and entries without a custom counterpart continue to use the defaults. A file under `custom/defaults/` replaces the whole same-named default file; it is never merged with that file. This applies to shell, aliases, Fish, Git, Vim, SpaceVim, tmux, Readline, and EditorConfig configuration.

Agent files follow the same overlay rule: a custom `AGENTS.md`, Claude settings file, or same-named skill replaces the default counterpart, while other default and custom skills coexist. The selected `AGENTS.md` is copied to `~/.local/state/dotfiles/generated/AGENTS.md`, then linked into Claude, Codex, and Cursor.

Deployment removes obsolete skill links that point to removed skill directories in this repository; unrelated links and files are left alone.

`custom/bin/` precedes `bin/` on `PATH`, so a same-named custom command wins while all other commands remain available. An executable `custom/bin/deploy.sh` runs after the default deployment.

Run `cnmirror on` to use the Tsinghua pip and conda mirrors in the current shell, or `cnmirror off` to return to upstream. China-hosted `autodl` machines enable the mirrors automatically.

## Updating

Each interactive shell displays the previous refresh result, clears that cache, and starts one background refresh. Refresh always runs update before deploy.

```bash
~/dotfiles/core/update.sh
~/dotfiles/core/deploy.sh
```

The updater fetches and merges `upstream/master`. It skips merging on a dirty worktree or a branch other than `master`, aborts merge conflicts automatically, and never pushes to the fork remote. OS file locks (`flock` on Linux, `lockf` on macOS/BSD) prevent overlapping updates and refreshes and release automatically when the owning processes exit. Legacy lock directories are ignored.

## Commands

Ordinary utilities live in `bin/` and are available through the shell configuration, including `ensure`, `macos`, `pyrun`, and `trash`. Bash and Zsh expose `myip` for the public IP; Fish aliases belong in `common_config.fish` because Bash alias syntax is not compatible with Fish.

tmux enables mouse support by default. The shell configuration starts Codex with `--no-alt-screen` and sets `CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1` for Claude Code to preserve terminal scrollback. Cursor Agent already uses inline rendering by default; no extra flag is needed. This refers to terminal rendering, not the Cursor editor window.

Run the isolated regression suite with:

```bash
./tests/test_dotfiles.sh
```
