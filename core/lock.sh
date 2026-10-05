#!/usr/bin/env bash

acquire_lock() {
  local lock_file="$1"

  exec 9>"$lock_file" || return 1
  if command -v flock >/dev/null 2>&1; then
    flock -n -E 75 9
  elif command -v lockf >/dev/null 2>&1; then
    lockf -s -t 0 9
  else
    printf 'Dotfiles locking requires flock (Linux) or lockf (macOS/BSD).\n' >&2
    return 1
  fi
}
