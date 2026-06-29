# Aqistat

**Living Weather Intelligence with Global Air-Quality Awareness.**

A modern, privacy-first Flutter weather app with a premium glassmorphism UI,
animated time-of-day backgrounds, and worldwide AQI support.

---

## Features

- Animated gradient sky that shifts with the time of day
- Glassmorphism (frosted glass) cards
- Hero temperature with live condition
- Glowing, color-coded AQI badge
- 24-hour hourly forecast scroll
- 7-day forecast with temperature bars
- Humidity / Wind / UV detail tiles
- "What to Wear" smart suggestions
- Settings, Privacy Policy, Terms of Service & About pages

---

## Setup

### 1. Get free API keys
- **OpenWeatherMap** → https://openweathermap.org/api
- **WAQI** → https://aqicn.org/data-platform/token/

### 2. Add your keys securely (never hardcoded)

Copy `env.example.json` to `env.json` and fill in your keys:

```json
{
  "OWM_KEY": "your_openweathermap_key",
  "WAQI_KEY": "your_waqi_token"
}
```

> `env.json` is git-ignored so your keys never get committed.

### 3. Run

```bash
flutter pub get
flutter run --dart-define-from-file=env.json
```

### 4. Build a release APK

```bash
flutter build apk --release --dart-define-from-file=env.json
```

---

## Security

This app is hardened for production:

| Protection | How |
|-----------|-----|
| **No hardcoded secrets** | API keys injected at build time via `--dart-define`, never in source |
| **HTTPS only** | Cleartext (HTTP) traffic blocked via network security config |
| **Code obfuscation** | R8/ProGuard shrinks + obfuscates release builds |
| **No data exfiltration** | No analytics, no ad trackers, no accounts |
| **Backup disabled** | App data excluded from cloud backup & device transfer |
| **Minimal permissions** | Only Internet + Location |
| **Log stripping** | Debug logs removed from release builds |
| **Local-only cache** | Weather data cached on-device, never uploaded |

---

## Tech Stack

- Flutter + Dart
- Riverpod (state management)
- Dio (networking)
- fl_chart (charts)
- OpenWeatherMap + WAQI APIs

---

## Privacy

Aqistat collects no personal data, has no accounts, and uses no trackers.
See the in-app Privacy Policy for full details.

---

## App Icon

A custom Aqistat icon (indigo-to-teal gradient with wind currents + AQI status dot)
is generated for all Android densities including adaptive icons.

To regenerate after changing the source art (`assets/icon/icon.png`):

```bash
dart run tool/make_icon.py   # regenerate the PNG art (needs Python + Pillow)
dart run flutter_launcher_icons   # generate all Android densities
```

---

## Hosted Privacy Policy (for Play Store)

The Google Play Console requires a public privacy policy URL. A ready-to-host
page lives in the `docs/` folder. Enable GitHub Pages to publish it for free:

1. Push this repo to GitHub
2. Go to your repo **Settings -> Pages**
3. Under "Build and deployment", set **Source = Deploy from a branch**
4. Choose branch **main** and folder **/docs**, then **Save**
5. Your privacy policy goes live at:
   `https://<your-username>.github.io/aqistat/`

Paste that URL into the Play Console "Privacy Policy" field during submission.
