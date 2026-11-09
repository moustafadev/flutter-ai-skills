#!/usr/bin/env bash
# SessionStart hook: if the session is in a Flutter project, print its stack
# (Flutter version + direct dependencies with exact locked versions, grouped by job)
# so Claude starts with the real versions instead of guessing from memory.

source "$(dirname "$0")/lib.sh"

INPUT="$(cat)"
CWD="$(json_get "$INPUT" '.cwd')"
[ -n "$CWD" ] || CWD="$PWD"

ROOT="$(find_project_root "$CWD")" || exit 0
grep -qE '^[[:space:]]+flutter:[[:space:]]*$|sdk: flutter' "$ROOT/pubspec.yaml" 2>/dev/null || exit 0
LOCK="$ROOT/pubspec.lock"

# name<TAB>version<TAB>kind for every direct dependency in pubspec.lock
deps() {
  [ -f "$LOCK" ] || return 0
  awk '
    /^packages:/ { inpk=1; next }
    inpk && /^[^ ]/ { inpk=0 }
    inpk && /^  [a-zA-Z0-9_]+:$/ { name=$1; sub(":","",name); kind=""; next }
    inpk && /^    dependency:/ { kind=$0; sub(/.*dependency: /,"",kind); gsub(/"/,"",kind) }
    inpk && /^    version:/ { v=$2; gsub(/"/,"",v); if (v=="0.0.0") v="sdk"; if (kind ~ /^direct/ && name!="flutter") print name "\t" v "\t" kind }
  ' "$LOCK"
}

ALL="$(deps)"
ver() { printf '%s\n' "$ALL" | awk -F'\t' -v n="$1" '$1==n {print $2; exit}'; }

group() { # label pkg...
  local label="$1"; shift; local found="" p v
  for p in "$@"; do v="$(ver "$p")"; [ -n "$v" ] && found="$found $p $v,"; done
  [ -n "$found" ] && printf '  %-18s%s\n' "$label:" "${found%,}"
}

count() { local n=0 p; for p in "$@"; do [ -n "$(ver "$p")" ] && n=$((n+1)); done; echo $n; }

echo "## Flutter project stack (from pubspec.lock — trust these versions over memory)"
echo "Project: $ROOT"
FV="$(fvm_version "$ROOT")"
[ -n "$FV" ] && echo "Flutter (FVM): $FV  → use \`fvm flutter\` / \`fvm dart\`"
[ -f "$LOCK" ] || { echo "No pubspec.lock yet — run \`flutter pub get\` before relying on versions."; exit 0; }

group "State"        flutter_bloc bloc provider flutter_riverpod hooks_riverpod riverpod get mobx signals
group "DI"           get_it injectable
group "Routing"      go_router auto_route beamer
group "Network"      dio retrofit http chopper web_socket_channel graphql_flutter
group "Models"       freezed freezed_annotation json_serializable json_annotation equatable built_value
group "Storage"      shared_preferences flutter_secure_storage hive hive_flutter hive_ce hive_ce_flutter isar drift sqflite objectbox
group "Localization" easy_localization flutter_localizations intl slang
group "Errors/FP"    dartz fpdart
group "Firebase"     firebase_core firebase_messaging firebase_crashlytics firebase_remote_config firebase_auth cloud_firestore firebase_analytics
group "Testing"      bloc_test mocktail mockito golden_toolkit alchemist patrol integration_test

OTHER="$(printf '%s\n' "$ALL" | awk -F'\t' '$3=="direct main" {printf "%s %s, ", $1, $2}' )"
[ -n "$OTHER" ] && echo "  All direct deps:  ${OTHER%, }"

# Duplicate tools for the same job — use the one the current feature uses, don't add a third.
WARN=""
[ "$(count flutter_bloc provider flutter_riverpod hooks_riverpod get mobx)" -gt 1 ] && WARN="$WARN state-management,"
[ "$(count go_router auto_route beamer)" -gt 1 ] && WARN="$WARN routing,"
[ -n "$(ver http)" ] && [ -n "$(ver dio)" ] && WARN="$WARN http+dio,"
[ -n "$(ver hive)" ] && [ -n "$(ver hive_ce)" ] && WARN="$WARN hive+hive_ce,"
[ "$(count dartz fpdart)" -gt 1 ] && WARN="$WARN dartz+fpdart,"
[ -n "$WARN" ] && echo "⚠ Multiple packages for the same job:${WARN%,}. Follow whichever the code you're editing already uses; mention it, don't migrate unasked."

echo "Before using an API you're unsure of, check ~/.pub-cache/hosted/pub.dev/<pkg>-<version>/. See the flutter-packages skill."
exit 0
