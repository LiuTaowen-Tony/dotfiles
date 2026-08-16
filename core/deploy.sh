#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="$HOME/.local/state/dotfiles"
GENERATED_DIR="$STATE_DIR/generated"

mkdir -p "$GENERATED_DIR"

write_if_changed() {
  local source_file="$1"
  local target_file="$2"

  if [[ -f "$target_file" ]] && cmp -s "$source_file" "$target_file"; then
    rm -f "$source_file"
  else
    mv -f "$source_file" "$target_file"
  fi
}

safe_link() {
  local source_path="$1"
  local target_path="$2"

  if [[ -e "$target_path" && ! -L "$target_path" ]]; then
    printf 'Skipping %s: an unmanaged file already exists.\n' "$target_path" >&2
    return
  fi
  ln -sfn "$source_path" "$target_path"
}

gitconfig_tmp="$(mktemp "$GENERATED_DIR/gitconfig.XXXXXX")"
git config --file "$gitconfig_tmp" --add include.path "$ROOT/defaults/gitconfig"
if [[ -f "$ROOT/custom/defaults/gitconfig" ]]; then
  git config --file "$gitconfig_tmp" --add include.path "$ROOT/custom/defaults/gitconfig"
fi
write_if_changed "$gitconfig_tmp" "$GENERATED_DIR/gitconfig"

touch "$HOME/.gitconfig"
git config --file "$HOME/.gitconfig" --unset-all include.path '^~/dotfiles/gitconfig$' \
  >/dev/null 2>&1 || true
if ! git config --file "$HOME/.gitconfig" --get-all include.path 2>/dev/null \
    | grep -Fqx "$GENERATED_DIR/gitconfig"; then
  git config --file "$HOME/.gitconfig" --add include.path "$GENERATED_DIR/gitconfig"
fi

"$ROOT/core/ensure_file_contains" 'set -g mouse off' "$HOME/.tmux.conf"

agents_tmp="$(mktemp "$GENERATED_DIR/AGENTS.md.XXXXXX")"
cp "$ROOT/agents/AGENTS.md" "$agents_tmp"
if [[ -f "$ROOT/custom/agents/AGENTS.md" ]]; then
  printf '\n' >> "$agents_tmp"
  cat "$ROOT/custom/agents/AGENTS.md" >> "$agents_tmp"
fi
write_if_changed "$agents_tmp" "$GENERATED_DIR/AGENTS.md"

mkdir -p "$HOME/.claude" "$HOME/.codex" "$HOME/.cursor"
safe_link "$GENERATED_DIR/AGENTS.md" "$HOME/.claude/CLAUDE.md"
safe_link "$GENERATED_DIR/AGENTS.md" "$HOME/.codex/AGENTS.md"
safe_link "$GENERATED_DIR/AGENTS.md" "$HOME/.cursor/AGENTS.md"

settings_source="$ROOT/agents/claude_settings.json"
if [[ -f "$ROOT/custom/agents/claude_settings.json" ]]; then
  settings_source="$ROOT/custom/agents/claude_settings.json"
fi
if [[ ! -f "$HOME/.claude/settings.json" ]] \
    || ! cmp -s "$settings_source" "$HOME/.claude/settings.json"; then
  cp "$settings_source" "$HOME/.claude/settings.json"
fi

deploy_skills() {
  local target_dir="$1"
  local skill

  mkdir -p "$target_dir"
  for skill in "$ROOT/agents/skills"/*; do
    [[ -d "$skill" ]] || continue
    safe_link "$skill" "$target_dir/$(basename "$skill")"
  done
  if [[ -d "$ROOT/custom/agents/skills" ]]; then
    for skill in "$ROOT/custom/agents/skills"/*; do
      [[ -d "$skill" ]] || continue
      safe_link "$skill" "$target_dir/$(basename "$skill")"
    done
  fi
}

deploy_skills "$HOME/.claude/skills"
deploy_skills "$HOME/.codex/skills"
deploy_skills "$HOME/.cursor/skills-cursor"

vim_source="$ROOT/defaults/vimrc"
[[ -f "$ROOT/custom/defaults/vimrc" ]] && vim_source="$ROOT/custom/defaults/vimrc"
if [[ -e "$HOME/.SpaceVim" ]]; then
  spacevim_source="$ROOT/defaults/spacevim"
  [[ -d "$ROOT/custom/defaults/spacevim" ]] && spacevim_source="$ROOT/custom/defaults/spacevim"
  safe_link "$spacevim_source" "$HOME/.SpaceVim.d"
else
  safe_link "$vim_source" "$HOME/.vimrc"
fi

if [[ -x "$ROOT/custom/bin/deploy.sh" ]]; then
  "$ROOT/custom/bin/deploy.sh"
fi
