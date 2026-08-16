#!/usr/bin/env fish

set -gx DOTFILES_ROOT "$HOME/dotfiles"
set -gx PATH "$DOTFILES_ROOT/custom/bin" "$DOTFILES_ROOT/bin" $PATH
set -gx CLICOLOR 1
set -gx LSCOLORS ExGxBxDxCxEgEdxbxgxcxd
set -gx MAKE 'make -j9'

source "$DOTFILES_ROOT/defaults/aliases"
if test -r "$DOTFILES_ROOT/custom/defaults/aliases"
  source "$DOTFILES_ROOT/custom/defaults/aliases"
end
if test -r "$DOTFILES_ROOT/custom/defaults/common_config.fish"
  source "$DOTFILES_ROOT/custom/defaults/common_config.fish"
end

if status is-login; and functions -q on_login
  on_login
end

if status is-interactive; and test -z "$DOTFILES_DISABLE_AUTO_REFRESH"
  mkdir -p "$DOTFILES_ROOT/tmp"
  set check_output "$DOTFILES_ROOT/tmp/.check_update_output.txt"
  touch "$check_output"
  if test -s "$check_output"
    cat "$check_output"
    command truncate -s 0 "$check_output"
  end
  "$DOTFILES_ROOT/core/refresh.sh" >> "$check_output" 2>&1 &
end
