# Tempo

A minimalist, high-fidelity alarm clock app built with Flutter, featuring dynamic Material 3 colour extraction (Material You), expressive card-based UI, and a Nothing OS-inspired aesthetic with the Nunito rounded font family. Tempo combines essential timekeeping tools — alarms, stopwatch, timer, world clock — with a modern M3 expressive design language.

<p align="center">
  <img src="screenshots/alarms_tab.png" width="200" alt="Alarms Tab">
  <img src="screenshots/stopwatch_tab.png" width="200" alt="Stopwatch Tab">
  <img src="screenshots/timer_tab.png" width="200" alt="Timer Tab">
  <img src="screenshots/lock_screen.png" width="200" alt="Lock Screen">
</p>

---

## Features

### Alarms
- Create, edit, and delete alarms with an intuitive bottom sheet editor
- Time picker wheel with smooth inertial scrolling
- Repeat on specific days of the week
- Custom alarm label and multiple sound options
- Swipe-to-delete with animated dismiss
- Swipe-to-snooze / swipe-to-stop gesture on lock screen
- Notification action buttons: "Snooze 5min" and "Stop"
- Persistent scheduling using exact alarms (`exactAllowWhileIdle`)
- Heads-up notification with full-screen intent on Android
- Alarm grid cards with M3 Container Transform animation

### Stopwatch
- Lap recording with horizontal lap list
- Animated time display with soft glow effect
- Task tracking with name, status, and progress percent
- Lock screen overlay when app resumes while stopwatch is running

### Timer
- H/M/S input selector with circular ring progress
- Finish notification with sound and "Stop" action button
- Persistent looping finish sound via `audioplayers`
- Sleep timer tab with customizable duration

### World Clock
- Searchable timezone picker with 150ms debounced search
- Favourite cities persisted via Hive (defaults: New York, London, Tokyo)
- Each city card has isolated `Timer.periodic(1s)` + `RepaintBoundary`
- Header local clock with independent tick timer

### Lock Screen
- Animated HSV gradient background with blur overlay
- Pulsing alarm/timer icon
- Large time display (82px thin weight)
- iOS-style slide-to-snooze / slide-to-stop gesture control
- Circular stop button for tap-to-dismiss
- Auto-dismiss countdown timer
- Vibrate loop (every 2 seconds) and adjustable volume
- Screen wake: `FLAG_SHOW_WHEN_LOCKED` + `FLAG_TURN_SCREEN_ON` + `FLAG_KEEP_SCREEN_ON`

### Settings
- Theme mode selector: Light / Dark / System (`SegmentedButton`)
- Bubble navigation bar (always on, circular animated style)
- Update channel selector (Stable / Beta)
- Check for updates via GitHub manifest with one-time "What's New" popup
- Auto-dismiss minutes picker (Off, 1, 2, 5, 10, 15, 30 min)
- Vibrate on alarm toggle and dot-matrix volume slider
- Dedicated About page with dynamic changelog from CHANGELOG.md

### Dynamic Color (Material You)
- Android 12+ wallpaper-based colour extraction via `dynamic_color` package
- Hct tone-mapping with chroma boost — green hues forced to chroma 52 for vibrancy
- WCAG-safe contrast: light tone clamped to 40, dark tone clamped to 75
- Green brand fallback (`#2E7D32` light / `#66BB6A` dark) when dynamic colour unavailable
- Throttled wallpaper change detection (30s cooldown) with automatic refresh

---

## Screenshots

<p align="center">
  <i>Screenshots go here. Place your PNG files in the <code>screenshots/</code> directory with the following filenames:</i>
</p>

| Screen | File |
|--------|------|
| Alarms Tab | `screenshots/alarms_tab.png` |
| Stopwatch Tab | `screenshots/stopwatch_tab.png` |
| Timer Tab | `screenshots/timer_tab.png` |
| Lock Screen (Alarm) | `screenshots/lock_screen.png` |
| Alarm Editor Sheet | `screenshots/alarm_editor.png` |
| Settings Page | `screenshots/settings.png` |
| World Clock Tab | `screenshots/world_clock.png` |
| Dark Theme | `screenshots/dark_theme.png` |
| Light Theme | `screenshots/light_theme.png` |

---

## Tech Stack

- **Framework:** Flutter 3.41+
- **Language:** Dart 3.x
- **State Management:** Riverpod 2.x (`flutter_riverpod`)
- **Notifications:** `flutter_local_notifications` 17.x
- **Audio:** `audioplayers` 6.x
- **Time Zones:** `flutter_timezone`, `timezone`, `tz_data`
- **Fonts:** `google_fonts` (Nunito)
- **HTTP:** `http` package
- **Persistence:** Hive + Hive Flutter
- **Dynamic Color:** `dynamic_color` 1.x, `material_color_utilities`
- **Animations:** `flutter_animate`, `animations`, `motor`
- **Navigation:** Custom animated bubble nav bar
- **Layout:** M3 Expressive with theme extensions
- **APK Release:** GitHub Actions with ProGuard/R8, obfuscation, single universal APK

---

## About

| | |
|---|---|
| **Developer** | Mohamed |
| **Source Code** | [github.com/MoHamed-B-M/Tempo](https://github.com/MoHamed-B-M/Tempo) |
| **Current Version** | 1.5.1 |
| **Design** | Material 3 Expressive + Nothing OS inspired |
| **License** | MIT |

---

## Release Notes

### [1.5.1] - 2026-06-14

**What's New**
- Redesigned AboutPage with M3 Expressive cards — version badge, info chips, GitHub & Telegram action buttons, dynamic changelog from CHANGELOG.md
- One-time "What's New" popup on first launch after update — shows changelog for the new version, works for both auto-checks and manual updates
- Replaced Plus Jakarta Sans and RobotoFlex with Nunito — rounded, friendly M3 expressive font across all ~140 text elements
- Bubble is now the only navigation style — removed Pill, Minimal, Compact presets and settings toggle

**Dynamic Color**
- `DynamicThemeManager` with Hct tone-mapping enforces WCAG contrast (tone 40/75)
- Green brand fallback (`#2E7D32` / `#66BB6A`) with green-hue chroma boost (90–150° → chroma 52)
- Wallpaper change detection with 30s throttle and automatic refresh
- `SegmentedButton<ThemeMode>` for Light/Dark/System switching
- Custom M3 SwitchThemeData with primary track and onPrimary thumb

**World Clock**
- `TimezoneService` singleton — IANA database initialized once
- `SearchableTimezonePicker` with 150ms debounced search
- `WorldClockCard` with isolated 1s timer + `RepaintBoundary`
- Favourites persisted via Hive (New York / London / Tokyo)

**Build & CI**
- Fixed "Gradle build failed to produce an .apk file" — removed custom build directory redirect
- Fixed Gradle OOM — reduced JVM heap from 8G to 4G
- Fixed R8 stripping plugin classes — comprehensive ProGuard keep rules
- Single universal APK with obfuscation and split debug info
- CI workflows with Pub/Gradle caching and rolling preview releases

**Bug Fixes**
- Fixed `AlarmForegroundService.kt` — missing `BroadcastReceiver` import
- Fixed `AlarmRingScreen` — redundant `ScreenWakeHandler.enable()` removed
- Fixed deprecated Color API: `value` → `toARGB32()`, `red/green/blue` → `r/g/b`
- Fixed ABI build conflict — `ndk { abiFilters.clear() }`
