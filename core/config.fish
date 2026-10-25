#!/usr/bin/env fish

set -gx DOTFILES_ROOT "$HOME/dotfiles"
set -gx PATH "$DOTFILES_ROOT/custom/bin" "$DOTFILES_ROOT/bin" "$HOME/b/bin" "$HOME/b/sbin" "$HOME/.local/bin" $PATH

set shell_config "$DOTFILES_ROOT/defaults/common_config.fish"
if test -r "$DOTFILES_ROOT/custom/defaults/common_config.fish"
  set shell_config "$DOTFILES_ROOT/custom/defaults/common_config.fish"
end
source "$shell_config"

set -l real_paths
for entry in $PATH
  if not test "$entry" -ef "$DOTFILES_ROOT/fallback"
    set -a real_paths "$entry"
  end
end
set -gx PATH $real_paths "$DOTFILES_ROOT/fallback"

if status is-interactive
  if not set -q DOTFILES_DISABLE_AUTO_REFRESH
    mkdir -p "$DOTFILES_ROOT/tmp"
    set check_output "$DOTFILES_ROOT/tmp/.check_update_output.txt"
    touch "$check_output"
    if test -s "$check_output"
      cat "$check_output"
      command truncate -s 0 "$check_output"
    end
    "$DOTFILES_ROOT/core/refresh.sh" >> "$check_output" 2>&1 &
  end
end
