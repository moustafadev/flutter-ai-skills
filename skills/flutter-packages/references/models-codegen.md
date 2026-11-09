# Models & code generation

## build_runner (everything below)
- After changing any annotated class: `dart run build_runner build --delete-conflicting-outputs`.
- `part` directives must match the file name exactly: `user.dart` → `part 'user.freezed.dart';` `part 'user.g.dart';`.
- Never hand-edit `*.g.dart` / `*.freezed.dart`. If the generator errors, fix the source.
- If the project has a `build.yaml`, respect its options (e.g. `field_rename: snake`, `explicit_to_json`).

## freezed
**Check the version in `pubspec.lock` — the syntax changed:**

| freezed | Class syntax | `when`/`map` |
|---|---|---|
| 2.x | `@freezed class User with _$User` | generated |
| 3.0.x | `@freezed abstract class User with _$User` (data) / `@freezed sealed class Result with _$Result` (unions) | **removed** — use Dart 3 `switch` |
| ≥ 3.1 | same as 3.0 (`abstract`/`sealed` required) | generated again, but `switch` is still preferred |

- Data class: `const factory User({required String id, String? name}) = _User;`
- JSON: add `factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);` + `part 'user.g.dart';`
- Custom getters/methods need a private constructor: `const User._();`
- Defaults: `@Default(<String>[]) List<String> tags`.
- Prefer exhaustive `switch (state) { Loading() => ..., Data(:final value) => ... }` for unions.

## json_serializable
- `@JsonSerializable()` + `factory X.fromJson(...) => _$XFromJson(json);` + `Map<String, dynamic> toJson() => _$XToJson(this);`
- Map API keys with `@JsonKey(name: 'user_name')` or the project's `fieldRename` setting — don't rename fields to snake_case.
- Nested objects need `explicitToJson: true` (per class or in `build.yaml`) for correct `toJson`.
- Nullable vs required: match what the API can actually return. A field the server sometimes omits must be
  nullable or have `@JsonKey(defaultValue: ...)` — otherwise parsing crashes in production.
- Enums: `@JsonEnum()` / `@JsonValue('x')`; add `unknownEnumValue:` for forward-compatibility.

## equatable
- Every field must be in `props`. Missing one = bugs where state "doesn't update".
- Lists in `props` compare by content — fine. Mutable lists inside state are not.

## Entities vs models
- If the project separates `entities` (domain) from `models` (data/JSON), keep that split:
  JSON annotations only on models, mapping in the model (`toEntity()`) or a mapper — copy what exists.
