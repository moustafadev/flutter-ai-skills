# UI & utility packages

## flutter_screenutil
- If the project uses it, size everything the same way (`.w`, `.h`, `.r`, `.sp`) — don't mix raw doubles in new widgets.
- `ScreenUtilInit` must wrap the app with the project's `designSize`; don't add another.
- `.sp` on font sizes respects the project's `minTextAdapt` / text scaling settings — don't double-scale with `textScaler`.
- `const` is impossible with `.w/.h` values — that's expected; still use `const` for children that allow it.

## cached_network_image
- Always give `placeholder` / `errorWidget` (or the project's shared image widget — look for one first, e.g. `AppNetworkImage`).
- Set `memCacheWidth/Height` for thumbnails in long lists to avoid memory blow-ups.

## flutter_svg
- `SvgPicture.asset(path, colorFilter: ColorFilter.mode(color, BlendMode.srcIn))` — the old `color:` parameter is deprecated.
- Use the project's generated asset paths (`flutter_gen`, `Assets.icons.x`) if they exist instead of string paths.
- Register new assets in `pubspec.yaml` `flutter: assets:` if the folder isn't already listed.

## google_fonts / custom fonts
- Use the project's theme text styles (`Theme.of(context).textTheme…` or the project's `AppTextStyles`) — don't
  set `GoogleFonts.x()` per widget.

## dartz / fpdart (functional error handling)
- If repositories return `Either<Failure, T>`, new ones must too. `Left` = failure, `Right` = success.
- Consume with `result.fold((failure) => ..., (data) => ...)`; don't call `getOrElse(() => null!)`-style hacks.
- Don't introduce `Either` into a project that uses exceptions (or vice versa).

## Theming (all projects)
- Colors from `Theme.of(context).colorScheme` or the project's `AppColors` — no new hex literals scattered in widgets.
- Material 3 is default since Flutter 3.16; don't add `useMaterial3: false` or M2-only APIs unless the project uses M2.
- If the project imports `material_ui` / `cupertino_ui` packages instead of `package:flutter/material.dart`,
  follow that import style.
- Dark mode: test that new widgets read from the theme, not hardcoded light colors.

## device_preview / debug-only tools
- Keep them behind `kDebugMode` / `!kReleaseMode` checks, as the project already does.
