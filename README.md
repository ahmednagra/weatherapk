# Changi AgriWeather — v2 (Flutter, Clean Architecture)

Premium agricultural pinpoint-weather app for **Village Changi, Daska, Sialkot** (32.145°N, 74.526°E). Five screens — Now, Hourly, 7-Day, Radar, Farm — built around real farm decisions: irrigate, spray, harvest, storm/frost/heat alerts. English + Urdu (RTL).

## What's new in v2

**Architecture** — full feature-first Clean Architecture per the project guidelines:

- **State:** Riverpod (`AsyncNotifier` for the forecast, `Notifier` for locale)
- **Routing:** GoRouter `StatefulShellRoute` (per-tab navigation state)
- **Network:** Dio (single configured client, logging interceptor)
- **Persistence:** Hive (forecast cache + learned bias + language)
- **Models:** immutable + Equatable, with DTO ↔ entity separation
- **Errors:** typed `Failure` hierarchy, `Result<T>` (no exceptions past the data layer)

```
lib/
  core/            constants · errors · network · router · services · theme · widgets · l10n
  features/
    weather/
      domain/      entities · repositories (interfaces) · usecases · services (bias maths)
      data/        models (DTOs) · datasources (Dio + Hive) · repositories (impl)
      presentation/ controllers (Riverpod) · providers (DI) · screens · widgets
    farm/
      domain/      farm decision rules + value types
      presentation/ farm screen
```

**Accuracy core** (this is what closes the gap with paid apps for *your* field):

- **Ground-truth bias correction** — learns the model's day/night temperature error against **OPST** (Sialkot airport METAR, ~13 km, 30-min reports) via a decaying-average filter and subtracts it. Persisted across launches.
- **Live "now"** — shows the actual OPST reading when fresh (≤90 min), labelled honestly vs forecast.
- **Multi-model blend** — temperature is the equal-weight mean of ECMWF/GFS/ICON/GEM, not a single model.
- **Honest confidence** — model-agreement bar hidden when unavailable (no fabricated %).
- **Agronomy** — ET₀ irrigation logic, GDD, buffered frost/heat alerts, livestock THI.
- **Layers** — NASA GIBS IMERG satellite-rain overlay (covers Pakistan) + GloFAS river-discharge flood watch (Chenab basin).

All data sources are **keyless and free** (Open-Meteo, NOAA AWC METAR, RainViewer, NASA GIBS). No API keys, no secrets.

## Build the APK

### On Codemagic (CI — recommended, no local toolchain needed)
The repo ships `lib/` + `pubspec.yaml` + the permissions manifest. `codemagic.yaml` scaffolds the Android platform, enables desugaring (for `flutter_local_notifications`), and builds the release APK. Connect the repo on codemagic.io → run the `android-release` workflow → download the APK artifact.

### Locally (if you have the Flutter SDK)
```bash
flutter create --org com.echooo --project-name changi_agriweather --platforms android .
flutter pub get
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```
`flutter create` skips existing files, so the provided `AndroidManifest.xml` (internet + notification permissions) is preserved. If the notifications plugin fails to compile, enable core-library desugaring in `android/app/build.gradle(.kts)` — see `codemagic.yaml` for the exact lines.

## Customising
- **Location / thresholds:** `lib/core/constants/api_constants.dart` (lat/lon) and `lib/features/farm/domain/farm_decisions.dart` (decision thresholds).
- **Colours / type / spacing:** `lib/core/theme/`.
- **Strings (EN/UR):** `lib/core/l10n/strings.dart`.

## Honest notes
- Forecasts are never 100% accurate — chaos caps useful skill at ~7–10 days. The bias correction + blend squeeze the real gains for a fixed point; the UI labels provenance rather than overclaiming.
- Pakistan has no public ground-radar feed, so the live precipitation layer is satellite QPE (~10 km, ~30–60 min), not street-level radar. Labelled as such.
- Built without a local compiler in the authoring environment — first CI build may surface a Gradle/SDK tweak (notifications desugaring is the likely one; handled in `codemagic.yaml`).
