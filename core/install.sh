#!/usr/bin/env bash

set -euo pipefail

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
echo 'Dotfiles installed.'
