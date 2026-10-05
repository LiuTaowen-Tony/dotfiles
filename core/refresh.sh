#!/usr/bin/env bash

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/core/lock.sh"

mkdir -p "$ROOT/tmp"
acquire_lock "$ROOT/tmp/refresh.lockfile"
lock_status=$?
if [[ $lock_status -eq 75 ]]; then
  exit 0
fi
[[ $lock_status -eq 0 ]] || exit "$lock_status"
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

update_status=0
"$ROOT/core/update.sh" || update_status=$?
"$ROOT/core/deploy.sh"
deploy_status=$?

[[ $deploy_status -eq 0 ]] || exit "$deploy_status"
exit "$update_status"
