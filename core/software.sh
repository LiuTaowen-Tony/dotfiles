# Shared by ensure and the fallback launchers (Bash).
SOFTWARE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Remove every fallback entry, including alternate spellings and symlinks.
# Otherwise command -v could mistake a launcher for an installed program.
software_path=""
software_rest="${PATH}:"
while [[ "$software_rest" == *:* ]]; do
  software_entry="${software_rest%%:*}"
  software_rest="${software_rest#*:}"
  if [[ "${software_entry:-.}" -ef "$SOFTWARE_ROOT/fallback" ]]; then
    continue
  fi
  software_path="${software_path}${software_entry}:"
done
export PATH="$HOME/b/bin:$HOME/b/sbin:${XDG_BIN_HOME:-$HOME/.local/bin}:$HOME/.local/bin:${software_path%:}"
unset software_path software_rest software_entry

software_exists() {
  if [[ "$1" == fd ]] && ! command -v fd >/dev/null 2>&1 \
      && command -v fdfind >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi
  command -v "$1" >/dev/null 2>&1
}
