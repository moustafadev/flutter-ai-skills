#!/usr/bin/env bash
# CLAUDE.md is the single source of truth for the core rules.
# This regenerates the Claude Code skill and the Cursor rule from it. Run after editing CLAUDE.md.
set -euo pipefail
cd "$(dirname "$0")/.."
BODY="$(sed '1,/^---$/d' CLAUDE.md)"   # drop the CLAUDE.md title/intro up to the first ---

cat > skills/flutter-guidelines/SKILL.md <<MD
---
name: flutter-guidelines
description: Core behavioral rules for writing Flutter/Dart code - follow the project's existing stack and versions, keep changes minimal and surgical, avoid deprecated APIs and BuildContext/async bugs, configure native permissions, and verify with format/analyze/test before claiming done. Use whenever writing, editing, reviewing, or refactoring Flutter or Dart code.
license: MIT
---

# Flutter guidelines

Behavioral rules that reduce the most common LLM mistakes in Flutter/Dart.
For package-specific rules see the \`flutter-packages\` skill; for tests \`flutter-testing\`; for text/RTL \`flutter-l10n-rtl\`; for screens and visual design \`flutter-ui\`.

**Tradeoff:** these rules bias toward correctness over speed. For trivial edits, use judgment.

---
$BODY
MD

cat > .cursor/rules/flutter-guidelines.mdc <<MD
---
description: Flutter/Dart behavioral guidelines - follow the project's stack and versions, surgical changes, no deprecated APIs, verify with analyze/test
globs: **/*.dart,pubspec.yaml
alwaysApply: true
---

# Flutter guidelines

**Tradeoff:** these rules bias toward correctness over speed. For trivial edits, use judgment.

---
$BODY
MD
echo "synced skills/flutter-guidelines/SKILL.md and .cursor/rules/flutter-guidelines.mdc"
