---
name: flutter-ui
description: Build or improve Flutter screens and widgets that look polished and fit the app - reuse the project's design system (theme, colors, text styles, spacing, shared widgets), design every state (loading/empty/error/success), and make them accessible, adaptive, dark-mode and RTL safe. Use when creating or restyling a Flutter screen, widget, flow, or theme, implementing a Figma/screenshot design, or when the user says "make this look better".
license: MIT
---

# Flutter UI

Two jobs, in this order of priority:
1. **Fit the app.** A new screen must look like it belongs to the same app as the existing ones.
2. **Be good UI.** Clear hierarchy, every state designed, comfortable to use with one thumb, accessible.

When these conflict, (1) wins — mention the improvement instead of silently restyling.

## Step 1 — Find the design source (in this order)

1. **A design was given** (Figma link, screenshot, mockup): match it exactly — spacing, sizes, colors, copy.
   Map its values onto the project's existing tokens; if a value has no token, say so instead of inventing one.
   For Figma links, use the Figma tools/skills if available (`figma:figma-design-to-code`, `figma:figma-swiftui`).
2. **The project has a design system**: find and use it. Search before writing any widget:
   ```bash
   grep -rlE "ThemeExtension|ThemeData\(|ColorScheme" lib | head
   grep -rlE "class (App|K)(Colors|TextStyles|Typography|Spacing|Sizes|Radius|Dimens|Insets)" lib | head
   ls lib/**/widgets lib/core/widgets lib/shared/widgets lib/common/widgets 2>/dev/null
   ```
   Look for shared widgets (`AppButton`, `PrimaryButton`, `AppTextField`, `AppNetworkImage`, `AppScaffold`,
   `EmptyState`, `ErrorView`, `LoadingWidget`, bottom sheets, dialogs) and **use them** instead of raw Material widgets.
3. **Copy the nearest similar screen**: a list screen? open an existing list screen and match its app bar,
   padding, card style, loading and error handling.
4. **Nothing exists** (new app or first screens): set up a small token system first —
   see `references/flutter-ui-patterns.md` §1 — then apply `references/design-principles.md`.

Never:
- Hardcode hex colors, font sizes, or font families inside widgets when the project has tokens/theme.
- Add a UI package (shimmer, animations, icons, fonts, glassmorphism) without asking.
- Restyle existing screens while building a new one.

## Step 2 — Structure before style

- What is the **one primary action** on this screen? It gets the strongest visual weight and sits in the
  thumb zone (bottom area: bottom button, FAB, bottom sheet) — unless the project's pattern puts it elsewhere.
- What should the user notice first? Make values bigger than labels ("591" bigger than "Sales").
- Show content directly — don't hide key info behind extra taps, banners, or expandable sections.
- Prefer selection over typing for common choices (chips, segmented buttons, pickers) with an "Other" fallback.
- Never a blank search screen: show recent / suggested items.
- Lists: `ListView.builder` / `SliverList`; pull-to-refresh (`RefreshIndicator`) if other lists in the app have it.

## Step 3 — Design every state

A screen that loads data is not done until it has all of these (using the project's shared widgets if they exist):

| State | Rule |
|---|---|
| Loading | Skeleton/placeholder shaped like the content for lists and cards; spinner only for short actions. Don't block the whole screen when only one section loads. |
| Empty | Icon or illustration + one-line explanation + a CTA that fixes it ("Add your first card"). Never just "No data". |
| Error | Human message (mapped from the failure, localized) + Retry. Keep already-loaded content visible if possible. |
| Success / data | The real layout. |
| Action in progress | Disable the button and show progress *inside* it; prevent double taps. |
| Action success | Clear feedback: snackbar/toast style the app already uses, a check animation, or navigation. |

Forms: inline validation messages under fields, keep the submit button reachable above the keyboard, keep
user input on error, correct keyboard types (`TextInputType.emailAddress`, `.phone`, `.number`) and
`textInputAction` / autofill hints.

## Step 4 — Visual rules (only where the project has no rule already)

Short version — details in `references/design-principles.md`:
- **Spacing:** 4/8-point scale (4, 8, 12, 16, 24, 32, 48). Related things close, groups further apart (≈2×).
  Screen horizontal padding usually 16–24.
- **Typography:** use `Theme.of(context).textTheme` roles (or the project's styles). Max ~4 sizes and 2–3 weights per screen.
  Use tabular figures for prices and stats: `fontFeatures: [FontFeature.tabularFigures()]`.
- **Color:** mostly neutral surfaces, text in on-surface tones, the brand color only for primary actions and
  key indicators (~60/30/10). Use `colorScheme` roles (`primary`, `onPrimary`, `surface`, `surfaceContainer*`,
  `onSurfaceVariant`, `error`, `outlineVariant`) — never raw colors that break in dark mode.
  Reserve red for errors and destructive actions.
- **Hierarchy with opacity/tone**, not with bold everywhere: secondary text in `onSurfaceVariant`.
- **Shape & depth:** one corner-radius scale used everywhere; soft, low shadows or tonal elevation
  (Material 3 `surfaceContainer*`) — no harsh black shadows on colored backgrounds.
- **Icons:** one icon style across the app (the one the project uses). Directional icons must flip in RTL.

## Step 5 — Mobile reality checks

- `SafeArea` / `MediaQuery.paddingOf` for notches and home indicator; bottom buttons must not sit under the home bar.
- Keyboard: fields and the submit button stay visible (`Scaffold` default resize + scrollable body, or
  `MediaQuery.viewInsetsOf(context).bottom` for custom sheets).
- Text scaling: layout must survive the system font at 200% — no fixed heights around text, use `Flexible`,
  `maxLines` + `overflow`, wrap rows that can overflow.
- Small and large screens: check 320–375 pt width phones; use `LayoutBuilder` / `MediaQuery.sizeOf` for tablets
  if the app supports them. No fixed widths that overflow.
- Touch targets ≥ 48×48 dp (Material) / 44×44 pt (iOS), even if the visual icon is smaller.
- Platform feel: follow the project. If it's adaptive, use `.adaptive` constructors
  (`Switch.adaptive`, `CircularProgressIndicator.adaptive`, `AlertDialog.adaptive` + `showAdaptiveDialog`).
- Images: `cached_network_image` (or the project's image widget) with placeholder + error widget, fixed aspect ratio
  to avoid layout jumps.

## Step 6 — Accessibility

- Contrast: body text ≥ 4.5:1, large text/icons ≥ 3:1 — theme roles usually guarantee it; custom colors must be checked.
- Icon-only buttons need `tooltip:` (IconButton) or a `Semantics(label: ...)`.
- Don't convey meaning by color alone (add an icon or text to red/green states).
- Group related text for screen readers with `MergeSemantics` where it reads better (e.g. a list tile).
- Respect reduced motion: `MediaQuery.disableAnimationsOf(context)`.

## Step 7 — Motion & delight (small, purposeful)

- Use built-in implicit animations: `AnimatedSwitcher` between states, `AnimatedContainer`/`AnimatedOpacity`,
  `Hero` for list → detail images. Durations 150–300 ms, standard easing (`Curves.easeOutCubic`).
- Pick **one** peak moment in the flow (payment done, task completed, milestone) and give it real feedback:
  a check animation, `HapticFeedback.mediumImpact()`, encouraging localized copy.
- End flows with closure (summary/confirmation), not a sudden pop back.
- No animation on every element, no infinite decorative animations, no blur/gradients unless the app's style already has them.

## Step 8 — Verify before saying done

Ask the user for a screenshot if you can't run it, or run it yourself if you can. Check:
- [ ] Uses the project's theme/tokens/shared widgets — no new hardcoded colors or font sizes
- [ ] Loading, empty, error, success states all exist
- [ ] Light **and** dark mode
- [ ] RTL (Arabic) **and** LTR — padding, alignment, icons
- [ ] Text scale 1.0 and 2.0 — nothing overflows (no yellow-black stripes)
- [ ] Small phone (≈ 320–375 wide) and the largest supported device
- [ ] Keyboard open on forms
- [ ] `flutter analyze` clean
- [ ] Strings localized (see `flutter-l10n-rtl`)

For layout-sensitive widgets, a widget test that pumps them at 320 width, text scale 2.0, and RTL catches
most regressions — see `references/flutter-ui-patterns.md` §6.

## References
- `references/design-principles.md` — the visual and UX rules in detail, plus industry conventions.
- `references/flutter-ui-patterns.md` — Flutter code for tokens (`ThemeExtension`), state switching,
  skeletons, empty/error views, adaptive layout, and a layout stress test.
