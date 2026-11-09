# Design principles (mobile)

Use these when the project has no rule for something, or when designing new screens/apps.
If the project's design system already decides something (spacing scale, radius, fonts), the project wins.

The visual rules and emotional-design ideas here are adapted from
[ceorkm/mobile-app-ui-design](https://github.com/ceorkm/mobile-app-ui-design) (MIT). They were translated to
Flutter, and the web-only values were removed.

---

## 1. Understand before designing
1. **What is the user trying to do on this screen?** Remove friction toward that one goal.
2. **How should it feel?** Trust (finance), calm (health), delight (learning), speed (productivity).
3. **What should they notice first?** That element gets the most visual weight.
4. **Who is the user right now?**
   - New user: simple welcome, guided setup, few options.
   - Returning user: personalized content, progress, quick re-entry.
   - Power user: denser info, shortcuts, advanced stats.

## 2. Layout & hierarchy
- **Thumb zone:** primary actions in the bottom third (bottom button, FAB, bottom sheet, bottom nav).
  Destructive or rare actions go out of easy reach (app bar overflow menu).
- **Reading order:** important info top-start, scanning down. In RTL, "start" means right.
- **Values over labels:** the number/name is big, the label is small and muted.
- **One primary button per screen.** Secondary actions are tonal/outlined/text buttons.
- **Expose, don't hide:** fewer taps beats a cleaner-looking screen that hides the key info.
- **Group with space, not lines:** use spacing first, then dividers only when spacing isn't enough.

## 3. Spacing — 4/8-point scale
- Allowed values: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64.
- **Relationship-based:** related items are close (label to value: 4–8), siblings are medium apart (12–16),
  and sections are far apart (24–32). The gap between groups is about 2× the gap inside a group.
- Screen side padding: 16 (dense apps) to 24 (calm apps), the same on every screen.
- Card internal padding: 16–24.
- Bigger text needs more space around it.
- With `flutter_screenutil`, apply the same scale with `.w` / `.h` / `.r`.

## 4. Typography
- One font family (two at most, each with a clear role).
- Per screen: about 4 sizes and 2–3 weights. Use `textTheme` roles: `headlineSmall`, `titleMedium`,
  `bodyMedium`, `labelLarge`, and so on.
- Make hierarchy with **size, weight and tone**. Don't make everything bold.
- Numbers (prices, balances, stats, timers): use tabular figures so they don't jump while changing.
- Arabic text needs a font with a good Arabic glyph set and slightly more line height. Check that
  the project's font actually covers Arabic. If it doesn't, Flutter falls back to a system font mid-sentence.

## 5. Color
- **60 / 30 / 10:** 60% neutral surfaces, 30% text and dark elements, 10% brand/accent for CTAs and key indicators.
- Text tones: primary text `onSurface`, secondary `onSurfaceVariant`, disabled about 38% opacity.
- Secondary buttons and highlights: a very light tint of the brand color, such as `primaryContainer`
  or the primary color at 8–12% alpha.
- Strong colors carry meaning. Red means error or destructive and nothing else; green means success.
  Overusing them kills the hierarchy.
- Design light and dark together. Every color should come from a role that has both variants.
- Use status colors with an icon or text, never color alone.

## 6. Shape, depth, imagery
- One radius scale (for example 8 / 12 / 16 / 24, plus full for pills), used consistently.
- Material 3: show elevation with tonal surfaces (`surfaceContainerLow` → `High`) and keep shadows minimal.
  If you use shadows, make them soft, large-blur and low-opacity, tinted toward the background hue.
- People: photo > initials > generic icon.
- Categories: soft colored backgrounds with clean, consistent icons or images. Keep one visual style across the app.
- Use real imagery or a consistent illustration set, not a mix of random stock photos.

## 7. Emotional design
### Peak-End rule
People remember the **most intense moment** and the **last moment** of an experience.
- **Map the flow** and find where stress peaks: waiting, payment, long forms, errors.
- **Design one peak** at the moment of value: task done, payment sent, goal reached. Use an animation,
  haptic feedback, and specific encouraging copy.
- **Design the end:** a summary or confirmation, what happens next, and a gentle reason to come back.
- **Soften negative peaks:** friendly error copy with a way forward, useful content during waits,
  and forms split into steps with progress.

### Feedback loops
- A correct or completed action gets a small celebration. A mistake gets a gentle, specific correction.
- Show progress with motion: progress bars that animate, streaks, completion counts.

### Consistency is the moat
- The same action looks and behaves the same way everywhere, with the same placement,
  wording and animation. Predictability builds habit and trust.

## 8. Industry conventions
Follow conventions for familiarity. Break them only on purpose.

| Domain | Typical language |
|---|---|
| Finance / banking / payments | Calm, trustworthy (often blue/neutral), lots of whitespace, big clear numbers, explicit confirmation steps, motion as a trust signal (smooth, never janky) |
| E-commerce / food / delivery | Big product photography, prominent price + CTA, frictionless checkout, trust signals (ratings, delivery time), visual order-tracking timeline |
| Tickets / events / booking | Clear date/time/venue hierarchy, seat/quantity selection over typing, a strong confirmation "ticket" moment, offline-readable tickets/QR |
| Health / wellness | Soft, approachable colors, friendly illustrations, gentle non-judgmental copy |
| Education | Bright, playful, character/feedback-driven, visible progress |
| Fitness | Energetic, bold numbers, progress and momentum |
| Productivity / business tools | Clean, dense but organized, strong grid, quick actions |
| AI products | Soft gradients/glow used sparingly, smooth motion for "thinking" states |

## 9. Anti-patterns
- Random spacing values off the scale.
- Too many font sizes or weights, or everything bold.
- Labels styled louder than values.
- More than one primary CTA competing for attention.
- CTAs at the top of long forms, outside the thumb zone.
- Generic empty states ("No data") with no next step.
- Sliders for precise or frequent input.
- Heavy gradients, blur and glassmorphism without a style that supports them.
- Harsh pure-black shadows, especially on colored backgrounds.
- Hardcoded light-mode colors that break in dark mode.
- `left` / `right` layout that breaks in RTL.
