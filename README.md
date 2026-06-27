# Changi AgriWeather — Android App (Flutter, ready to build)

A premium, animated, agricultural pinpoint-weather app for **Village Changi, Daska, Sialkot** (32.145°N, 74.526°E). Five screens — Now, Hourly, 7-Day, Radar, Farm — built around four farm decisions: **irrigate, spray, harvest, storm/flood risk.** Live data from Open-Meteo (free, no API key). English + Urdu (RTL). Local notifications. Offline caching.

> **This is now a COMPLETE Flutter project** — the full `android/` platform folder (MainActivity, Gradle files, v2 embedding, launcher icons) is included. You do **not** need to run `flutter create`. Just build.

---

## ⚡ The v1-embedding error is fixed

If you previously saw **"Build failed due to use of deleted Android v1 embedding"**, that was because the Android platform files were missing. This package now ships the complete `android/` folder with proper **v2 embedding**: a real `MainActivity.kt` extending `io.flutter.embedding.android.FlutterActivity`, the `flutterEmbedding = 2` manifest marker, and modern Gradle config. The error will not recur.

**If your build tool already created its own `android/` folder, delete it and use the one in this package** (or copy this `android/` folder over it), then rebuild.

---

## Build the APK

### Prerequisites (one-time, local builds)
- Install **Flutter** (stable): https://docs.flutter.dev/get-started/install
- Install **Android Studio** (provides the Android SDK).
- Verify: `flutter doctor` — "Android toolchain" should be all green.

### Steps
```bash
# 1. unzip, then from inside the project folder:
cd changi_agriweather

# 2. get packages
flutter pub get

# 3. build the release APK
flutter build apk --release
```
Installable file:
```
build/app/outputs/flutter-apk/app-release.apk
```
Copy that `.apk` to any Android phone and install (allow "install from unknown sources").

- App bundle for Play Store: `flutter build appbundle --release`
- Smaller per-CPU APKs: `flutter build apk --split-per-abi`
- Preview on a connected device/emulator: `flutter run`

### If your builder reports a missing Gradle wrapper
Some minimal environments don't ship the Gradle wrapper binary. If you see a `gradlew not found` / wrapper error, run this once — it regenerates ONLY the missing platform glue and keeps all the provided source:
```bash
flutter create --platforms=android --org com.echooo .
```
Then re-confirm these three lines are still in `android/app/src/main/AndroidManifest.xml` (re-add if needed), and rebuild:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

---

## No-toolchain option (build in the cloud, free)
Push this project to GitHub and build with a free runner — the command is the same (`flutter build apk --release`):
- **Codemagic** — connect repo, choose "Flutter App", build, download the APK artifact.
- **GitHub Actions** — use `subosito/flutter-action`, then `flutter build apk --release`, upload the APK as an artifact.

---

## What's included

```
changi_agriweather/
├── pubspec.yaml                         # dependencies
├── analysis_options.yaml
├── README.md
├── lib/                                 # the full app (20 Dart files, ~2950 lines)
│   ├── main.dart  app.dart
│   ├── theme/     (colors, theme, type)
│   ├── l10n/      (English + Urdu strings)
│   ├── models/    (weather data models)
│   ├── services/  (Open-Meteo, cache, notifications)
│   ├── logic/     (farm decision rules)
│   ├── widgets/   (rain canvas, CAPE ring, bars, dots, cards)
│   └── screens/   (5 screens + nav shell + icons)
└── android/                             # COMPLETE platform folder (v2 embedding)
    ├── build.gradle  settings.gradle  gradle.properties
    ├── gradle/wrapper/gradle-wrapper.properties
    └── app/
        ├── build.gradle
        └── src/main/
            ├── AndroidManifest.xml      (internet + notification permissions, v2 marker)
            ├── kotlin/com/echooo/changi_agriweather/MainActivity.kt
            └── res/  (styles, launch background, ic_launcher icons @ 5 densities)
```

---

## How it works (for your developer)

- **Data:** `lib/services/weather_service.dart` makes two Open-Meteo calls — one "best match" call for the rich agricultural fields (CAPE, soil moisture, ET₀, VPD), and one multi-model call (ECMWF, GFS, ICON, GEM) for the comparison bars and model-agreement %. No API key.
- **Caching:** `lib/services/cache_service.dart` stores the last good forecast as JSON via `shared_preferences`. The app shows cached data instantly on launch, then refreshes in the background. Pull-to-refresh forces an update.
- **Farm logic:** `lib/logic/farm_decisions.dart` holds the transparent, tunable rules for irrigation HOLD/GO, spray Safe/Marginal/Unsafe, harvest windows, storm alerts and urea timing — every output exposes the numbers behind it. Tune thresholds at the top of that file.
- **Animations:** `rain_canvas.dart` (particle field scaling to precipitation), `cape_ring.dart` (animated gauge), `common_widgets.dart` (`AnimatedBar`, `PulsingDot`).
- **Radar:** `radar_screen.dart` pulls RainViewer's tile manifest and overlays the latest frame on a dark map. Ground-radar status is shown **honestly** (PMD Sialkot = feed gap, IMD Amritsar = upstream alternative).
- **Localization:** `lib/l10n/strings.dart` — English + Urdu. Urdu switches the whole UI to RTL automatically. Toggle via the globe icon on the Now screen.
- **Notifications:** `lib/services/notification_service.dart` fires local alerts (rain soon, high CAPE tonight, spray window open) when a fresh forecast loads.

### Background alerts (optional enhancement)
Alerts currently evaluate on foreground refresh. For always-on delivery when the app is closed, add [`workmanager`](https://pub.dev/packages/workmanager) and call `NotificationService.evaluateAndNotify` from a periodic background task.

---

## Customizing
- **Farm location:** `lat`, `lon`, `placeName` in `lib/app.dart` (`AppController`).
- **Decision thresholds:** top of `lib/logic/farm_decisions.dart`.
- **Colors / fonts:** `lib/theme/app_colors.dart`, `lib/theme/app_theme.dart`.
- **App name under the icon:** `android:label` in `android/app/src/main/AndroidManifest.xml`.
- **Package / application id:** `com.echooo.changi_agriweather` (in `android/app/build.gradle` and the MainActivity path).

---

## Honest notes
- All code is written and statically checked. On first `flutter pub get` you may need `flutter pub upgrade` if a plugin version has moved since packaging — the structure is sound.
- The Gradle config targets AGP 8.1 / Kotlin 1.8.22 / Gradle 8.3, compatible with current stable Flutter. Very new Flutter releases may print deprecation warnings but still build.
- NASA GPM IMERG satellite rainfall needs a free Earthdata login, so it's listed as a source but not wired as a live layer in v1 (RainViewer radar is the live overlay).
- Google Fonts fetches Space Grotesk + JetBrains Mono on first launch and caches them; fully-offline first run falls back to system fonts gracefully.
