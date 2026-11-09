# Examples

What LLMs commonly write in Flutter projects, and what the rules make them write instead.

---

## 1. Adding a package the project doesn't need

**Request:** "Add a screen that loads the user's orders."

**❌ Typical LLM output** — in a project that already uses `dio` + `flutter_bloc` + `get_it`:

```yaml
# pubspec.yaml
dependencies:
  http: ^0.13.5          # second HTTP client, invented old version
  provider: ^6.0.0       # second state-management solution
```

```dart
class OrdersProvider extends ChangeNotifier {
  List<Order> orders = [];
  Future<void> load() async {
    final res = await http.get(Uri.parse('https://api.example.com/orders')); // hardcoded URL
    orders = (jsonDecode(res.body) as List).map((e) => Order.fromJson(e)).toList();
    notifyListeners();
  }
}
```

**✅ With the rules** — copies the nearest existing feature:

```dart
// features/orders/data/orders_remote_data_source.dart — same shape as features/profile/...
@lazySingleton
class OrdersRemoteDataSource {
  OrdersRemoteDataSource(this._dio);          // the app's configured Dio (base URL, auth interceptor)
  final Dio _dio;

  Future<List<OrderModel>> getOrders() async {
    final res = await _dio.get<List<dynamic>>(ApiEndpoints.orders);
    return (res.data ?? const []).map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

// features/orders/presentation/cubit/orders_cubit.dart — Cubit, because the project uses Cubits
@injectable
class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit(this._repo) : super(const OrdersState.initial());
  final OrdersRepository _repo;

  Future<void> load() async {
    emit(const OrdersState.loading());
    final result = await _repo.getOrders();          // Either<Failure, List<Order>> like other repos
    if (isClosed) return;
    result.fold(
      (failure) => emit(OrdersState.error(failure.message)),
      (orders) => emit(OrdersState.loaded(orders)),
    );
  }
}
```

No new packages. Then: `build_runner build`, `flutter analyze`, done.

---

## 2. Using an API from the wrong version

**Request:** "Show a different widget for each result state." Project has `freezed 3.0.6`.

**❌ Typical LLM output** (from freezed 2.x memory):

```dart
@freezed
class Result with _$Result { ... }            // freezed 3 requires `sealed`/`abstract`

result.when(                                  // `when` doesn't exist in 3.0.x
  loading: () => const Loader(),
  data: (d) => DataView(d),
  error: (e) => ErrorView(e),
);
```

**✅ With the rules** — checks `pubspec.lock` → 3.0.6 → reads the CHANGELOG in `~/.pub-cache`:

```dart
@freezed
sealed class Result with _$Result {
  const factory Result.loading() = Loading;
  const factory Result.data(Data value) = DataResult;
  const factory Result.error(String message) = ErrorResult;
}

return switch (result) {
  Loading() => const Loader(),
  DataResult(:final value) => DataView(value),
  ErrorResult(:final message) => ErrorView(message),
};
```

---

## 3. BuildContext across an async gap

**❌**

```dart
onPressed: () async {
  await context.read<AuthCubit>().logout();
  Navigator.of(context).pushReplacementNamed('/login');   // widget may be gone; wrong router too
}
```

**✅**

```dart
onPressed: () async {
  await context.read<AuthCubit>().logout();
  if (!context.mounted) return;
  context.go(AppRoutes.login);                            // the app uses go_router
}
```

Even better if the project does it this way: a `BlocListener` that navigates on the `LoggedOut` state.

---

## 4. Deprecated APIs

**❌**

```dart
WillPopScope(
  onWillPop: () async => false,
  child: Container(color: Colors.black.withOpacity(0.4)),
)
```

**✅**

```dart
PopScope(
  canPop: false,
  child: ColoredBox(color: Colors.black.withValues(alpha: 0.4)),
)
```

The PostToolUse hook catches anything missed. It reports `deprecated_member_use` on the lines Claude just changed, and Claude fixes it right away.

---

## 5. Hardcoded strings and LTR-only layout (Arabic app)

**❌**

```dart
Padding(
  padding: const EdgeInsets.only(left: 16),
  child: Text('Total: $count items', textAlign: TextAlign.left),
)
```

**✅** (project uses `easy_localization`)

```dart
Padding(
  padding: const EdgeInsetsDirectional.only(start: 16),
  child: Text(LocaleKeys.cart_total_items.plural(count), textAlign: TextAlign.start),
)
```

Plus the key added to **both** `assets/translations/ar.json` and `en.json`, and `LocaleKeys` regenerated.

---

## 6. A permission feature that "works" but crashes on iOS

**Request:** "Let the user pick a profile photo."

**❌** Adds `image_picker`, writes the Dart code, says "done". The app crashes on iOS when the gallery opens
(missing `NSPhotoLibraryUsageDescription`).

**✅** Same Dart code, and:

```xml
<!-- ios/Runner/Info.plist -->
<key>NSPhotoLibraryUsageDescription</key>
<string>We use your photo library so you can choose a profile picture.</string>
<key>NSCameraUsageDescription</key>
<string>We use the camera so you can take a profile picture.</string>
```

Plus: "I couldn't run it on an iOS device — please test the picker on a real phone."

---

## 7. Surgical changes

**Request:** "Fix the price showing with too many decimals on the cart screen."

**❌** Changes the formatter, but also: converts the screen to a different widget structure, renames variables,
reorders imports, adds `const` to 40 unrelated lines, and runs `dart fix --apply` on the whole project.

**✅** One line:

```diff
- Text('${item.price}'),
+ Text(NumberFormat.currency(locale: context.locale.toString(), symbol: currency).format(item.price)),
```

Plus a test for the formatting, and a note: "`ProductCard` has the same issue — want me to fix it too?"
