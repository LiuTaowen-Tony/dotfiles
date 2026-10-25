#!/usr/bin/env bash

set -euo pipefail

config_only=0
github_ssh=auto
mac_apps=1
macos_settings=1
for option in "$@"; do
  case "$option" in
    --config-only) config_only=1 ;;
    --github-ssh) github_ssh=1 ;;
    --no-github-ssh) github_ssh=0 ;;
    --no-mac-apps) mac_apps=0 ;;
    --no-macos-settings) macos_settings=0 ;;
    -h|--help)
      echo 'usage: install.sh [--config-only] [--github-ssh|--no-github-ssh] [--no-mac-apps] [--no-macos-settings]'
      exit 0
      ;;
    *) echo "Unknown option: $option" >&2; exit 1 ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_URL="${DOTFILES_UPSTREAM_URL:-https://github.com/LiuTaowen-Tony/dotfiles.git}"
EXPECTED_ROOT="$(cd "$HOME" && pwd)/dotfiles"

if [[ "$ROOT" != "$EXPECTED_ROOT" ]]; then
  printf 'Expected the repository at %s, found %s.\n' "$EXPECTED_ROOT" "$ROOT" >&2
  exit 1
fi

ensure_shell_source() {
  local rc_file="$1"
  local source_line='source "$HOME/dotfiles/shellrc"'
  local cleaned_file

  touch "$rc_file"
  cleaned_file="$(mktemp "${rc_file}.XXXXXX")"
  awk '$0 != "source $HOME/dotfiles/defaults/shellrc" \
    && $0 != "source \"$HOME/dotfiles/defaults/shellrc\"" \
    && $0 != "source $HOME/dotfiles/core/shellrc" \
    && $0 != "source \"$HOME/dotfiles/core/shellrc\""' \
    "$rc_file" > "$cleaned_file"
  if ! cmp -s "$cleaned_file" "$rc_file"; then
    cp "$cleaned_file" "$rc_file"
  fi
  rm -f "$cleaned_file"
  grep -Fqx "$source_line" "$rc_file" || printf '\n%s\n' "$source_line" >> "$rc_file"
}

ensure_shell_source "$HOME/.bashrc"
ensure_shell_source "${ZDOTDIR:-$HOME}/.zshrc"

if git -C "$ROOT" remote get-url upstream >/dev/null 2>&1; then
  git -C "$ROOT" remote set-url upstream "$UPSTREAM_URL"
else
  git -C "$ROOT" remote add upstream "$UPSTREAM_URL"
fi

"$ROOT/core/deploy.sh"
if [[ "$config_only" == 0 ]]; then
  if [[ "$(uname -s)" == Darwin ]]; then
    "$ROOT/bin/ensure" brew
  fi
  "$ROOT/bin/ensure" git rg fd jq
  "$ROOT/bin/ensure" font-maple-mono-nf-cn font-fira-code
  mkdir -p "$HOME/.zsh"
  for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if [[ ! -d "$HOME/.zsh/$plugin" ]]; then
      git clone --depth 1 "https://github.com/zsh-users/$plugin.git" "$HOME/.zsh/$plugin"
    fi
  done
  if [[ "$mac_apps" == 1 && "$(uname -s)" == Darwin ]]; then
    "$ROOT/bin/ensure" rectangle dia vscode wechat hapigo
  fi
fi
if [[ "$github_ssh" == 1 || ( "$github_ssh" == auto && "$config_only" == 0 ) ]]; then
  bash "$ROOT/core/github-ssh.sh"
fi
if [[ "$config_only" == 0 && "$macos_settings" == 1 && "$(uname -s)" == Darwin ]]; then
  bash "$ROOT/bin/macos"
fi
echo 'Dotfiles installed.'
