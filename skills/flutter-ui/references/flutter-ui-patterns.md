# Flutter UI patterns

Reference code. **Use the project's equivalents first.** Use these only when the project has nothing for that job,
and adapt the names to the project's conventions.

## §1 Design tokens with ThemeExtension

Use this when the app has no token system. It keeps spacing and radius consistent, and lets custom colors work in dark mode.

```dart
import 'package:flutter/material.dart';

/// Spacing & radius scale — plain constants, usable in const contexts.
abstract final class AppSpacing {
  static const double xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32, xxxl = 48;
  static const screen = EdgeInsetsDirectional.symmetric(horizontal: lg);
}

abstract final class AppRadius {
  static const double sm = 8, md = 12, lg = 16, xl = 24;
}

/// Brand colors that ColorScheme has no role for (success, warning…), with light/dark values.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({required this.success, required this.onSuccess, required this.warning});

  final Color success;
  final Color onSuccess;
  final Color warning;

  static const light = AppColors(success: Color(0xFF1E8E3E), onSuccess: Colors.white, warning: Color(0xFFB26A00));
  static const dark = AppColors(success: Color(0xFF81C995), onSuccess: Color(0xFF00390F), warning: Color(0xFFFFB74D));

  @override
  AppColors copyWith({Color? success, Color? onSuccess, Color? warning}) => AppColors(
        success: success ?? this.success,
        onSuccess: onSuccess ?? this.onSuccess,
        warning: warning ?? this.warning,
      );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension AppThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF3355FF), brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    extensions: [brightness == Brightness.dark ? AppColors.dark : AppColors.light],
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
  );
}
// MaterialApp(theme: buildTheme(Brightness.light), darkTheme: buildTheme(Brightness.dark))
```

Check the extension names first. If the project already has `context.colors`-style extensions, don't add a second set.
`CardThemeData` is the current type for `ThemeData.cardTheme`. On older Flutter versions it was `CardTheme`,
so check the version.

## §2 One widget per state

Use this when the state holder exposes a status. Adapt it to the project's state shape: a sealed class,
a status enum, or `AsyncValue`.

```dart
class OrdersView extends StatelessWidget {
  const OrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: switch (state) {
          OrdersLoading() => const OrdersSkeleton(key: ValueKey('loading')),
          OrdersError(:final message) => ErrorView(
              key: const ValueKey('error'),
              message: message,
              onRetry: () => context.read<OrdersCubit>().load(),
            ),
          OrdersLoaded(:final orders) when orders.isEmpty => EmptyView(
              key: const ValueKey('empty'),
              icon: Icons.receipt_long_outlined,
              title: 'orders.empty.title'.tr(),
              actionLabel: 'orders.empty.cta'.tr(),
              onAction: () => context.push(AppRoutes.shop),
            ),
          OrdersLoaded(:final orders) => OrdersList(key: const ValueKey('data'), orders: orders),
        },
      ),
    );
  }
}
```

## §3 Empty and error views (only if the project has none)

```dart
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.icon, required this.title, this.message, this.actionLabel, this.onAction});

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: colors.onSurfaceVariant),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: text.titleMedium, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(message!, style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant), textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
// ErrorView = same layout with Icons.error_outline, the localized failure message, and a "Retry" action.
```

## §4 Skeleton loading without a package

```dart
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, required this.height, this.radius = AppRadius.sm});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

class OrdersSkeleton extends StatelessWidget {
  const OrdersSkeleton({super.key});

  @override
  Widget build(BuildContext context) => ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: AppSpacing.screen,
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, _) => const Row(
          children: [
            SkeletonBox(width: 48, height: 48, radius: AppRadius.md),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 14),
                  SizedBox(height: AppSpacing.sm),
                  SkeletonBox(width: 120, height: 12),
                ],
              ),
            ),
          ],
        ),
      );
}
```

If the project already uses `shimmer` or `skeletonizer`, use that instead.
The `(_, _)` wildcard parameters need Dart ≥ 3.7. On older SDKs, write `(_, __)`.

## §5 Button with in-progress state and haptic success

```dart
class SubmitButton extends StatelessWidget {
  const SubmitButton({super.key, required this.label, required this.loading, required this.onPressed});

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: loading ? null : onPressed,          // disabled while loading → no double submit
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: loading
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator.adaptive(strokeWidth: 2))
              : Text(label),
        ),
      );
}

// On the success state (e.g. in a BlocListener):
// HapticFeedback.mediumImpact();   // import 'package:flutter/services.dart';
```

A bottom action that stays above the home indicator and the keyboard:

```dart
Scaffold(
  body: ...,
  bottomNavigationBar: SafeArea(
    minimum: const EdgeInsets.all(AppSpacing.lg),
    child: SubmitButton(label: 'checkout.pay'.tr(), loading: state.isSubmitting, onPressed: _pay),
  ),
);
```

## §6 Responsive and adaptive

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final columns = switch (constraints.maxWidth) {
      < 600 => 1,
      < 900 => 2,
      _ => 3,
    };
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisExtent: 120),
      itemBuilder: ...,
    );
  },
);
```

- Read only what you need: `MediaQuery.sizeOf(context)`, `MediaQuery.paddingOf(context)` and
  `MediaQuery.viewInsetsOf(context)` instead of `MediaQuery.of(context)`, which causes extra rebuilds.
- Constrain wide content on tablets: `Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 600), child: ...))`.

## §7 Layout stress test

A widget test that catches overflow in small width, large text and RTL at the same time:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpStressed(WidgetTester tester, Widget child, {TextDirection dir = TextDirection.rtl}) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(2)),
      child: MaterialApp(
        theme: ThemeData(),            // use the app's real theme builder here
        home: Directionality(textDirection: dir, child: Scaffold(body: child)),
      ),
    ),
  );
  await tester.pump();
}

testWidgets('order card survives 320px + 2x text + RTL', (tester) async {
  await pumpStressed(tester, OrderCard(order: fakeOrder));
  expect(tester.takeException(), isNull);   // RenderFlex overflow shows up here
});
```

Wrap the widget with whatever it needs: the localization delegates, `ScreenUtilInit`, and `BlocProvider.value`.
Copy those from an existing widget test or a shared `pumpApp` helper.
