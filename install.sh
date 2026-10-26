#!/usr/bin/env bash

# Keep the entry point in a function so a partial curl download cannot execute
# installation commands before Bash has parsed the complete function.
main() {
  set -euo pipefail
  local destination="$HOME/dotfiles"
  local repository='https://github.com/LiuTaowen-Tony/dotfiles.git'

  if ! git --version >/dev/null 2>&1; then
    echo 'Git is required. On macOS, install Command Line Tools with xcode-select --install first.' >&2
    return 1
  fi
  if [[ ! -e "$destination" && ! -L "$destination" ]]; then
    git clone --depth 1 --branch master "$repository" "$destination"
  elif [[ ! -e "$destination/.git" || ! -f "$destination/core/install.sh" ]] \
      || ! git -C "$destination" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Refusing to overwrite $destination: it is not a dotfiles checkout." >&2
    return 1
  elif [[ -n "$(git -C "$destination" status --porcelain)" \
      || "$(git -C "$destination" branch --show-current)" != master ]]; then
    echo 'Keeping the existing checkout: local changes or a non-master branch; skipping update.' >&2
  else
    git -C "$destination" pull --ff-only origin master
  fi

  # The pipe contains this script, not answers to ssh-keygen/gh login prompts.
  if { : </dev/tty; } 2>/dev/null; then
    exec bash "$destination/core/install.sh" "$@" </dev/tty
  else
    exec bash "$destination/core/install.sh" "$@" </dev/null
  fi
}

main "$@"
