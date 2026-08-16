#!/usr/bin/env bash

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK_DIR="$ROOT/tmp/refresh.lock"

mkdir -p "$ROOT/tmp"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  exit 0
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

update_status=0
"$ROOT/core/update.sh" || update_status=$?
"$ROOT/core/deploy.sh"
deploy_status=$?

[[ $deploy_status -eq 0 ]] || exit "$deploy_status"
exit "$update_status"
