#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-tests.XXXXXX")"
TEST_ROOT="$(cd "$TEST_ROOT" && pwd)"
trap 'rm -rf "$TEST_ROOT"' EXIT

pass_count=0

pass() {
  pass_count=$((pass_count + 1))
  printf 'ok %d - %s\n' "$pass_count" "$1"
}

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local reason="$3"
  [[ "$actual" == "$expected" ]] || fail "$reason (expected '$expected', got '$actual')"
}

assert_contains() {
  local needle="$1"
  local haystack="$2"
  local reason="$3"
  [[ "$haystack" == *"$needle"* ]] || fail "$reason"
}

configure_git_user() {
  git -C "$1" config user.name 'Dotfiles Test'
  git -C "$1" config user.email 'dotfiles@example.test'
}

copy_worktree() {
  local target="$1"
  mkdir -p "$target"
  cp -R "$ROOT/." "$target"
  rm -rf "$target/.git"
  git -C "$target" init -q -b master
  configure_git_user "$target"
  git -C "$target" add -A
  git -C "$target" commit -qm 'test snapshot'
}

snapshot_deployment() {
  local home="$1"
  find "$home" -path "$home/dotfiles" -prune -o \( -type f -o -type l \) -print \
    | LC_ALL=C sort \
    | while IFS= read -r path; do
        if [[ -L "$path" ]]; then
          printf 'link %s %s\n' "$path" "$(readlink "$path")"
        else
          cksum "$path"
        fi
      done
}

install_home="$TEST_ROOT/install-home"
copy_worktree "$install_home/dotfiles"
printf '%s\n' 'export BEFORE_DOTFILES=1' 'source $HOME/dotfiles/shellrc' > "$install_home/.bashrc"
printf '%s\n' 'source "$HOME/dotfiles/defaults/shellrc"' > "$install_home/.zshrc"
printf '%s\n' '[include]' '  path = ~/dotfiles/gitconfig' > "$install_home/.gitconfig"
HOME="$install_home" DOTFILES_UPSTREAM_URL='https://example.test/upstream.git' \
  "$install_home/dotfiles/core/install.sh" >/dev/null
HOME="$install_home" DOTFILES_UPSTREAM_URL='https://example.test/upstream.git' \
  "$install_home/dotfiles/core/install.sh" >/dev/null

assert_eq '1' "$(grep -Fc 'source "$HOME/dotfiles/core/shellrc"' "$install_home/.bashrc")" \
  'installer must add the Bash source exactly once'
assert_eq '1' "$(grep -Fc 'source "$HOME/dotfiles/core/shellrc"' "$install_home/.zshrc")" \
  'installer must add the Zsh source exactly once'
assert_eq '0' "$(grep -Fc 'dotfiles/shellrc' "$install_home/.bashrc" || true)" \
  'installer must remove the obsolete Bash source path'
assert_eq '0' "$(grep -Fc 'dotfiles/defaults/shellrc' "$install_home/.zshrc" || true)" \
  'installer must remove the obsolete Zsh source path'
assert_eq 'https://example.test/upstream.git' \
  "$(git -C "$install_home/dotfiles" remote get-url upstream)" \
  'installer must configure upstream'
assert_eq '0' "$(git config --file "$install_home/.gitconfig" --get-all include.path \
    | grep -Fc '~/dotfiles/gitconfig' || true)" \
  'deploy must remove the obsolete Git include path'
[[ -L "$install_home/.codex/AGENTS.md" ]] || fail 'default agent rules must be linked for Codex'
[[ -L "$install_home/.vimrc" ]] || fail 'default Vim configuration must be linked'
assert_eq 'vim' "$(HOME="$install_home" git config --global --includes core.editor)" \
  'default Git configuration must load on first install'
for expected_setting in \
  'color.ui auto' \
  'push.autoSetupRemote true' \
  'push.followTags true' \
  'pull.rebase false' \
  'fetch.prune true' \
  'rerere.enabled true' \
  'merge.conflictStyle zdiff3' \
  'rebase.autostash true' \
  'rebase.autosquash true' \
  'commit.verbose true' \
  'column.ui auto' \
  'branch.sort -committerdate' \
  'tag.sort version:refname' \
  'diff.colorMoved default'; do
  read -r setting_key setting_value <<< "$expected_setting"
  assert_eq "$setting_value" "$(HOME="$install_home" git config --global --includes "$setting_key")" \
    "default Git setting $setting_key must be deployed"
done

git_init_project="$TEST_ROOT/git-init-project"
mkdir -p "$git_init_project"
default_shell_result="$(
  HOME="$install_home" TEST_PROJECT="$git_init_project" TERM=xterm \
    DOTFILES_DISABLE_AUTO_REFRESH=1 bash --noprofile --norc -ic \
      'source "$HOME/dotfiles/core/shellrc"; alias myip >/dev/null; cnmirror on >/dev/null; printf "%s|%s|" "$PIP_INDEX_URL" "$CONDARC"; cd "$TEST_PROJECT"; git init >/dev/null; cnmirror off >/dev/null; printf "%s|%s" "${PIP_INDEX_URL-unset}" "${CONDARC-unset}"' \
      2>/dev/null
)"
assert_eq "https://pypi.tuna.tsinghua.edu.cn/simple|$install_home/dotfiles/defaults/condarc|unset|unset" \
  "$default_shell_result" 'default shell must expose reversible China mirrors'
cmp -s "$git_init_project/.gitignore" "$install_home/dotfiles/defaults/common_gitignore" \
  || fail 'plain git init must install the common project ignore file'
pass 'defaults-only install is complete and repeatable'

before_snapshot="$(snapshot_deployment "$install_home")"
HOME="$install_home" "$install_home/dotfiles/core/deploy.sh"
after_snapshot="$(snapshot_deployment "$install_home")"
assert_eq "$before_snapshot" "$after_snapshot" 'a second deploy must not change deployed content or targets'
pass 'deploy is idempotent'

mkdir -p "$install_home/dotfiles/custom/defaults" \
  "$install_home/dotfiles/custom/bin" \
  "$install_home/dotfiles/agents/skills/default-only" \
  "$install_home/dotfiles/custom/agents/skills/exec-goal" \
  "$install_home/dotfiles/custom/agents/skills/custom-only"
printf '%s\n' 'export CUSTOM_SHELL_LOADED=1' > "$install_home/dotfiles/custom/defaults/shellrc"
printf '%s\n' "alias ll='printf custom-alias'" > "$install_home/dotfiles/custom/defaults/aliases"
printf '%s\n' '[core]' '  editor = custom-editor' > "$install_home/dotfiles/custom/defaults/gitconfig"
printf '%s\n' '# Custom agent marker' > "$install_home/dotfiles/custom/agents/AGENTS.md"
printf '%s\n' '# Default-only skill marker' > "$install_home/dotfiles/agents/skills/default-only/SKILL.md"
printf '%s\n' '# Custom skill marker' > "$install_home/dotfiles/custom/agents/skills/exec-goal/SKILL.md"
printf '%s\n' '# Custom-only skill marker' > "$install_home/dotfiles/custom/agents/skills/custom-only/SKILL.md"
printf '%s\n' '#!/usr/bin/env bash' "echo default-script" > "$install_home/dotfiles/bin/layer-probe"
printf '%s\n' '#!/usr/bin/env bash' "echo custom-script" > "$install_home/dotfiles/custom/bin/layer-probe"
printf '%s\n' '#!/usr/bin/env bash' \
  '[[ -L "$HOME/.codex/AGENTS.md" ]] || exit 1' \
  'printf "%s\n" after-default > "$HOME/custom-deploy-order"' \
  > "$install_home/dotfiles/custom/bin/deploy.sh"
chmod +x "$install_home/dotfiles/bin/layer-probe" \
  "$install_home/dotfiles/custom/bin/layer-probe" \
  "$install_home/dotfiles/custom/bin/deploy.sh"

HOME="$install_home" "$install_home/dotfiles/core/deploy.sh"
shell_result="$(
  HOME="$install_home" TERM=xterm DOTFILES_DISABLE_AUTO_REFRESH=1 \
    bash --noprofile --norc -ic \
      'unset MAKE; source "$HOME/dotfiles/core/shellrc"; printf "%s|%s|" "$CUSTOM_SHELL_LOADED" "${MAKE-unset}"; eval ll; printf "|"; layer-probe' \
      2>/dev/null
)"
assert_contains '1|unset|custom-alias|custom-script' "$shell_result" \
  "custom shell, aliases, and commands must take precedence over defaults (got '$shell_result')"
assert_eq 'custom-editor' "$(HOME="$install_home" git config --global --includes core.editor)" \
  'custom Git configuration must replace the default file'
assert_eq '' "$(HOME="$install_home" git config --global --includes core.autocrlf || true)" \
  'replaced Git configuration must not retain keys from the default file'
generated_agents="$install_home/.local/state/dotfiles/generated/AGENTS.md"
assert_eq '0' "$(grep -Fc '# Agent Rules' "$generated_agents" || true)" \
  'custom agent rules must replace the default file'
assert_eq '1' "$(grep -Fc '# Custom agent marker' "$generated_agents")" \
  'custom agent rules must occur once'
assert_eq "$install_home/dotfiles/custom/agents/skills/exec-goal" \
  "$(readlink "$install_home/.codex/skills/exec-goal")" \
  'custom skill must replace the same-named default skill'
assert_eq "$install_home/dotfiles/agents/skills/default-only" \
  "$(readlink "$install_home/.codex/skills/default-only")" \
  'default-only skills must remain available'
assert_eq "$install_home/dotfiles/custom/agents/skills/custom-only" \
  "$(readlink "$install_home/.codex/skills/custom-only")" \
  'custom-only skills must be added'
assert_eq 'after-default' "$(< "$install_home/custom-deploy-order")" \
  'custom deploy hook must run after default agent deployment'
pass 'custom overlays replace same-named files and retain other entries'

printf '%s\n' '#!/usr/bin/env bash' 'touch "$HOME/custom-update-ran"' \
  > "$install_home/dotfiles/custom/bin/update.sh"
chmod +x "$install_home/dotfiles/custom/bin/update.sh"
HOME="$install_home" DOTFILES_UPSTREAM_URL='https://example.test/upstream.git' \
  "$install_home/dotfiles/core/update.sh" >/dev/null
[[ ! -e "$install_home/custom-update-ran" ]] || fail 'custom commands must not replace core update behavior'
pass 'custom commands cannot replace core lifecycle scripts'

create_update_fixture() {
  local name="$1"
  local fixture="$TEST_ROOT/$name"
  local official_work="$fixture/official-work"
  local upstream_bare="$fixture/upstream.git"
  local fork_work="$fixture/fork"
  local origin_bare="$fixture/origin.git"

  mkdir -p "$official_work/core" "$official_work/defaults" "$official_work/custom"
  cp "$ROOT/core/update.sh" "$official_work/core/update.sh"
  chmod +x "$official_work/core/update.sh"
  printf '%s\n' 'base' > "$official_work/defaults/value"
  git -C "$official_work" init -q -b master
  configure_git_user "$official_work"
  git -C "$official_work" add -A
  git -C "$official_work" commit -qm 'base'
  git clone -q --bare "$official_work" "$upstream_bare"
  git -C "$official_work" remote add origin "$upstream_bare"

  git clone -q "$upstream_bare" "$fork_work"
  configure_git_user "$fork_work"
  git init -q --bare "$origin_bare"
  git -C "$fork_work" remote set-url origin "$origin_bare"
  git -C "$fork_work" push -q -u origin master

  printf '%s\n' "$official_work|$upstream_bare|$fork_work|$origin_bare"
}

IFS='|' read -r official_work upstream_bare fork_work origin_bare \
  <<< "$(create_update_fixture merge-case)"
mkdir -p "$fork_work/custom"
printf '%s\n' 'fork customization' > "$fork_work/custom/user-setting"
git -C "$fork_work" add custom/user-setting
git -C "$fork_work" commit -qm 'fork customization'
git -C "$fork_work" push -q origin master
origin_before="$(git --git-dir="$origin_bare" rev-parse master)"
printf '%s\n' 'upstream update' > "$official_work/defaults/value"
git -C "$official_work" add defaults/value
git -C "$official_work" commit -qm 'upstream defaults update'
git -C "$official_work" push -q origin master
DOTFILES_UPSTREAM_URL="$upstream_bare" "$fork_work/core/update.sh" >/dev/null
assert_eq 'upstream update' "$(< "$fork_work/defaults/value")" \
  'fork must merge upstream default updates'
assert_eq 'fork customization' "$(< "$fork_work/custom/user-setting")" \
  'fork custom commits must survive an upstream merge'
assert_eq "$origin_before" "$(git --git-dir="$origin_bare" rev-parse master)" \
  'automatic update must not push its merge to origin'
pass 'fork custom commits merge upstream defaults without pushing'

IFS='|' read -r official_work upstream_bare fork_work origin_bare \
  <<< "$(create_update_fixture dirty-case)"
printf '%s\n' 'upstream update' > "$official_work/defaults/value"
git -C "$official_work" add defaults/value
git -C "$official_work" commit -qm 'upstream defaults update'
git -C "$official_work" push -q origin master
dirty_head="$(git -C "$fork_work" rev-parse HEAD)"
printf '%s\n' 'dirty' > "$fork_work/defaults/value"
dirty_output="$(DOTFILES_UPSTREAM_URL="$upstream_bare" "$fork_work/core/update.sh")"
assert_contains 'working tree is not clean' "$dirty_output" 'dirty worktree must explain why update was skipped'
assert_eq "$dirty_head" "$(git -C "$fork_work" rev-parse HEAD)" 'dirty worktree must not merge'
pass 'dirty worktree is left untouched'

IFS='|' read -r official_work upstream_bare fork_work origin_bare \
  <<< "$(create_update_fixture branch-case)"
git -C "$fork_work" checkout -qb topic
branch_head="$(git -C "$fork_work" rev-parse HEAD)"
branch_output="$(DOTFILES_UPSTREAM_URL="$upstream_bare" "$fork_work/core/update.sh")"
assert_contains 'expected master' "$branch_output" 'non-master branch must explain why update was skipped'
assert_eq "$branch_head" "$(git -C "$fork_work" rev-parse HEAD)" 'non-master branch must not merge'
pass 'non-master branch is left untouched'

IFS='|' read -r official_work upstream_bare fork_work origin_bare \
  <<< "$(create_update_fixture conflict-case)"
printf '%s\n' 'fork conflict' > "$fork_work/defaults/value"
git -C "$fork_work" add defaults/value
git -C "$fork_work" commit -qm 'fork conflict'
printf '%s\n' 'upstream conflict' > "$official_work/defaults/value"
git -C "$official_work" add defaults/value
git -C "$official_work" commit -qm 'upstream conflict'
git -C "$official_work" push -q origin master
if DOTFILES_UPSTREAM_URL="$upstream_bare" "$fork_work/core/update.sh" >/dev/null 2>&1; then
  fail 'conflicting update must report failure'
fi
[[ ! -e "$fork_work/.git/MERGE_HEAD" ]] || fail 'conflicting update must abort the merge'
assert_eq 'fork conflict' "$(< "$fork_work/defaults/value")" \
  'merge abort must restore the fork version'
pass 'merge conflicts abort cleanly'

mkdir -p "$install_home/dotfiles/custom/bin"
printf '%s\n' '#!/usr/bin/env bash' 'echo deploy >> "$HOME/refresh-deploy.log"' 'sleep 1' \
  > "$install_home/dotfiles/custom/bin/deploy.sh"
chmod +x "$install_home/dotfiles/custom/bin/deploy.sh"
HOME="$install_home" "$install_home/dotfiles/core/refresh.sh" >/dev/null 2>&1 &
first_refresh=$!
HOME="$install_home" "$install_home/dotfiles/core/refresh.sh" >/dev/null 2>&1 &
second_refresh=$!
wait "$first_refresh" || true
wait "$second_refresh" || true
assert_eq '1' "$(wc -l < "$install_home/refresh-deploy.log" | tr -d ' ')" \
  'concurrent refreshes must perform one deployment'
pass 'atomic refresh lock prevents overlapping update and deploy'

for script in "$ROOT"/core/*.sh "$ROOT"/bin/*; do
  [[ -f "$script" ]] || continue
  bash -n "$script"
done
bash -n "$ROOT/core/shellrc" "$ROOT/defaults/shellrc"
if command -v zsh >/dev/null 2>&1; then
  zsh -n "$ROOT/core/shellrc" "$ROOT/defaults/shellrc"
fi
if command -v fish >/dev/null 2>&1; then
  fish -n "$ROOT/core/config.fish" "$ROOT/defaults/common_config.fish"
fi
if grep -Fq '/aliases' "$ROOT/core/config.fish"; then
  fail 'Fish loader must not source Bash aliases'
fi
git -C "$ROOT" diff --check
if grep -En '[[:blank:]]+$' "$ROOT"/core/*.sh "$ROOT/core/shellrc" \
    "$ROOT/core/config.fish" "$ROOT/custom/README.md" \
    "$ROOT/tests/test_dotfiles.sh" "$ROOT/README.md"; then
  fail 'new files must not contain trailing whitespace'
fi
pass 'shell syntax and whitespace checks pass'

printf '1..%d\n' "$pass_count"
