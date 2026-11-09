# Local storage

**Universal:** access storage through the project's existing wrapper (e.g. `LocalStorage`, `CacheHelper`,
`PrefsService`) — don't call the package directly from widgets or blocs if a wrapper exists.
Keep keys as constants in one place.

## What goes where
| Data | Use |
|---|---|
| Tokens, passwords, secrets | `flutter_secure_storage` (if available) — **never** shared_preferences / Hive plain boxes. If the project has no secure storage, say so. |
| Small flags/settings | shared_preferences |
| Structured / offline data | the project's DB (hive / hive_ce / isar / drift / sqflite) |

## shared_preferences
- Newer versions offer `SharedPreferencesAsync` / `SharedPreferencesWithCache`; the legacy
  `SharedPreferences.getInstance()` still works. Use whichever the project uses.
- If the instance is registered in DI, inject it — don't call `getInstance()` everywhere.

## hive vs hive_ce
- `hive` (original) is unmaintained; `hive_ce` is the community continuation. **Never mix imports**:
  a project on `hive_ce` imports `package:hive_ce/hive.dart` / `hive_ce_flutter`, generator `hive_ce_generator`.
- `Hive.initFlutter()` before opening boxes; open boxes once (startup or a service), not in `build`.
- Type adapters: hive uses `@HiveType(typeId: n)` + `@HiveField(n)`; hive_ce also supports
  `@GenerateAdapters([...])` — use what the project uses.
- **Never change or reuse an existing `typeId` / field index** — it corrupts data already stored on users' devices.
  Add new fields with new indexes and make them nullable / defaulted.
- Close boxes on logout if the project clears user data there.

## isar / drift / sqflite
- Schema changes need a migration (drift: bump `schemaVersion` + `MigrationStrategy`; sqflite: `onUpgrade`;
  isar: schema evolves but renamed/removed fields lose data). Never ship a schema change without one.
- Run queries off the UI thread the way the package intends (they're async — don't block `build`).
- Regenerate code after schema changes (drift, isar).
