---
name: flutter-l10n-rtl
description: Localization and right-to-left (Arabic, Hebrew, Persian, Urdu) rules for Flutter - easy_localization, gen-l10n/ARB, intl, slang, directional layout, number/date/currency formatting. Use when adding user-facing text, building or changing layouts in an app that supports RTL or more than one language, or formatting dates/numbers/money.
license: MIT
---

# Localization & RTL

## Step 1 — Detect the l10n system and use only that

| Signs in the project | System | How to add a string |
|---|---|---|
| `easy_localization` in pubspec, `assets/translations/*.json` | easy_localization | Add the key to **every** language file, use `'key'.tr()` / `LocaleKeys.key.tr()` if `LocaleKeys` is generated |
| `l10n.yaml`, `lib/l10n/*.arb`, `generate: true` | gen-l10n (ARB) | Add to every `.arb` (with `@key` metadata for placeholders), run `flutter gen-l10n` (or build), use `AppLocalizations.of(context)!.key` / the project's `context.l10n.key` extension |
| `slang` in pubspec, `i18n/*.json` | slang | Add to every file, regenerate, use `t.section.key` |
| none | — | Ask before adding localization; otherwise follow existing hardcoded style |

Rules:
- **Every** new user-facing string goes through the system — including snackbars, dialogs, validation
  messages, and error messages mapped from failures.
- Add the key to **all** locale files in the same change. If you can't translate (e.g. Russian), add the
  English text and tell the user which keys need translation — never leave a key missing.
- Follow the existing key naming (`auth.login.title` vs `loginTitle`). Search for an existing key before adding a new one.
- Placeholders and plurals use the system's syntax (`{count}` + ICU `plural` in ARB, `plural()` in
  easy_localization) — never concatenate strings: `'${'items'.tr()} $n'` breaks word order in Arabic.
- If easy_localization generates `LocaleKeys` (`codegen_loader.g.dart` / `locale_keys.g.dart`), regenerate
  with `dart run easy_localization:generate ...` the way the project's scripts/README say.

## Step 2 — RTL-safe layout

| Don't | Do |
|---|---|
| `EdgeInsets.only(left: 8)` / `fromLTRB` | `EdgeInsetsDirectional.only(start: 8)` / `fromSTEB` |
| `Alignment.centerLeft` | `AlignmentDirectional.centerStart` |
| `Positioned(left: 0)` | `PositionedDirectional(start: 0)` |
| `BorderRadius.only(topLeft:)` | `BorderRadiusDirectional.only(topStart:)` |
| `TextAlign.left` | `TextAlign.start` |
| Manually flipping `Icons.arrow_back` / `Icons.chevron_right` | Nothing — directional Material icons already mirror in RTL (`matchTextDirection`). Flip only custom SVG/PNG directional icons, using `Directionality.of(context)` |
| `Row` children ordered assuming LTR | `Row` already follows text direction — don't reverse manually |

- Don't wrap screens in `Directionality(textDirection: TextDirection.rtl)` manually — the app's locale sets it.
  Exceptions: content that's always LTR (phone numbers, IBANs, code, OTP fields) → wrap *that field* in
  `Directionality(textDirection: TextDirection.ltr)`.
- Mixed Arabic + Latin/number text can render out of order — use `TextDirection` on the `Text`, or Unicode
  marks (`‏` RLM / `‎` LRM) when needed.
- Directional icons (back, forward, chevrons, send) should flip in RTL; non-directional ones (search, home, check)
  should not. Check custom asset icons especially — they never flip automatically.
- Check text overflow: Arabic strings are often longer/taller — use `Flexible`/`Expanded`, `maxLines` + `overflow`.

## Step 3 — Formatting (intl)
- Dates: `DateFormat.yMMMd(locale)` — never build `'$day/$month/$year'` by hand.
- Numbers/money: `NumberFormat.currency(locale: ..., symbol: ...)`, `NumberFormat.decimalPattern(locale)`.
  Use the project's money type if it has one (e.g. `decimal`) — never `double` arithmetic for money.
- Decide deliberately between Arabic-Indic digits (٠١٢) and Western digits (012) — follow what the
  app already shows; `NumberFormat` uses the locale's default.
- Parsing user input: normalize Arabic-Indic digits before `int.parse` / `double.parse`.

## Step 4 — Verify
- Run the app (or a widget test) in the RTL locale and the LTR locale. Check padding, icons, alignment, overflow.
- No missing-key warnings in the console (easy_localization logs them).
