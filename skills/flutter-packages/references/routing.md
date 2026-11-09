# Routing

**Universal:** one router per app. Add routes in the existing router file, using the same naming and
argument-passing style as existing routes. If the app mixes routers, use the one the current flow uses.

## Universal
- Don't mix `Navigator.push(MaterialPageRoute(...))` into a go_router / auto_route app unless that
  pattern already exists for the same case (e.g. dialogs, bottom sheets are fine with `Navigator`/`showDialog`).
- Pass IDs in the path/query, not whole objects, when the route must survive deep links / web refresh.
- Auth redirects live in the router (`redirect` / guards), not scattered `if (!loggedIn) push(login)` in widgets.
- Deep links (app_links, firebase dynamic links, notifications) must route through the same router.
- Android back / iOS swipe: use `PopScope` (not `WillPopScope`) and test it.

## go_router
- Check the major version — many breaking changes (v10 `state.uri`, v15 case-sensitive URLs, v18 requires Flutter ≥ 3.44).
- `context.go('/x')` replaces the stack (tabs, top-level destinations); `context.push('/x')` adds on top
  (details screens, flows that should pop back). Pick based on expected back behaviour.
- Read params: `state.pathParameters['id']`, `state.uri.queryParameters['q']`, `state.extra` (avoid `extra`
  for anything that must survive deep links / restoration).
- Bottom navigation with preserved tab state: `StatefulShellRoute.indexedStack`.
- Typed routes (`@TypedGoRoute`, `go_router_builder`) only if the project already uses them.
- Use named routes (`name:` + `context.goNamed`) if existing routes are named.

## auto_route
- Screens get `@RoutePage()`; routes go in the `@AutoRouterConfig()` class (`extends RootStackRouter`),
  then regenerate (`*.gr.dart`). Never edit generated route files.
- Navigate with generated route classes: `context.router.push(DetailsRoute(id: id))`.
- Guards: extend `AutoRouteGuard`. In auto_route ≥ 11, the guard method is `redirectUntil` (renamed) and
  several deprecated APIs (`navigateNamed`, `popForced`, `replaceNamed`, …) were removed — check the version.
- Tabs: `AutoTabsRouter` / `AutoTabsScaffold` if that's what the project uses.
