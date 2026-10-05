#!/usr/bin/env fish

set -gx CLICOLOR 1
set -gx LSCOLORS ExGxBxDxCxEgEdxbxgxcxd
set -gx MAKE 'make -j9'
set -gx CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN 1

alias codex 'command codex --no-alt-screen'

if status is-login; and functions -q on_login
  on_login
end
