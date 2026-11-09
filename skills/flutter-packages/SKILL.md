---
name: flutter-packages
description: Version-aware rules for the packages a Flutter project depends on (state management, DI, routing, networking, codegen, storage, Firebase, localization, native plugins). Use before writing or changing code that calls any third-party Flutter/Dart package, adding a dependency, or upgrading one.
license: MIT
---

# Flutter packages — work with what's installed

The rules here are generic: they work for whatever packages the project uses.
The per-package notes in `references/` are only loaded when the project actually depends on that package.

## Step 1 — Inventory the stack (once per session)

1. Read `pubspec.yaml` (what's declared) and `pubspec.lock` (what's installed — exact versions).
   The session hook may already have printed this summary; if so, use it.
2. Note the Flutter/Dart version: `.fvmrc` → `{"flutter": "x.y.z"}`, or `environment:` in `pubspec.yaml`.
3. Classify every **direct** dependency by job (state, DI, routing, network, models, storage, l10n, …).
4. If two packages do the same job, find which one the code you're about to touch uses (`grep` the imports
   in that feature folder). Use that one. Report the duplication once; don't fix it unasked.

## Step 2 — Verify any API you aren't certain about

Your training data mixes many major versions. Before using an API you haven't just seen in this project:

```bash
V=$(grep -A6 '^  <pkg>:' pubspec.lock | grep version | head -1 | cut -d'"' -f2)
ls ~/.pub-cache/hosted/pub.dev/<pkg>-$V/
grep -n "BREAKING\|Breaking\|deprecated" ~/.pub-cache/hosted/pub.dev/<pkg>-$V/CHANGELOG.md | head -30
grep -rn "class <Name>\|<methodName>(" ~/.pub-cache/hosted/pub.dev/<pkg>-$V/lib | head
```

Order of trust: **project code using the package** > **installed package source** > **package example/** > your memory.

Real example of why: `freezed` 3.0 *removed* `when`/`map`, then 3.1 *added them back*. Only the installed
version tells you which is true for this project.

## Step 3 — Read the matching reference file

Load only the files for packages the project actually has:

| If the project has… | Read |
|---|---|
| flutter_bloc, bloc, provider, riverpod, getx, mobx | `references/state-management.md` |
| get_it, injectable | `references/dependency-injection.md` |
| dio, retrofit, http, chopper, web_socket_channel | `references/networking.md` |
| freezed, json_serializable, equatable, build_runner | `references/models-codegen.md` |
| go_router, auto_route | `references/routing.md` |
| shared_preferences, hive, hive_ce, isar, drift, sqflite, flutter_secure_storage | `references/storage.md` |
| firebase_*, flutterfire | `references/firebase.md` |
| image_picker, permission_handler, geolocator, camera, mobile_scanner, url_launcher, local notifications… | `references/native-plugins.md` |
| flutter_screenutil, cached_network_image, flutter_svg, dartz/fpdart | `references/ui-and-utils.md` |
| easy_localization, intl, flutter_localizations, slang | the `flutter-l10n-rtl` skill |

Any package not listed: apply Steps 1–2 and copy how the project already uses it.

## Step 4 — Adding or upgrading a dependency

- Ask first unless the user explicitly asked for that package.
- Check the project doesn't already have something that does the job.
- Add with `flutter pub add <pkg>` (or `fvm flutter pub add`). For dev tools: `flutter pub add dev:<pkg>`.
- Read the package README's **platform setup** section and apply it (Info.plist, AndroidManifest,
  `minSdk`, Podfile platform, Gradle). List anything you couldn't apply.
- Upgrading a major version: read the CHANGELOG between the two versions first and list the breaking
  changes that affect this codebase *before* editing.
- Never run `flutter pub upgrade --major-versions` unasked.

## Step 5 — Codegen

If you add/modify anything annotated (`@freezed`, `@JsonSerializable`, `@RestApi`, `@injectable`,
`@RoutePage`, `@HiveType`, `@TypedGoRoute`…):

```bash
dart run build_runner build --delete-conflicting-outputs
```

- Make sure the `part '<file>.g.dart';` / `part '<file>.freezed.dart';` lines exist and match the file name.
- Never hand-edit generated output. If generation fails, fix the source and report the error.
- Check whether the project commits generated files (`git ls-files | grep '\.g\.dart$'`). If it does,
  include regenerated files in the change; if it doesn't, don't add them.
