#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-entry.XXXXXX")"
trap 'rm -rf "$fixture"' EXIT
export ENTRY_REAL_GIT="$(command -v git)"
export ENTRY_REMOTE="$fixture/remote"
mkdir -p "$fixture/home" "$fixture/mock" "$ENTRY_REMOTE/core"
git -C "$ENTRY_REMOTE" init -q -b master
git -C "$ENTRY_REMOTE" config user.name 'Dotfiles Test'
git -C "$ENTRY_REMOTE" config user.email 'dotfiles@example.test'
cat > "$ENTRY_REMOTE/core/install.sh" <<'SCRIPT'
#!/usr/bin/env bash
printf '<%s>\n' "$@" > "$HOME/arguments"
# A piped installer must not pass its script body through as application input.
if [[ ! -t 0 ]] && IFS= read -r unexpected; then exit 99; fi
echo first > "$HOME/installed"
exit "${ENTRY_INSTALL_EXIT:-0}"
SCRIPT
git -C "$ENTRY_REMOTE" add core/install.sh
git -C "$ENTRY_REMOTE" commit -qm initial
cat > "$fixture/mock/git" <<'SCRIPT'
#!/usr/bin/env bash
if [[ "$1" == clone ]]; then
  exec "$ENTRY_REAL_GIT" clone --branch master "$ENTRY_REMOTE" "${@: -1}"
fi
exec "$ENTRY_REAL_GIT" "$@"
SCRIPT
chmod +x "$fixture/mock/git"
run_entry() {
  cat "$ROOT/install.sh" | HOME="$fixture/home" PATH="$fixture/mock:$PATH" bash -s -- "$@"
}
run_entry --config-only 'two words' >/dev/null 2>&1
[[ "$(cat "$fixture/home/arguments")" == $'<--config-only>\n<two words>' ]]
[[ "$(cat "$fixture/home/installed")" == first ]]

# Re-running obtains a fast-forward update, while dirty work stays untouched.
sed 's/echo first/echo second/' "$ENTRY_REMOTE/core/install.sh" > "$fixture/next"
cp "$fixture/next" "$ENTRY_REMOTE/core/install.sh"
git -C "$ENTRY_REMOTE" commit -qam second
run_entry --config-only >/dev/null 2>&1
[[ "$(cat "$fixture/home/installed")" == second ]]
echo personal > "$fixture/home/dotfiles/personal.txt"
sed 's/echo second/echo third/' "$ENTRY_REMOTE/core/install.sh" > "$fixture/next"
cp "$fixture/next" "$ENTRY_REMOTE/core/install.sh"
git -C "$ENTRY_REMOTE" commit -qam third
run_entry --config-only >/dev/null 2>&1
[[ "$(cat "$fixture/home/installed")" == second ]]
[[ "$(cat "$fixture/home/dotfiles/personal.txt")" == personal ]]
rm "$fixture/home/dotfiles/personal.txt"
git -C "$fixture/home/dotfiles" checkout -qb personal
run_entry --config-only >/dev/null 2>&1
[[ "$(cat "$fixture/home/installed")" == second ]]
[[ "$(git -C "$fixture/home/dotfiles" branch --show-current)" == personal ]]

entry_exit=0
ENTRY_INSTALL_EXIT=23 run_entry --config-only >/dev/null 2>&1 || entry_exit=$?
[[ "$entry_exit" == 23 ]]

# Never replace an existing non-repository directory.
mv "$fixture/home/dotfiles" "$fixture/checkout"
mkdir "$fixture/home/dotfiles"
echo keep > "$fixture/home/dotfiles/keep"
if run_entry --config-only >/dev/null 2>&1; then
  echo 'Unexpected success for a non-repository destination.' >&2
  exit 1
fi
[[ "$(cat "$fixture/home/dotfiles/keep")" == keep ]]

# A failed/truncated script download must not start cloning.
mkdir "$fixture/truncated-home"
sed '/^}/,$d' "$ROOT/install.sh" > "$fixture/truncated.sh"
if HOME="$fixture/truncated-home" PATH="$fixture/mock:$PATH" bash "$fixture/truncated.sh" >/dev/null 2>&1; then
  echo 'Unexpected success for a truncated entry point.' >&2
  exit 1
fi
[[ ! -e "$fixture/truncated-home/dotfiles" ]]
echo 'Remote install checks passed: clone, updates, local changes, arguments, stdin, and failures.'
