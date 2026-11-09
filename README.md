# Flutter AI Skills

Guardrails that make Claude Code (and Cursor) write Flutter code that fits **your** project: your packages,
your versions, your architecture, and verified with the analyzer before saying "done".

Inspired by [andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills), but specific to Flutter, and with
**hooks that enforce the rules** instead of only asking the model to follow them.

English | [العربية](./README.ar.md)

## The problems

LLMs writing Flutter code tend to:

- **Use APIs from the wrong version.** Training data mixes freezed 2 and 3, bloc 7 and 9, go_router 6 through 17, dio 4 and 5.
- **Add packages the project doesn't need.** They bring in a second HTTP client, a second state-management solution, or a version number they made up.
- **Ignore the architecture.** A project built on Cubit + get_it + repositories suddenly gets a `ChangeNotifier` with an inline `http.get`.
- **Write deprecated code.** `withOpacity`, `WillPopScope`, `MaterialStateProperty`, `DioError`.
- **Break at runtime.** `BuildContext` used after `await`, controllers that are never disposed, a missing `Info.plist` key that crashes iOS.
- **Hand-edit generated files**, or forget to run `build_runner`.
- **Hardcode strings and LTR layouts** in apps that support Arabic.
- **Claim "done"** without running `flutter analyze`.

## What's inside

| Part | What it does |
|---|---|
| `CLAUDE.md` | Core rules in one file. Drop it into any Flutter project. |
| `skills/flutter-guidelines` | Same core rules as a skill. Loaded whenever Claude writes Dart. |
| `skills/flutter-packages` | Generic, version-aware workflow for **any** package: read `pubspec.lock`, verify APIs in `~/.pub-cache`, follow the project's existing choice. Plus reference notes for bloc, provider, riverpod, getx, get_it, injectable, dio, retrofit, http, freezed, json_serializable, equatable, go_router, auto_route, shared_preferences, hive / hive_ce, isar, drift, Firebase, native plugins, screenutil, dartz / fpdart. Only the files for packages you actually use get loaded. |
| `skills/flutter-ui` | Screens that fit your app and look polished. It finds and reuses your design system first (theme, tokens, shared widgets, the nearest similar screen) or follows a Figma design exactly. It requires loading, empty, error and success states for every screen, and checks thumb-zone placement, accessibility, keyboard, safe area, text scaling, dark mode and RTL. Includes Flutter code for tokens (`ThemeExtension`), skeletons, empty and error views, and a widget test that fails on overflow at 320px width, 2× text and RTL. Design principles are adapted from [ceorkm/mobile-app-ui-design](https://github.com/ceorkm/mobile-app-ui-design). |
| `skills/flutter-testing` | Verification loop, bug-fix-by-test, bloc / widget / golden tests with the tools you already have. |
| `skills/flutter-l10n-rtl` | easy_localization / gen-l10n / slang, RTL-safe layout, number, date, and money formatting. |
| `hooks/session-context.sh` | **SessionStart:** prints the project's Flutter version (FVM-aware) and every direct dependency with its exact locked version, grouped by job. It also warns when the project already has two packages for the same job. |
| `hooks/dart-check.sh` | **PostToolUse:** after every edit to a `.dart` file, runs `dart format` and `dart analyze` with the project's own SDK. Errors and warnings go straight back to Claude so it fixes them. It also reminds Claude to run `build_runner` when a `part` file is stale. |
| `.cursor/rules/` | The core rules as a Cursor project rule. |
| `EXAMPLES.md` | Before/after code for each rule. |

### Session start output (real project)

```
## Flutter project stack (from pubspec.lock — trust these versions over memory)
Flutter (FVM): 3.44.4  → use `fvm flutter` / `fvm dart`
  State:             flutter_bloc 9.1.1
  DI:                get_it 8.3.0, injectable 2.7.1+4
  Network:           dio 5.9.2, retrofit 4.9.2
  Models:            freezed 3.2.5, freezed_annotation 3.1.0, json_serializable 6.11.4
  Storage:           shared_preferences 2.5.5, hive_ce 2.19.3
  Localization:      easy_localization 3.0.8
⚠ Multiple packages for the same job: routing, http+dio. Follow whichever the code you're editing already uses.
```

## Install

**Option A: Claude Code plugin (recommended, includes the hooks)**

```
/plugin marketplace add moustafadev/flutter-ai-skills
/plugin install flutter-ai-skills@flutter-ai-skills
```

From a local clone: `/plugin marketplace add /path/to/flutter-ai-skills`.

**Option B: `CLAUDE.md` only (per project, no hooks)**

```bash
curl -o CLAUDE.md https://raw.githubusercontent.com/moustafadev/flutter-ai-skills/main/CLAUDE.md
# or append to an existing one
curl https://raw.githubusercontent.com/moustafadev/flutter-ai-skills/main/CLAUDE.md >> CLAUDE.md
```

**Cursor:** copy `.cursor/rules/flutter-guidelines.mdc` into your project's `.cursor/rules/`.

### Requirements for the hooks
- `bash`, plus `jq` or `python3` to parse hook input.
- A Dart SDK. The hooks look for it in this order: `.fvm/flutter_sdk`, `~/fvm/versions/<version from .fvmrc>`, then `dart` on your `PATH`.
- If no SDK is found, or the session isn't in a Flutter project, the hooks do nothing.

## Customize

Add project-specific rules under the imported ones:

```markdown
## Project-specific
- Feature folders: lib/features/<name>/{data,domain,presentation}
- All repositories return Either<Failure, T>
- Colors only from AppColors, text styles only from AppTextStyles
```

Edit `CLAUDE.md`, then run `./scripts/sync.sh` to regenerate the skill and the Cursor rule from it.

## How to know it's working

- No new analyzer warnings after Claude's edits.
- No surprise packages in `pubspec.yaml`.
- New features look like the existing ones: same folders, same state classes, same error flow.
- Generated files get regenerated, not hand-edited.
- Arabic and RTL screens don't need a second pass.
- New screens have loading, empty and error states, and don't overflow with large text.

## Tradeoff

These rules favor correctness over speed. For one-line fixes, the model should use judgment.
The analyze hook adds a few seconds per edited Dart file.

## License

MIT
