#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/core/software.sh"

setup_ssh() {
  "$ROOT/bin/ensure" gh
  command -v ssh-keygen >/dev/null || { echo "Install OpenSSH first." >&2; return 1; }
  local GH_HOST=github.com
  export GH_HOST
  local key="$HOME/.ssh/id_ed25519" public_key keys refresh_needed=1
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  if [ ! -e "$key" ]; then
    if [ -e "$key.pub" ]; then
      echo "Public key exists without its private key: $key.pub; resolve this before rerunning." >&2
      exit 1
    fi
    # ssh-keygen prompts for a passphrase; existing private keys are never replaced.
    ssh-keygen -t ed25519 -f "$key" -C "$(whoami)@$(hostname)"
  fi
  # Derive from the private key, so a missing or stale .pub file is harmless.
  public_key="$(ssh-keygen -y -f "$key" | awk '{print $1 " " $2}')"
  if ! gh auth status --hostname github.com >/dev/null 2>&1; then
    gh auth login --hostname github.com --git-protocol ssh --web --skip-ssh-key --scopes admin:public_key
    refresh_needed=0
  fi
  if ! keys="$(gh api --hostname github.com --paginate user/keys --jq '.[].key')"; then
    # Token authentication cannot refresh scopes interactively.
    [ -z "${GH_TOKEN:-}${GITHUB_TOKEN:-}" ] || return 1
    gh auth refresh --hostname github.com --scopes admin:public_key
    refresh_needed=0
    keys="$(gh api --hostname github.com --paginate user/keys --jq '.[].key')"
  fi
  if printf '%s\n' "$keys" | awk '{print $1 " " $2}' | grep -Fx "$public_key" >/dev/null; then
    echo 'SSH public key already uploaded to GitHub.'
    return
  fi
  if [[ "$refresh_needed" == 1 && -z "${GH_TOKEN:-}${GITHUB_TOKEN:-}" ]]; then
    gh auth refresh --hostname github.com --scopes admin:public_key
  fi
  printf '%s\n' "$public_key" | gh ssh-key add --title "$(whoami)@$(hostname)" --type authentication
  echo 'SSH public key uploaded to GitHub.'
}

setup_ssh
