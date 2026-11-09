# Dependency injection

## get_it
- Find the setup file (`injection.dart`, `service_locator.dart`, `di.dart`, `injection_container.dart`)
  and register new things there, in the same style and order as existing registrations.
- Choose the lifetime deliberately and match the project:
  - `registerFactory` — new instance each time (blocs/cubits, view models).
  - `registerLazySingleton` — one shared instance created on first use (Dio, repositories, data sources).
  - `registerSingleton` / `registerSingletonAsync` — created eagerly (needs `await getIt.allReady()` if async).
- Register dependencies **before** whatever depends on them, or the lazy getter will throw.
- Don't call `getIt<T>()` deep inside widgets if the project passes dependencies via constructors/BlocProvider.
- get_it 9 disposes in strict LIFO order — relevant if you rely on `dispose:` callbacks.
- Tests: `getIt.reset()` in `tearDown`, or `getIt.pushNewScope()` / `popScope()` to override.

## injectable (with get_it)
- If the project uses injectable, **never register manually** — annotate and regenerate:
  - `@injectable` (factory), `@lazySingleton`, `@singleton`
  - `@LazySingleton(as: AbstractRepo)` for interface → implementation
  - `@module` abstract class for third-party types (Dio, SharedPreferences) with `@preResolve` for async ones
  - `@Named('x')` / `@Environment('dev')` if the project uses them
- After annotating: `dart run build_runner build --delete-conflicting-outputs`, which updates
  `injection.config.dart`. Never edit that file by hand.
- Missing-dependency errors at runtime usually mean: forgot the annotation, wrong `as:` type, or didn't regenerate.
