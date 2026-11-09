# State management

**Universal rule:** use the project's existing solution and the same flavour of it (Cubit vs Bloc,
Notifier vs StateNotifier, codegen vs manual). Never introduce a second state-management package.

## Universal
- State classes are immutable. Copy with `copyWith`, never mutate a list/map inside state and re-emit it.
- Equality matters: with `equatable`, every field must be in `props`; with `freezed`, it's generated.
  A state that compares equal to the previous one is **not** re-emitted, so the UI won't rebuild.
- Model loading/error explicitly — either a status enum + fields, or a sealed hierarchy. Follow the project.
- Business logic lives in the state holder, not in widgets. Widgets dispatch intents and render state.
- Don't keep `BuildContext`, controllers, or widgets inside state objects.

## flutter_bloc / bloc
- Events: register with `on<Event>((event, emit) async { ... })` in the constructor.
  `mapEventToState` was removed in bloc 8 — never write it.
- `BlocOverrides` was removed in bloc 9 — use `Bloc.observer = ...`.
- Inside an async handler, `await` everything before the handler returns; emitting after it completes throws.
  Use `emit.forEach` / `emit.onEach` for streams.
- Concurrency (debounce search, drop duplicate taps): use `transformer:` with `bloc_concurrency`
  only if the project has it.
- Cubit methods that `emit` after an `await`: guard with `if (isClosed) return;`.
- In widgets:
  - `context.read<T>()` in callbacks (`onPressed`), never in `build`.
  - `context.watch<T>()` / `BlocBuilder` / `BlocSelector` in `build`.
  - `BlocListener` for one-off side effects (navigation, snackbars, dialogs) — not `BlocBuilder`.
  - `BlocConsumer` only when you need both.
  - Use `buildWhen` / `listenWhen` / `BlocSelector` to avoid rebuilding the whole screen.
- Providing:
  - `BlocProvider(create: (_) => getIt<X>())` creates **and closes** it.
  - `BlocProvider.value(value: existing)` for an instance created elsewhere — never `BlocProvider.value(value: X())`.
- If blocs come from `get_it`, they should normally be `registerFactory` (new instance per screen),
  not singletons — check how the project registers existing ones.
- Tests: use `bloc_test` + `mocktail`/`mockito` if the project has them.

## provider
- `ChangeNotifier`: call `notifyListeners()` after changes; dispose controllers in `dispose()`.
- `context.read` in callbacks, `context.watch` / `Consumer` / `Selector` in build.
- `ChangeNotifierProvider(create:)` for new instances, `.value` for existing ones.
- If the project uses `flutter_bloc` as its main solution, don't add new `ChangeNotifier`s just because
  `provider` is in pubspec — it may only be there transitively or for a legacy screen.

## riverpod (flutter_riverpod / hooks_riverpod / riverpod_annotation)
- Check the major version in `pubspec.lock` first — 2.x and 3.x differ (e.g. 3.x moves `StateProvider`,
  `StateNotifierProvider`, `ChangeNotifierProvider` to `package:flutter_riverpod/legacy.dart`).
- For new code prefer `Notifier` / `AsyncNotifier` (or `@riverpod` codegen if the project uses `riverpod_generator`).
- `ref.watch` in build / provider bodies, `ref.read` in callbacks, `ref.listen` for side effects.
- Never `ref.read` inside `build` to "avoid rebuilds".
- `ref.onDispose` to clean up; use `autoDispose` (default in codegen) for screen-scoped state.
- Wrap the app in `ProviderScope`; override providers in tests via `ProviderContainer(overrides: ...)`.

## getx
- If the project uses GetX for state, follow its conventions (`GetxController`, `.obs`, `Obx`, bindings).
- Don't mix GetX navigation with go_router/auto_route in the same flow.
- Don't introduce GetX into a project that doesn't already use it.

## setState only
- Fine for local UI state. Lift state up or use the project's solution when 2+ widgets need it.
- Guard async: `if (!mounted) return; setState(...)`.
