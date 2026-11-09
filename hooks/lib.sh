#!/usr/bin/env bash
# Shared helpers for flutter-ai-skills hooks. Sourced, not executed.

# Walk up from $1 until a directory containing pubspec.yaml is found.
find_project_root() {
  local dir="$1"
  [ -f "$dir" ] && dir="$(dirname "$dir")"
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    [ -f "$dir/pubspec.yaml" ] && { echo "$dir"; return 0; }
    dir="$(dirname "$dir")"
  done
  return 1
}

# Flutter version pinned by FVM (.fvmrc or legacy .fvm/fvm_config.json), if any.
fvm_version() {
  local root="$1" f
  for f in "$root/.fvmrc" "$root/.fvm/fvm_config.json"; do
    [ -f "$f" ] || continue
    grep -oE '"(flutter|flutterSdkVersion)"[[:space:]]*:[[:space:]]*"[^"]+"' "$f" | head -1 | sed -E 's/.*"([^"]+)"$/\1/'
    return 0
  done
}

# Path to the dart binary that matches the project (FVM first, then PATH).
find_dart() {
  local root="$1" v
  if [ -x "$root/.fvm/flutter_sdk/bin/dart" ]; then echo "$root/.fvm/flutter_sdk/bin/dart"; return 0; fi
  v="$(fvm_version "$root")"
  if [ -n "$v" ]; then
    for base in "${FVM_CACHE_PATH:-}" "$HOME/fvm" "$HOME/.fvm"; do
      [ -n "$base" ] && [ -x "$base/versions/$v/bin/dart" ] && { echo "$base/versions/$v/bin/dart"; return 0; }
    done
  fi
  command -v dart 2>/dev/null && return 0
  return 1
}

# Read a field from hook JSON on stdin-captured string. Usage: json_get "$INPUT" '.tool_input.file_path'
json_get() {
  local input="$1" path="$2"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r "$path // empty" 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$input" | python3 -I -c '
import json, sys
d = json.load(sys.stdin)
for k in sys.argv[1].lstrip(".").split("."):
    d = d.get(k) if isinstance(d, dict) else None
print(d if isinstance(d, str) else "")' "$path" 2>/dev/null
  fi
}
