# Tempo

A minimalist, high-fidelity alarm clock app built with Flutter, featuring a warm Nothing OS aesthetic with a vibrant orange accent. Tempo combines essential timekeeping tools — alarms, stopwatch, timer — with an expressive Material 3 inspired design.

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
- Custom alarm label
- Multiple sound options
- Toggle on/off with a checkmark button
- Swipe-to-delete with animated dismiss
- Swipe-to-snooze / swipe-to-stop gesture on lock screen
- Notification action buttons: "Snooze 5min" and "Stop"
- Persistent scheduling using exact alarms (`exactAllowWhileIdle`)
- Heads-up notification with full-screen intent on Android

### Stopwatch
- Lap recording with horizontal lap list
- Animated time display with soft glow effect
- Task tracking with name, status, and progress percent
- Lock screen overlay when app resumes while stopwatch is running

### Timer
- H/M/S input selector with circular ring progress
- Finish notification with sound and "Stop" action button
- Persistent looping finish sound via `audioplayers`

### Lock Screen
- Animated HSV gradient background with blur overlay
- Pulsing alarm/timer icon
- Large time display (82px thin weight)
- iOS-style slide-to-snooze / slide-to-stop gesture control
- Circular stop button for tap-to-dismiss
- Auto-dismiss countdown timer
- Vibrate loop (every 2 seconds)
- Adjustable volume
- Screen wake on alarm: `FLAG_SHOW_WHEN_LOCKED` + `FLAG_TURN_SCREEN_ON` + `FLAG_KEEP_SCREEN_ON`

### Settings
- Dark/Light theme toggle
- Update channel selector (Stable / Beta)
- Check for updates via GitHub API (`/releases/latest`)
- Update available bottom sheet with Download button
- Auto-dismiss minutes picker (Off, 1, 2, 5, 10, 15, 30 min)
- Vibrate on alarm toggle
- Dot-matrix volume slider
- Inspirational quote displayed at the bottom (changes on relaunch)

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
- **State Management:** Provider (`ChangeNotifier`)
- **Notifications:** `flutter_local_notifications` 17.x
- **Audio:** `audioplayers` 6.x
- **Time Zones:** `flutter_timezone`, `timezone`
- **Fonts:** `google_fonts` (Plus Jakarta Sans)
- **HTTP:** `http` package
- **Persistence:** `shared_preferences`
- **APK Release:** GitHub Actions with ProGuard/R8, ABI splits, App Bundle

---

## About

| | |
|---|---|
| **Developer** | Mohamed |
| **Source Code** | [github.com/MoHamed-B-M/Tempo](https://github.com/MoHamed-B-M/Tempo) |
| **Current Version** | 1.0.14 |
| **License** | MIT |

---

## Release Notes

### [1.0.14] - 2026-05-31
- Fixed notification stop button: uses `abs()` hash for positive notification IDs, `showsUserInterface: false` for silent background stop, backup SharedPreferences persistence in foreground handler
- Refactored alarms tab with Material 3 expressive design: `Card` with elevation, `FilledButton`, `FloatingActionButton`, orange accent throughout, `AnimatedContainer` for toggle transitions
- Fixed lock screen full-screen intent: updated `MainActivity.kt` to use `setShowWhenLocked()` / `setTurnScreenOn()` (API 29+), calls `ScreenWakeHandler.enable()` before pushing route
- Added clearAllAlarms() method for safe data reset
- Added random inspirational quotes on settings page (changes on relaunch)
- Added about section with dev credit and source code link

### [1.0.13] - 2026-05-31
- Replaced stopwatch OrangeRingPainter and circular container with animated BackdropFilter glow behind clock text
- Pushed save/cancel buttons up in alarm editor bottom sheet with top padding for better reachability
- Changed alarm editor default time from hardcoded 7:00 AM to TimeOfDay.now()
- Rewrote update checker to use /releases/latest endpoint — single release object, simpler parsing
- Replaced AlertDialog with bottom sheet for update available (version, release notes, Download button)
- Added floating snackbar for up-to-date status; improved error handling for all update check failure modes

### [1.0.12] - 2026-05-31
- Updated Android app icon — replaced launcher icons across all mipmap densities with new adaptive icon

### [1.0.11] - 2026-05-31
- Fixed alarm notification: foreground detection (checkMissedAlarms on resume) to show lock screen when alarm fires while app is active
- Fixed cold-start alarm handling: getNotificationAppLaunchDetails + processPendingAlarm
- Added onDidReceiveBackgroundNotificationResponse callback
- Added timer finish notification
- Glowing ring effect for OrangeRingPainter
- Fixed alarm save button, snooze action, and stop action for repeating alarms

### [1.0.10] - 2026-05-31
- Added AlarmSettings service (auto-dismiss, vibrate, volume) with SharedPreferences persistence
- Enhanced LockScreen: auto-dismiss countdown, vibrate loop, adjustable volume
- Enhanced SettingsPage: monochromatic alarm section, dot-matrix volume slider
- Fixed touch responsiveness, nested GestureDetector conflicts, tab-switch debouncing

### [1.0.8] - 2026-05-31
- Fixed alarm not ringing — exact alarm scheduling with exactAllowWhileIdle
- Alarm sound via audioplayers with looping in AlarmRingScreen
- Nothing OS TimePickerWheel replacing +/- 15min buttons
- TimerTab with countdown timer, circular ring, and finish sound
- Unified LockScreen widget with animated gradient, slide-to-snooze/stop
- StopwatchState ChangeNotifier, stopwatch lock screen
- Notification action buttons: Snooze 5min and Stop
- Smooth sliding orange pill navigation, fade transitions, "Show Nav Labels" toggle

### [1.0.6] - 2026-05-31
- MainScreen with Scaffold bottomNavigationBar
- StopwatchTab with orange ring CustomPainter, lap recording
- Layout stability with fixed SizedBox dimensions
- Safe-area padding for notched devices

### [1.0.5] - 2026-05-30
- Version aligned to match workflow iteration cadence

### [1.0.4] - 2026-05-29
- Complete Nothing OS redesign (warm charcoal / off-white palette)
- Alarm ring screen with animated gradient background
- Sound picker and slide-to-snooze/dismiss gesture
- zonedSchedule for exact alarm scheduling
- Edit alarm feature (tap alarm tile to modify time, sound, repeat, label)

### [1.0.3] - 2026-05-28
- ProGuard/R8 minification, ABI splits, App Bundle support
- Split debug info and obfuscation for release builds
- Keystore auto-generation, fixed AGP Kotlin DSL build errors
- GitHub Actions: beta and release workflows

### [1.0.2] - 2026-05-26
- Nothing OS themed time picker with half-wheel effect
- Alarm list with swipe-to-delete and toggle switches
- Dark/light theme toggle, settings page with update channel selector
- In-app update checker, GitHub Actions CI for APK builds
- Animated page transitions with easeInOutCubic curve

### [1.0.1] - 2026-05-25
- Initial project setup with Flutter
- AlarmModel with JSON serialization
- AlarmService with shared_preferences persistence
- flutter_local_notifications for Android AlarmManager
- Custom Nothing OS light/dark themes
- Android permissions for exact alarms and notifications
