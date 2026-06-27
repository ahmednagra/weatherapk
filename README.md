# Changi AgriWeather — Android App (Flutter source)

A premium, animated, agricultural pinpoint-weather app for **Village Changi, Daska, Sialkot** (32.145°N, 74.526°E). Five screens — Now, Hourly, 7-Day, Radar, Farm — built around four farm decisions: **irrigate, spray, harvest, storm/flood risk.** Live data from Open-Meteo (free, no API key). English + Urdu (RTL). Local notifications. Offline caching.

> **This package is the complete Flutter source.** It compiles to an installable APK with one command (below). I could not produce the `.apk` binary itself in my environment because that requires the Android SDK + Gradle toolchain on a build machine — but everything is here and ready.

---

## What's included

```
changi_agriweather/
├── pubspec.yaml                 # dependencies
├── analysis_options.yaml
├── README.md                    # this file
├── lib/                         # the full app (20 Dart files)
│   ├── main.dart  app.dart
│   ├── theme/     (colors, theme, type)
│   ├── l10n/      (English + Urdu strings)
│   ├── models/    (weather data models)
│   ├── services/  (Open-Meteo, cache, notifications)
│   ├── logic/     (farm decision rules)
│   ├── widgets/   (rain canvas, CAPE ring, bars, dots, cards)
│   └── screens/   (5 screens + nav shell + icons)
└── android/app/src/main/AndroidManifest.xml   # permissions (internet, notifications)
```

The platform scaffolding (Gradle files, `MainActivity`, launcher icons) is intentionally **not** bundled, because those are version-specific and best generated fresh by your installed Flutter. Step 2 below generates them around this source in one command.

---

## Build the APK — step by step

### Prerequisites (one-time)
- Install **Flutter** (stable channel): https://docs.flutter.dev/get-started/install
- Install **Android Studio** (gives you the Android SDK + a device/emulator).
- Confirm your setup:
  ```bash
  flutter doctor
  ```
  Every line under "Android toolchain" should be a green check.

### Step 1 — unzip
Unzip this folder somewhere, e.g. `~/changi_agriweather`.

### Step 2 — generate the platform scaffolding around the source
From **inside** the unzipped folder:
```bash
cd changi_agriweather
flutter create --org com.echooo --project-name changi_agriweather .
```
This adds the `android/`, build files, `MainActivity`, and default launcher icons **without** touching the provided `lib/` or `pubspec.yaml`.

> It will print that some files already exist and were skipped — that's expected and correct.

### Step 3 — re-apply the permissions manifest
`flutter create` writes a fresh `AndroidManifest.xml`. Replace it with the one provided in this package so internet + notification permissions are set:
```bash
# from the project root
cp android/app/src/main/AndroidManifest.xml /tmp/agri_manifest_backup.xml   # optional backup of generated one
# then copy THIS package's manifest over the generated one:
#   (the provided manifest is the file you unzipped at
#    android/app/src/main/AndroidManifest.xml — if flutter create overwrote it,
#    restore it from the zip)
```
If `flutter create` overwrote the manifest, just open `android/app/src/main/AndroidManifest.xml` and ensure these three permission lines are present above `<application>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### Step 4 — get packages
```bash
flutter pub get
```
If any dependency version isn't found, run `flutter pub upgrade` to resolve to the latest compatible versions.

### Step 5 — run on a device (optional, to preview)
Plug in an Android phone with USB debugging on, or start an emulator, then:
```bash
flutter run
```

### Step 6 — build the release APK
```bash
flutter build apk --release
```
The installable file lands at:
```
build/app/outputs/flutter-apk/app-release.apk
```
Copy that `.apk` to any Android phone and install it (allow "install from unknown sources").

> Want a smaller download or Play Store upload? Use `flutter build apk --split-per-abi` (per-CPU APKs) or `flutter build appbundle` (AAB for Play Store).

---

## No-toolchain option (build in the cloud, free)

If you don't want to install Android Studio locally, push this project to GitHub and build the APK with a free CI runner:

- **Codemagic** (easiest for Flutter): connect the repo, pick "Flutter App", build → download the APK artifact.
- **GitHub Actions:** use the `subosito/flutter-action` action, then `flutter build apk --release`, and upload the APK as an artifact.

Either way the build command is identical to Step 6.

---

## How it works (for your developer)

- **Data:** `lib/services/weather_service.dart` makes two Open-Meteo calls — one "best match" call for the rich agricultural fields (CAPE, soil moisture, ET₀, VPD), and one multi-model call (ECMWF, GFS, ICON, GEM) for the comparison bars and the model-agreement %. No API key.
- **Caching:** `lib/services/cache_service.dart` stores the last good forecast as JSON via `shared_preferences`. On launch the app shows cached data instantly, then refreshes in the background. Pull-to-refresh on any screen forces an update.
- **Farm logic:** `lib/logic/farm_decisions.dart` holds the transparent, tunable rules for irrigation HOLD/GO, spray Safe/Marginal/Unsafe, harvest windows, storm alerts and urea timing — every output exposes the numbers behind it. Tune the thresholds at the top of that file.
- **Animations:** `rain_canvas.dart` (particle field scaling to precipitation), `cape_ring.dart` (animated gauge), `common_widgets.dart` (`AnimatedBar`, `PulsingDot`).
- **Radar:** `radar_screen.dart` pulls RainViewer's tile manifest and overlays the latest frame on a dark map. Ground-radar status is shown **honestly** (PMD Sialkot = feed gap, IMD Amritsar = upstream alternative).
- **Localization:** `lib/l10n/strings.dart` — English + Urdu maps. Urdu switches the whole UI to RTL automatically. Toggle via the globe icon on the Now screen.
- **Notifications:** `lib/services/notification_service.dart` fires local alerts (rain soon, high CAPE tonight, spray window open) when a fresh forecast is loaded.

### Background alerts (optional enhancement)
Notifications currently evaluate when the app refreshes in the foreground. For always-on alerts when the app is closed, add the [`workmanager`](https://pub.dev/packages/workmanager) package and call `NotificationService.evaluateAndNotify` from a periodic background task. This is the one piece that needs a device to test properly, so it's left as a clearly-marked extension.

---

## Customizing

- **Change the farm location:** edit `lat`, `lon`, `placeName` in `lib/app.dart` (`AppController`).
- **Tune decision thresholds:** top of `lib/logic/farm_decisions.dart` (CAPE high, soil healthy %, spray wind/rain limits).
- **Colors / fonts:** `lib/theme/app_colors.dart` and `lib/theme/app_theme.dart`.
- **App name shown under the icon:** `android/app/src/main/AndroidManifest.xml` (`android:label`).
- **Custom launcher icon:** add the `flutter_launcher_icons` package (optional).

---

## Honest notes

- I wrote and statically checked all the code, but I couldn't run the Android compiler here, so on first `flutter pub get` you may need a `flutter pub upgrade` if a plugin version has moved. The logic and structure are sound.
- NASA GPM IMERG satellite rainfall needs a free Earthdata login, so it's listed as a source but not wired as a live layer in v1 (RainViewer radar is the live overlay).
- Google Fonts fetches Space Grotesk + JetBrains Mono on first launch and caches them; if a device is fully offline on first run, it falls back to system fonts gracefully.
