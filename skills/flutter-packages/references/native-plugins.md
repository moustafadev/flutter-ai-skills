# Native plugins (permissions, device features)

**Universal:** a plugin feature is not done until the native side is configured. Before finishing, read the
plugin's README "Setup" / "iOS" / "Android" sections in `~/.pub-cache/hosted/pub.dev/<pkg>-<version>/README.md`
and apply them. If you cannot edit/verify native files, list the exact lines the user must add.

## Checklist per feature
| Feature | iOS `Info.plist` | Android `AndroidManifest.xml` / Gradle |
|---|---|---|
| Camera / scanner (`image_picker`, `camera`, `mobile_scanner`) | `NSCameraUsageDescription` | `CAMERA` (if the plugin requires it) |
| Gallery (`image_picker`, `saver_gallery`) | `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription` (saving) | Android 13+ uses photo picker / `READ_MEDIA_IMAGES` — check plugin docs |
| Microphone (video, calls, `livekit_client`, `flutter_webrtc`) | `NSMicrophoneUsageDescription` | `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS` |
| Location (`geolocator`, `location`) | `NSLocationWhenInUseUsageDescription` (+ `Always…` only if truly needed) | `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` |
| Notifications (`flutter_local_notifications`, FCM) | capability + permission request | `POST_NOTIFICATIONS` (13+), channel setup |
| Open links / apps (`url_launcher`) | `LSApplicationQueriesSchemes` for custom schemes you check | `<queries>` intents for `canLaunchUrl` (Android 11+) |
| Deep links (`app_links`) | Associated Domains / URL types | intent filters + `autoVerify` |
| WebView (`webview_flutter`, `flutter_inappwebview`) | — | `INTERNET`; check `minSdk` |

Usage-description strings should explain *why* in user terms — App Store review rejects vague ones.
If the app is Arabic, also add localized `InfoPlist.strings` the way the project already does.

## permission_handler
- iOS: permissions must also be enabled via `GCC_PREPROCESSOR_DEFINITIONS` macros in `ios/Podfile`
  (e.g. `PERMISSION_CAMERA=1`) — otherwise the request silently returns denied. Check the existing Podfile.
- Flow: check `status` → `request()` → handle `granted` / `denied` / `permanentlyDenied` (offer `openAppSettings()`) /
  `limited` (iOS photos) / `restricted`.
- Don't request permissions at app start unless the project already does — request in context, when the feature is used.

## General
- Check `minSdk`, `compileSdk`, iOS deployment target (`ios/Podfile` `platform :ios`) against the plugin's requirements.
- After adding a plugin: full restart (not hot reload); on iOS `cd ios && pod install` may be needed.
- Wrap platform calls in try/catch for `PlatformException` and map to the project's failure type.
- Test on a real device for camera/location/push — simulators lie.
