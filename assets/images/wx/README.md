# Weather background images (immersive header)

Full-color, compressed `.webp` photos keyed by WMO weather-code bucket × day/night.
Resolved by the WMO→asset mapper in `core/widgets/app_widgets.dart`.

Expected filenames (buckets, both `_day` and `_night`):

- `clear_day.webp`, `clear_night.webp`
- `cloudy_day.webp`, `cloudy_night.webp`
- `fog_day.webp`, `fog_night.webp`
- `drizzle_day.webp`, `drizzle_night.webp`
- `rain_day.webp`, `rain_night.webp`
- `snow_day.webp`, `snow_night.webp`
- `thunder_day.webp`, `thunder_night.webp`

Keep each file small (target < 150 KB) to bound APK size. Source/license per
image should be recorded here. A missing image degrades gracefully to a
theme-colored gradient in `ImmersiveHeader`.
