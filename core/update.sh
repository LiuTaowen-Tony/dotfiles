#!/usr/bin/env bash

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_URL="${DOTFILES_UPSTREAM_URL:-https://github.com/LiuTaowen-Tony/dotfiles.git}"
LOCK_DIR="$ROOT/tmp/update.lock"

mkdir -p "$ROOT/tmp"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  echo 'Dotfiles update already running; skipping.'
  exit 0
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

cd "$ROOT" || exit 1

if git remote get-url upstream >/dev/null 2>&1; then
  git remote set-url upstream "$UPSTREAM_URL"
else
  git remote add upstream "$UPSTREAM_URL"
fi

branch="$(git branch --show-current)"
if [[ "$branch" != 'master' ]]; then
  printf 'Dotfiles update skipped: branch is %s, expected master.\n' "${branch:-detached HEAD}"
  exit 0
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo 'Dotfiles update skipped: working tree is not clean.'
  exit 0
fi

if ! git fetch --quiet upstream master; then
  echo 'Dotfiles update failed while fetching upstream.' >&2
  exit 1
fi

before="$(git rev-parse HEAD)"
if ! git merge --quiet --no-edit upstream/master; then
  git merge --abort >/dev/null 2>&1 || true
  echo 'Dotfiles update found a merge conflict; merge was aborted.' >&2
  exit 1
fi

after="$(git rev-parse HEAD)"
if [[ "$before" != "$after" ]]; then
  echo 'Dotfiles updated from upstream.'
  git status --short
fi
