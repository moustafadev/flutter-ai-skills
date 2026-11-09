#!/usr/bin/env bash
# PostToolUse hook: after Claude edits a .dart file, format it and analyze it.
# Analyzer errors/warnings are fed back to Claude (exit 2) so it fixes them right away.
# Infos/lints are ignored here to keep the loop quiet.

source "$(dirname "$0")/lib.sh"

INPUT="$(cat)"
FILE="$(json_get "$INPUT" '.tool_input.file_path')"

case "$FILE" in
  *.g.dart|*.freezed.dart|*.gr.dart|*.config.dart|*.mocks.dart) exit 0 ;;  # generated
  *.dart) ;;
  *) exit 0 ;;
esac
[ -f "$FILE" ] || exit 0

ROOT="$(find_project_root "$FILE")" || exit 0
DART="$(find_dart "$ROOT")" || exit 0

cd "$ROOT" || exit 0

"$DART" format "$FILE" >/dev/null 2>&1

# Lines changed vs HEAD ("ALL" if the file is new/untracked or there's no git repo).
# Used so INFO-level issues are only reported on lines Claude touched — pre-existing ones stay out of scope.
CHANGED="ALL"
if git -C "$ROOT" ls-files --error-unmatch "$FILE" >/dev/null 2>&1; then
  CHANGED="$(git -C "$ROOT" diff -U0 HEAD -- "$FILE" 2>/dev/null | awk '
    /^@@/ { split($3, a, ","); s = substr(a[1], 2); n = (a[2] == "" ? 1 : a[2]); for (i = 0; i < n; i++) printf "%d,", s + i }')"
fi

# Machine format: SEVERITY|TYPE|CODE|FILE|LINE|COL|LEN|MESSAGE
# ERROR/WARNING anywhere in the file; plus a few INFO codes that are real bugs, but only on changed lines.
ISSUES="$("$DART" analyze --format=machine "$FILE" 2>&1 | awk -F'|' -v changed=",$CHANGED" '
  $1 == "ERROR" || $1 == "WARNING" { print; next }
  $1 == "INFO" && $3 ~ /^(DEPRECATED_MEMBER_USE|USE_BUILD_CONTEXT_SYNCHRONOUSLY)$/ {
    if (changed == ",ALL" || index(changed, "," $5 ",")) print
  }' | head -20)"

MSGS=""
if [ -n "$ISSUES" ]; then
  MSGS="$(printf '%s\n' "$ISSUES" | awk -F'|' -v root="$ROOT/" '{ f=$4; sub("^" root, "", f); printf "- %s %s:%s:%s  %s (%s)\n", $1, f, $5, $6, $8, $3 }')"
  MSGS="dart analyze found issues in ${FILE#"$ROOT"/} — fix them before continuing:
$MSGS"
fi

# Annotated code changed but generated part is stale/missing → remind about build_runner.
if grep -qE "^part '.+\.(g|freezed|gr|config)\.dart';" "$FILE" 2>/dev/null; then
  for part in $(grep -oE "^part '[^']+\.(g|freezed|gr|config)\.dart'" "$FILE" | sed -E "s/^part '([^']+)'/\1/"); do
    GEN="$(dirname "$FILE")/$part"
    if [ ! -f "$GEN" ] || [ "$FILE" -nt "$GEN" ]; then
      MSGS="${MSGS:+$MSGS
}Note: $part is missing or older than $(basename "$FILE"). If you changed annotated code, run: dart run build_runner build --delete-conflicting-outputs"
      break
    fi
  done
fi

if [ -n "$MSGS" ]; then
  printf '%s\n' "$MSGS" >&2
  exit 2
fi
exit 0
