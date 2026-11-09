# Networking

**Universal:** reuse the project's existing client instance, base URL, interceptors, and error type.
Never create a new `Dio()` / `http.Client()` per request or per repository.

## Universal
- Find how existing API calls are written (data source / service / repository) and copy the shape exactly:
  where the call lives, how JSON is parsed, how errors become failures (`Either<Failure, T>`, `Result`, exceptions).
- Base URLs, keys, and tokens come from the project's config/env/flavor setup — never hardcode them.
- Parse with the project's model approach (freezed/json_serializable/manual `fromJson`).
  Test the model against a real response sample when possible.
- Handle: no internet, timeout, 4xx with server message, 401 (token refresh/logout flow), 5xx, malformed JSON.
- Don't log tokens or full request bodies with personal data.

## dio (5.x)
- Exceptions are `DioException` with `DioExceptionType` (`connectionTimeout`, `receiveTimeout`,
  `badResponse`, `connectionError`, `cancel`, `unknown`). `DioError` / `DioErrorType` are the old 4.x names — don't use them.
- Error body: `e.response?.statusCode`, `e.response?.data`.
- Auth headers / refresh go in interceptors. For token refresh use `QueuedInterceptor` (or the project's existing
  interceptor) so parallel 401s don't refresh multiple times.
- Use `CancelToken` for searches / screens that can be left mid-request, if the project does.
- Use `queryParameters:` instead of building query strings by hand.
- Multipart: `FormData.fromMap({'file': await MultipartFile.fromFile(path, filename: name)})`.

## retrofit (+ dio)
- New endpoints go into the existing `@RestApi()` abstract class (or a new one following the same pattern):
  `factory XApi(Dio dio, {String? baseUrl}) = _XApi;` and `part 'x_api.g.dart';`.
- Use `@GET/@POST(...)`, `@Path`, `@Query`, `@Body`, `@Part`, `@Header` — match existing method styles
  (return `Future<Model>` vs `Future<HttpResponse<Model>>`).
- Regenerate with build_runner. Never edit `*.g.dart`.

## http
- `Uri.parse(...)` / `Uri.https(host, path, query)`; always set timeouts (`.timeout(...)`).
- `http` does not throw on 4xx/5xx — check `response.statusCode` yourself.
- Decode with `jsonDecode(utf8.decode(response.bodyBytes))` for non-ASCII (Arabic) responses.
- Reuse one `http.Client` and close it when its owner is disposed.

## WebSockets / realtime (web_socket_channel, pusher, socket.io, livekit…)
- Own the connection in one service, not in widgets. Expose a `Stream`.
- Cancel subscriptions and close channels on dispose / logout.
- Handle reconnect the way the project already does; don't add a second reconnection strategy.
