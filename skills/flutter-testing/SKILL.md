---
name: flutter-testing
description: How to verify Flutter work - analyzer, unit, bloc/notifier, widget, and golden tests, using the project's existing test tooling. Use when fixing a bug, adding a feature that has testable logic, writing or repairing tests, or before claiming a Flutter task is done.
license: MIT
---

# Flutter testing & verification

## The verification loop (always)

Use `fvm flutter` / `fvm dart` if the project has `.fvmrc`.

```
1. dart format <changed files>
2. flutter analyze                       → zero new errors/warnings
3. dart run build_runner build -d         (only if annotated code changed)
4. flutter test <relevant test files>     → green
```

Report results honestly: which commands ran, what passed, what failed, what you couldn't run.

## Use what the project already has

Check `dev_dependencies` before writing a test:

| If present | Use it for |
|---|---|
| `bloc_test` | `blocTest<MyCubit, MyState>(build:, act:, expect:)` |
| `mocktail` | `class MockRepo extends Mock implements Repo {}` + `when(() => ...)`, `registerFallbackValue` for custom args |
| `mockito` | `@GenerateMocks([...])` + build_runner — don't mix with mocktail |
| `golden_toolkit` / `alchemist` | golden tests in the project's existing style |
| `integration_test` / `patrol` | end-to-end flows |
| nothing | plain `flutter_test` with hand-written fakes |

Don't add a new test package without asking. Put tests in `test/` mirroring `lib/` paths
(`lib/features/auth/auth_cubit.dart` → `test/features/auth/auth_cubit_test.dart`), or follow the existing layout.

## Bug fixes: reproduce first
1. Write the smallest test that fails because of the bug.
2. Run it — confirm it fails for the right reason.
3. Fix the code.
4. Run it again — confirm it passes, plus neighbouring tests.

If the bug is untestable in the current structure (e.g. logic buried in a widget), say so and propose the
minimal change — don't restructure silently.

## What to test where
- **Unit**: models (`fromJson` with a real API sample, including missing/null fields), mappers, validators, utils.
- **Bloc / Cubit / Notifier**: each event/method → expected sequence of states, including the error path.
  Mock repositories, not HTTP.
- **Widget**: rendering for each state (loading / data / empty / error), key interactions, navigation trigger.
  - Wrap with what the widget needs: `MaterialApp`, localization delegates, `BlocProvider.value(value: mockCubit)`,
    `ProviderScope(overrides:)`, `ScreenUtilInit` — copy from an existing widget test or a shared `pumpApp` helper.
  - `await tester.pumpAndSettle()` hangs on infinite animations (progress indicators) — use `pump(duration)` there.
  - Find by `Key` or semantic text; avoid `find.byType` for generic widgets.
- **RTL**: for layout-sensitive widgets, also pump with `Directionality(textDirection: TextDirection.rtl)`
  or the Arabic locale.

## Don'ts
- Don't make tests pass by loosening assertions, adding `skip:`, or deleting tests.
- Don't hit real network/Firebase in unit/widget tests.
- Don't commit golden files generated on a different platform than CI uses without saying so.
- Don't leave `print` / `debugPrint` in tests.
