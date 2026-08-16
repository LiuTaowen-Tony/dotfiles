#!/usr/bin/env fish

set -gx CLICOLOR 1
set -gx LSCOLORS ExGxBxDxCxEgEdxbxgxcxd
set -gx MAKE 'make -j9'

if status is-login; and functions -q on_login
  on_login
end
