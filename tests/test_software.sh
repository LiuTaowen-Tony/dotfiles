#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-software.XXXXXX")"
trap 'rm -rf "$fixture"' EXIT
fixture="$(cd "$fixture" && pwd)"
mkdir -p "$fixture/home" "$fixture/mock" "$fixture/real"
for cmd in bash dirname mkdir ln cat chmod cp mktemp rm sed find; do
  ln -s "$(command -v "$cmd")" "$fixture/mock/$cmd"
done
cat > "$fixture/mock/id" <<'SCRIPT'
#!/usr/bin/env bash
printf '%s\n' "${TEST_UID:-1000}"
SCRIPT
cat > "$fixture/mock/stat" <<'SCRIPT'
#!/usr/bin/env bash
if [[ "${*: -1}" == "$HOME/b" ]]; then echo 1000; else echo "${TEST_BREW_OWNER:-1000}"; fi
SCRIPT
chmod +x "$fixture/mock/stat"
cat > "$fixture/mock/uname" <<'SCRIPT'
#!/usr/bin/env bash
echo "${TEST_OS:-Linux}"
SCRIPT
cat > "$fixture/manager" <<'SCRIPT'
#!/usr/bin/env bash
set -eu
if [[ "${0##*/} $1" == "brew --prefix" ]]; then
  if [[ "$0" == "$HOME/b/bin/brew" ]]; then echo "$HOME/b"; else echo "$TEST_BREW_PREFIX"; fi
  exit 0
fi
printf '%s\n' "${0##*/} $*" >> "$TEST_LOG"
echo 'installation log'
# Installers must not consume the launched program's piped input.
cat >/dev/null
[[ "${TEST_FAIL:-0}" == 0 ]] || exit 42
[[ "${1:-}" != update ]] || exit 0
if [[ "${0##*/}" == brew && "${*: -1}" == font-fira-code ]]; then
  mkdir -p "$HOME/Library/Fonts"
  echo font > "$HOME/Library/Fonts/FiraCode-Regular.ttf"
  exit 0
fi
if [[ "${0##*/}" == python ]]; then TEST_REAL="$(dirname "$0")"; fi
case "${*: -1}" in
  ripgrep) command_name=rg ;;
  fd-find) command_name=fdfind ;;
  *) command_name="${*: -1}" ;;
esac
cat > "$TEST_REAL/$command_name" <<'PROGRAM'
#!/usr/bin/env bash
printf 'arg=<%s>\n' "$@"
cat
exit 23
PROGRAM
chmod +x "$TEST_REAL/$command_name"
SCRIPT
chmod +x "$fixture/mock/id" "$fixture/mock/uname" "$fixture/manager"
export TEST_BREW_PREFIX="$fixture/real"
export TEST_REAL="$fixture/real" TEST_LOG="$fixture/log"
run() {
  HOME="$fixture/home" XDG_BIN_HOME="$fixture/home/.local/bin" \
    PATH="$fixture/mock:$fixture/real:$ROOT/fallback" "$@"
}
assert() { [[ "$1" == "$2" ]] || { echo "FAIL: $3 ($1 != $2)" >&2; exit 1; }; }

# Install once, preserve stdin/arguments/status, and never mix install logs into stdout.
ln -s "$fixture/manager" "$fixture/mock/brew"
set +e
result="$(printf 'input\n' | run "$ROOT/fallback/fzf" 'two words' '' '*' 2>"$fixture/stderr")"
status=$?
set -e
assert "$status" 23 'program exit status'
assert "$result" $'arg=<two words>\narg=<>\narg=<*>\ninput' 'argument and stdin forwarding'
assert "$(cat "$TEST_LOG")" 'brew install fzf' 'brew selection'
grep -q 'installation log' "$fixture/stderr"
# Calling even a cached launcher must find the newly installed binary, not reinstall.
set +e
run "$ROOT/fallback/fzf" </dev/null >/dev/null
status=$?
set -e
assert "$status" 23 'cached launcher execution'
assert "$(wc -l < "$TEST_LOG" | tr -d ' ')" 1 'no duplicate installation'

# Python tools bypass brew, install into a dedicated venv, and launch immediately.
export TEST_MANAGER="$fixture/manager"
cat > "$fixture/mock/python3" <<'SCRIPT'
#!/usr/bin/env bash
set -eu
[[ "$1 $2" == '-m venv' ]]
echo venv >> "$TEST_LOG"
mkdir -p "$3/bin"
cp "$TEST_MANAGER" "$3/bin/python"
SCRIPT
chmod +x "$fixture/mock/python3"
: > "$TEST_LOG"
set +e
result="$(printf 'gpu-input\n' | run "$ROOT/fallback/nvitop" '--once' 2>"$fixture/stderr")"
status=$?
set -e
assert "$status" 23 'pip-installed program exit status'
assert "$result" $'arg=<--once>\ngpu-input' 'pip-installed program arguments and stdin'
assert "$(cat "$TEST_LOG")" $'venv\npython -m pip install --upgrade nvitop' 'nvitop uses isolated pip even with brew'
[[ -L "$fixture/home/.local/bin/nvitop" ]]
: > "$TEST_LOG"
run "$ROOT/bin/ensure" nvitop
[[ ! -s "$TEST_LOG" ]] || { echo 'nvitop was reinstalled' >&2; exit 1; }

# Fonts use macOS casks or checksum-verified Linux archives. A failed download
# must leave installed fonts alone, and repeated runs must not download again.
: > "$TEST_LOG"
TEST_OS=Darwin run "$ROOT/bin/ensure" font-fira-code </dev/null 2>/dev/null
assert "$(cat "$TEST_LOG")" 'brew install --cask font-fira-code' 'Mac font uses Homebrew cask'
: > "$TEST_LOG"
TEST_OS=Darwin run "$ROOT/bin/ensure" font-fira-code </dev/null
[[ ! -s "$TEST_LOG" ]]
cat > "$fixture/mock/curl" <<'SCRIPT'
#!/usr/bin/env bash
[[ "${TEST_DOWNLOAD_FAIL:-0}" == 0 ]] || exit 6
echo download >> "$TEST_LOG"
case "$*" in *MapleMono*) family=MapleMono-NF-CN ;; *) family=FiraCode ;; esac
while [[ "$1" != -o ]]; do shift; done
echo "$family" > "$2"
SCRIPT
cat > "$fixture/mock/sha256sum" <<'SCRIPT'
#!/usr/bin/env bash
if [[ "${TEST_BAD_HASH:-0}" == 1 ]]; then echo 'invalid hash'; exit 0; fi
if [[ "$(cat "$1")" == MapleMono-NF-CN ]]; then
  echo 'ab88522932cf4015dffeaef6dedc59a22a5fefecdcc6e583d9fcd997da5b7cac archive'
else
  echo '0949915ba8eb24d89fd93d10a7ff623f42830d7c5ffc3ecbf960e4ecad3e3e79 archive'
fi
SCRIPT
cat > "$fixture/mock/unzip" <<'SCRIPT'
#!/usr/bin/env bash
echo unpack >> "$TEST_LOG"
family="$(cat "$2")"
mkdir -p "$4/ttf"
echo font > "$4/ttf/$family-Regular.ttf"
SCRIPT
cat > "$fixture/mock/fc-cache" <<'SCRIPT'
#!/usr/bin/env bash
echo cache >> "$TEST_LOG"
SCRIPT
chmod +x "$fixture/mock/curl" "$fixture/mock/sha256sum" "$fixture/mock/unzip" "$fixture/mock/fc-cache"
: > "$TEST_LOG"
set +e
TEST_BAD_HASH=1 XDG_DATA_HOME="$fixture/font data" run "$ROOT/bin/ensure" font-maple-mono-nf-cn 2>/dev/null
font_exit=$?
set -e
[[ "$font_exit" != 0 && ! -d "$fixture/font data/fonts" ]]
assert "$(cat "$TEST_LOG")" download 'bad checksums stop before archive extraction'
: > "$TEST_LOG"
XDG_DATA_HOME="$fixture/font data" run "$ROOT/bin/ensure" font-maple-mono-nf-cn font-fira-code 2>/dev/null
[[ -s "$fixture/font data/fonts/font-maple-mono-nf-cn/MapleMono-NF-CN-Regular.ttf" ]]
[[ -s "$fixture/font data/fonts/font-fira-code/FiraCode-Regular.ttf" ]]
assert "$(cat "$TEST_LOG")" $'download\nunpack\ncache\ndownload\nunpack\ncache' 'Linux fonts use verified archives and refresh the cache'
: > "$TEST_LOG"
XDG_DATA_HOME="$fixture/font data" run "$ROOT/bin/ensure" font-maple-mono-nf-cn font-fira-code
[[ ! -s "$TEST_LOG" ]]
rm "$fixture/mock/curl" "$fixture/mock/sha256sum" "$fixture/mock/unzip" "$fixture/mock/fc-cache"

# Root apt handles package/command name differences without accepting the launcher.
rm "$fixture/mock/brew"
ln -s "$fixture/manager" "$fixture/mock/apt-get"
: > "$TEST_LOG"
TEST_UID=0 run "$ROOT/bin/ensure" fd rg 2>/dev/null
assert "$(cat "$TEST_LOG")" $'apt-get update\napt-get install -y fd-find\napt-get install -y ripgrep' 'apt mapping and one refresh'
[[ -L "$fixture/home/.local/bin/fd" ]]

# A non-root session must use AppMan even when apt exists; a broken install stops.
ln -s "$fixture/manager" "$fixture/mock/appman"
: > "$TEST_LOG"
run "$ROOT/bin/ensure" jq 2>/dev/null
assert "$(cat "$TEST_LOG")" 'appman -y -i jq' 'non-root backend'

# A foreign-owned brew must never install, even if its prefix is writable.
ln -s "$fixture/manager" "$fixture/mock/brew"
: > "$TEST_LOG"
TEST_BREW_OWNER=2000 run "$ROOT/bin/ensure" gh 2>"$fixture/stderr"
assert "$(cat "$TEST_LOG")" 'appman -y -i gh' 'foreign-owned brew falls back to AppMan on Linux'
cat > "$fixture/mock/curl" <<'SCRIPT'
#!/usr/bin/env bash
set -eu
[[ "${TEST_DOWNLOAD_FAIL:-0}" == 0 ]] || exit 6
while [[ "$1" != -o ]]; do shift; done
cat > "$2" <<'INSTALLER'
set -eu
[[ "$1" == --path && "$2" == "$HOME/b" ]]
[[ "$NONINTERACTIVE" == 1 && "$HOMEBREW_NO_SUDO" == 1 ]]
echo 'bootstrap user brew' >> "$TEST_LOG"
mkdir -p "$2/bin"
cp "$TEST_MANAGER" "$2/bin/brew"
INSTALLER
SCRIPT
chmod +x "$fixture/mock/curl"
: > "$TEST_LOG"
TEST_OS=Darwin TEST_BREW_OWNER=2000 run "$ROOT/bin/ensure" brew 2>"$fixture/stderr"
TEST_OS=Darwin TEST_BREW_OWNER=2000 run "$ROOT/bin/ensure" brew 2>"$fixture/stderr"
assert "$(cat "$TEST_LOG")" 'bootstrap user brew' 'Mac bootstraps a private brew once without sudo'
: > "$TEST_LOG"
TEST_OS=Darwin TEST_BREW_OWNER=2000 run "$ROOT/bin/ensure" tmux 2>"$fixture/stderr"
assert "$(cat "$TEST_LOG")" 'brew install tmux' 'private brew takes precedence over foreign brew'
rm -rf "$fixture/home/b"
rm "$fixture/real/tmux"
: > "$TEST_LOG"
set +e
TEST_DOWNLOAD_FAIL=1 TEST_OS=Darwin TEST_BREW_OWNER=2000 run "$ROOT/bin/ensure" brew 2>"$fixture/stderr"
status=$?
set -e
assert "$status" 6 'failed installer downloads stop before execution'
[[ ! -s "$TEST_LOG" && ! -e "$fixture/home/b" ]]
rm "$fixture/mock/curl"
rm "$fixture/mock/brew"

set +e
TEST_FAIL=1 run "$ROOT/fallback/tmux" </dev/null >"$fixture/stdout" 2>"$fixture/stderr"
status=$?
set -e
assert "$status" 42 'installer failure propagation'
[[ ! -s "$fixture/stdout" && ! -e "$fixture/real/tmux" ]]

# Repeated shell loading must keep exactly one fallback directory at the end.
ln -s "$ROOT" "$fixture/home/dotfiles"
for shell in bash zsh; do
  command -v "$shell" >/dev/null || continue
  result="$(HOME="$fixture/home" DOTFILES_DISABLE_AUTO_REFRESH=1 "$shell" -c '
    source "$HOME/dotfiles/shellrc"
    source "$HOME/dotfiles/shellrc"
    printf "%s\n" "${PATH##*:}"
    printf "%s\n" "$PATH" | tr : "\n" | grep -c "/dotfiles/fallback$"
  ')"
  assert "$result" "$fixture/home/dotfiles/fallback"$'\n1' "$shell PATH ordering"
done

# The default installer performs initialization; repeat runs retain plugin clones.
cat > "$fixture/mock/brew" <<'SCRIPT'
#!/usr/bin/env bash
set -eu
if [[ "$1" == --prefix ]]; then echo "$TEST_BREW_PREFIX"; exit 0; fi
[[ "$1" != list ]] || exit 1
echo "brew $*" >> "$TEST_LOG"
case "${*: -1}" in
  rectangle) app=Rectangle ;;
  thebrowsercompany-dia) app=Dia ;;
  visual-studio-code) app='Visual Studio Code' ;;
  wechat) app=WeChat ;;
  hapigo) app=HapiGo ;;
  *) exit 1 ;;
esac
mkdir -p "$HOME/Applications/$app.app"
SCRIPT
chmod +x "$fixture/mock/brew"
: > "$TEST_LOG"
TEST_OS=Darwin run "$ROOT/bin/ensure" rectangle dia vscode wechat hapigo
for mapping in 'rectangle:Rectangle' 'thebrowsercompany-dia:Dia' 'visual-studio-code:Visual Studio Code' 'wechat:WeChat' 'hapigo:HapiGo'; do
  package="${mapping%%:*}"
  app="${mapping#*:}"
  if [[ ! -d "/Applications/$app.app" ]]; then
    grep -Fx "brew install --cask --appdir=$fixture/home/Applications $package" "$TEST_LOG" >/dev/null
  fi
done
: > "$TEST_LOG"
TEST_OS=Darwin run "$ROOT/bin/ensure" rectangle dia vscode wechat hapigo
[[ ! -s "$TEST_LOG" ]] || { echo 'Existing Mac apps were reinstalled' >&2; exit 1; }
rm "$fixture/mock/brew"

init_home="$fixture/init-home"
mkdir -p "$init_home/dotfiles/core" "$init_home/dotfiles/bin" "$fixture/init-mock"
cp "$ROOT/core/install.sh" "$init_home/dotfiles/core/install.sh"
cat > "$init_home/dotfiles/core/deploy.sh" <<'SCRIPT'
#!/usr/bin/env bash
echo deploy >> "$TEST_LOG"
SCRIPT
cat > "$init_home/dotfiles/bin/ensure" <<'SCRIPT'
#!/usr/bin/env bash
echo "ensure $*" >> "$TEST_LOG"
SCRIPT
cat > "$init_home/dotfiles/core/github-ssh.sh" <<'SCRIPT'
#!/usr/bin/env bash
echo github-ssh >> "$TEST_LOG"
SCRIPT
cat > "$init_home/dotfiles/bin/macos" <<'SCRIPT'
#!/usr/bin/env bash
echo macos >> "$TEST_LOG"
SCRIPT
cp "$fixture/mock/uname" "$fixture/init-mock/uname"
cat > "$fixture/init-mock/git" <<'SCRIPT'
#!/usr/bin/env bash
if [[ "$1" == clone ]]; then
  echo clone >> "$TEST_LOG"
  mkdir -p "${*: -1}"
fi
SCRIPT
chmod +x "$init_home/dotfiles/core/deploy.sh" "$init_home/dotfiles/bin/ensure" "$fixture/init-mock/git"
: > "$TEST_LOG"
for attempt in 1 2; do
  HOME="$init_home" PATH="$fixture/init-mock:$PATH" bash "$init_home/dotfiles/core/install.sh" >/dev/null
done
assert "$(grep -c '^ensure git rg fd jq$' "$TEST_LOG")" 2 'default install ensures agent tools'
assert "$(grep -c '^ensure font-maple-mono-nf-cn font-fira-code$' "$TEST_LOG")" 2 'default install ensures fonts on Linux too'
assert "$(grep -c '^github-ssh$' "$TEST_LOG")" 2 'default install configures GitHub SSH'
assert "$(grep -c '^clone$' "$TEST_LOG")" 2 'plugins cloned only once'
: > "$TEST_LOG"
HOME="$init_home" PATH="$fixture/init-mock:$PATH" bash "$init_home/dotfiles/core/install.sh" --config-only >/dev/null
assert "$(cat "$TEST_LOG")" deploy 'config-only does not install tools'
: > "$TEST_LOG"
HOME="$init_home" PATH="$fixture/init-mock:$PATH" bash "$init_home/dotfiles/core/install.sh" --no-github-ssh >/dev/null
assert "$(cat "$TEST_LOG")" $'deploy\nensure git rg fd jq\nensure font-maple-mono-nf-cn font-fira-code' 'GitHub SSH can be skipped independently'
: > "$TEST_LOG"
HOME="$init_home" PATH="$fixture/init-mock:$PATH" bash "$init_home/dotfiles/core/install.sh" --github-ssh --config-only >/dev/null
assert "$(cat "$TEST_LOG")" $'deploy\ngithub-ssh' 'explicit SSH setup works with config-only regardless of option order'
: > "$TEST_LOG"
HOME="$init_home" TEST_OS=Darwin PATH="$fixture/init-mock:$PATH" bash "$init_home/dotfiles/core/install.sh" >/dev/null
assert "$(cat "$TEST_LOG")" $'deploy\nensure brew\nensure git rg fd jq\nensure font-maple-mono-nf-cn font-fira-code\nensure rectangle dia vscode wechat hapigo\ngithub-ssh\nmacos' 'Mac install includes apps and preferences after SSH without closing apps'
: > "$TEST_LOG"
HOME="$init_home" TEST_OS=Darwin PATH="$fixture/init-mock:$PATH" bash "$init_home/dotfiles/core/install.sh" --config-only >/dev/null
assert "$(cat "$TEST_LOG")" deploy 'Mac config-only skips app downloads and system preferences'
# Mac downloads and preference writes can be skipped independently.
: > "$TEST_LOG"
HOME="$init_home" TEST_OS=Darwin PATH="$fixture/init-mock:$PATH" bash "$init_home/dotfiles/core/install.sh" --no-mac-apps >/dev/null
assert "$(cat "$TEST_LOG")" $'deploy\nensure brew\nensure git rg fd jq\nensure font-maple-mono-nf-cn font-fira-code\ngithub-ssh\nmacos' 'skip Mac apps only'
: > "$TEST_LOG"
HOME="$init_home" TEST_OS=Darwin PATH="$fixture/init-mock:$PATH" bash "$init_home/dotfiles/core/install.sh" --no-macos-settings >/dev/null
assert "$(cat "$TEST_LOG")" $'deploy\nensure brew\nensure git rg fd jq\nensure font-maple-mono-nf-cn font-fira-code\nensure rectangle dia vscode wechat hapigo\ngithub-ssh' 'skip Mac preferences only'

# Run the real preferences script with only mocked defaults/uname available.
# Unexpected privileged commands, process restarts, or indexing commands fail.
mkdir -p "$fixture/preferences-mock"
cp "$fixture/mock/uname" "$fixture/preferences-mock/uname"
ln -s "$(command -v bash)" "$fixture/preferences-mock/bash"
ln -s "$(command -v mkdir)" "$fixture/preferences-mock/mkdir"
cat > "$fixture/preferences-mock/defaults" <<'SCRIPT'
#!/usr/bin/env bash
[[ "${TEST_DEFAULTS_FAIL:-0}" == 0 ]] || exit 35
[[ "$1" == write ]] || exit 1
case "$2" in
  NSGlobalDomain|com.apple.finder|com.apple.dock|com.apple.HIToolbox|com.apple.inputmethod.CoreChineseEngineFramework|com.apple.screencapture) ;;
  *) exit 1 ;;
esac
case "${*: -1}" in
  AppleLanguages|AppleLocale|AppleMeasurementUnits|AppleMetricUnits|FXRemoveOldTrashItems) exit 1 ;;
esac
printf '%s\n' "$*" >> "$TEST_LOG"
SCRIPT
chmod +x "$fixture/preferences-mock/defaults"
: > "$TEST_LOG"
HOME="$fixture/preferences home" TEST_OS=Darwin PATH="$fixture/preferences-mock" bash "$ROOT/bin/macos" >/dev/null
[[ -s "$TEST_LOG" ]]
[[ -d "$fixture/preferences home/Pictures/Screenshots" ]]
set +e
HOME="$fixture/preferences home" TEST_DEFAULTS_FAIL=1 TEST_OS=Darwin PATH="$fixture/preferences-mock" bash "$ROOT/bin/macos" >/dev/null 2>&1
status=$?
set -e
assert "$status" 35 'preference write failures must be reported'

# Existing remote keys must not trigger OAuth refresh or key uploads.
ssh_home="$fixture/ssh-home"
mkdir -p "$ssh_home/.ssh" "$fixture/ssh-mock"
ssh-keygen -q -t ed25519 -N '' -f "$ssh_home/.ssh/id_ed25519"
cp "$ssh_home/.ssh/id_ed25519" "$fixture/original-key"
awk '{print $1 " " $2}' "$ssh_home/.ssh/id_ed25519.pub" > "$ssh_home/remote-key"
cat > "$fixture/ssh-mock/gh" <<'SCRIPT'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$1 ${2:-}" >> "$TEST_LOG"
case "$1 ${2:-}" in
  'auth status') exit 0 ;;
  'api --hostname')
    if [[ "${TEST_KEY_LIST_DENIED:-0}" == 1 && ! -e "$HOME/refreshed" ]]; then exit 1; fi
    cat "$HOME/remote-key"
    ;;
  'auth refresh') : > "$HOME/refreshed" ;;
  'ssh-key add') cat > "$HOME/remote-key" ;;
  *) exit 1 ;;
esac
SCRIPT
chmod +x "$fixture/ssh-mock/gh"
ssh_setup() {
  env -u GH_TOKEN -u GITHUB_TOKEN HOME="$ssh_home" PATH="$fixture/ssh-mock:$PATH" bash "$ROOT/core/github-ssh.sh" >/dev/null
}
: > "$TEST_LOG"
ssh_setup
assert "$(cat "$TEST_LOG")" $'auth status\napi --hostname' 'already-uploaded key needs no refresh'
: > "$TEST_LOG"
TEST_KEY_LIST_DENIED=1 ssh_setup
assert "$(cat "$TEST_LOG")" $'auth status\napi --hostname\nauth refresh\napi --hostname' 'missing read scope refreshes and retries'
: > "$ssh_home/remote-key"
: > "$TEST_LOG"
ssh_setup
assert "$(cat "$TEST_LOG")" $'auth status\napi --hostname\nauth refresh\nssh-key add' 'missing remote key still gets uploaded'
cmp "$fixture/original-key" "$ssh_home/.ssh/id_ed25519"

printf 'Software checks passed: routing, repeat runs, launch contract, failure propagation, PATH ordering.\n'
