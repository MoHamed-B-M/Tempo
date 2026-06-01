# Changelog

## [1.0.17] - 2026-06-01
- Added `m3e_core: ^0.1.0` dependency — Material 3 Expressive component library with spring animations, expressive shapes, and enhanced interaction patterns
- Rewrote AlarmsTab with M3E expandable card items (`buildM3EExpandableItem`) — spring‑powered expand/collapse animations, animated border‑radius morphing on hover/press, M3E expressive shape containers for empty state
- Replaced manual `FilledButton`, `OutlinedButton`, and `FloatingActionButton` with `M3EFilledButton`, `M3EOutlinedButton.icon`, and `M3EButton.icon` variants across AlarmsTab, SettingsPage, TimerTab, StopwatchTab, SleepTimerTab — M3E buttons feature spring‑driven radius morphing, configurable haptic feedback, and consistent M3 sizing tokens (xs/sm/md/lg/xl)
- Updated SettingsPage: channel toggle buttons migrated from custom `GestureDetector`+`AnimatedContainer` to `M3EButton.icon` with filled/outlined style switching, "Check for Updates" replaced with `M3EButton.icon` (filled, decorative)
- Updated TimerTab: START TIMER, reset, and start/pause controls replaced with `M3EFilledButton` / `M3EOutlinedButton` — consistent 18px border radius, fixed sizing, spring‑driven press feedback
- Updated StopwatchTab: flag/reset and start/pause buttons replaced with `M3EOutlinedButton` / `M3EFilledButton.icon` — dynamic background/border states for running vs. stopped
- Updated SleepTimerTab: "Skip" and "Next" buttons replaced with `M3EOutlinedButton` / `M3EFilledButton` — unified 16px border radius with theme accent color
- Verified with `flutter analyze` — 0 errors, 0 warnings
- Removed "by Mohamed" and GitHub source link from settings page footer; developer credit and repo link now live exclusively in the dedicated AboutPage
- Added release notes section to AboutPage showing the latest changelog entries inline
- Bumped version to 1.0.17

## [1.0.16] - 2026-05-31
- Added `AppTheme` class using `ColorScheme.fromSeed(seedColor: #F56D3B)` generating full M3 tonal palette with warm charcoal/off-white surfaces and orange primary; replaces inline `_buildLightTheme()` / `_buildDarkTheme()` in main.dart
- Split alarm architecture: `AlarmService` stripped to scheduling-only (no longer a `ChangeNotifier`); new `AlarmNotifier` (`ChangeNotifier`) owns alarm list state with `SharedPreferences` persistence and coordinates with `AlarmService` for scheduling. Provided via `Provider` + `ChangeNotifierProvider` in main.dart
- Rewrote alarms tab with Google Clock M3 design — 36px `HH:mm` digital clock display, M3 `Switch`, centered `FloatingActionButton` at bottom, `AnimatedSize` expansion revealing inline label/repeat/sound/delete panel with auto-commit on dispose, `Dismissible` swipe-to-delete with trash icon and animated background, `HapticFeedback.mediumImpact()` on all interactions, `SliverAppBar` pinned header with "Next alarm in..." status
- Created `AlarmNotifier` (`lib/services/alarm_notifier.dart`) with full CRUD, partial field updates (`updateAlarmLabel`, `updateAlarmRepeatDays`, `updateAlarmSound`), `disableAlarm` for notification stop callbacks
- Refactored `AlarmService` (`lib/services/alarm_service.dart`) — removed `_alarms`, `_loadAlarms`, `_saveAlarms`, `addAlarm`, `updateAlarm`, `removeAlarm`, `toggleAlarm`, `clearAllAlarms`. Kept scheduling, notification handlers, `stopAlarm`, `snoozeAlarm`, `processPendingAlarm`, `checkMissedAlarms(List<AlarmModel>)`, `fetchAndClearStoppedAlarms()`. Exposes `onStopFromNotification` callback wired to `AlarmNotifier.disableAlarm`
- Updated `alarm_ring_screen.dart` — uses `AlarmService.stopAlarm`/`snoozeAlarm` and `AlarmNotifier.disableAlarm` for one-shot dismiss
- Updated `sleep_timer_tab.dart` — uses `AlarmNotifier.addAlarm` instead of `AlarmService.addAlarm`
- Updated `home_page.dart` — streamlined to call `AlarmService.processPendingAlarm()` only (permission/schedule handled by notifier in lifecycle)
- Created dedicated AboutPage with app icon, version, description, developer/framework info rows, and tappable GitHub source link
- Added "About" navigation tile in settings page that opens AboutPage, styled with `surfaceContainerHigh` + `outlineVariant` from theme
- Removed unused AppColors and AppTextStyles imports from alarms_tab and main.dart; removed dead `_defaultColorScheme` field from AppTheme

## [1.0.15] - 2026-05-31
- Fixed notification stop button: added `_notifId()` / `_notifIdForDay()` helpers with `hashCode.abs()` for stable positive notification IDs; set `showsUserInterface: false` on stop action for silent background handling; added `_persistStopFlag()` backup persistence in foreground handler
- Refactored alarms tab with Material 3 expressive design — `Card` with elevation, `FilledButton`, `FloatingActionButton`, `InkWell` with proper ripple, notification active icon, enhanced empty state; all theme lookups now use sheet `ctx`
- Fixed lock screen full-screen intent: updated `MainActivity.kt` to use `setShowWhenLocked()` / `setTurnScreenOn()` (API 29+) with deprecation-safe fallback; calls `ScreenWakeHandler.enable()` before pushing routes
- Added comprehensive README with feature list, screenshot placeholders, tech stack, about section, and full release notes history
- Added 15 random inspirational time-themed quotes to settings page footer (persisted to SharedPreferences, changes on relaunch)
- Added about section in settings: developer credit ("by Mohamed") with clickable source code link to github.com/MoHamed-B-M/Tempo
- Verified no alarm-seeding logic exists in codebase — _loadAlarms only reads from SharedPreferences; removed dead code path that could have injected default alarms
- Added clearAllAlarms() method to AlarmService for safe data reset
- Fixed update check crash — added missing break statements in switch to prevent fall-through cascade to null release access
- Made version comparison case-insensitive for v/V prefix in tag_name
- Fixed bottom sheet using wrong BuildContext (ctx vs captured outer context)
- Added 15s timeout, explicit exception catching, and empty tag_name guard to update API call
- Adjusted alarm editor bottom sheet padding (viewInsets.bottom + padding.bottom + 80) to keep save button above floating nav bar
- Replaced glitchy stopwatch glow with soft grey animated pulse — reduced blur sigma 50→18, wrapped in RepaintBoundary, used AnimatedContainer for opacity transitions
- Added proper 'stop' action for notifications: background handler persists stop flags to SharedPreferences; foreground handler pops LockScreen via maybePop; processStoppedAlarms() applied on app resume
- Added 'Stop' action button to timer finish notification
- Added ScreenWakeHandler with method channel for FLAG_SHOW_WHEN_LOCKED / FLAG_TURN_SCREEN_ON / FLAG_KEEP_SCREEN_ON — LockScreen enables on init, disables on dispose
- Changed alarm editor default time from hardcoded 7:00 AM to TimeOfDay.now()
- Rewrote update checker to use /releases/latest endpoint — single release object, simpler parsing
- Replaced AlertDialog with bottom sheet for update available (version, release notes, Download button)
- Added floating snackbar for up-to-date status; improved error handling for all update check failure modes

## [1.0.12] - 2026-05-31
- Updated Android app icon — replaced launcher icons across all mipmap densities with new adaptive icon (foreground, background, monochrome)

## [1.0.11] - 2026-05-31
- Fixed alarm notification: added foreground detection (checkMissedAlarms on resume) to show lock screen when alarm fires while app is active
- Fixed cold-start alarm handling: getNotificationAppLaunchDetails + processPendingAlarm in HomePage post-frame callback
- Added onDidReceiveBackgroundNotificationResponse callback to handle notification taps from background isolate
- Removed orElse fallback to wrong alarm in _handleNotificationResponse; added proper null-safety throughout
- Added timer finish notification: TimerTab now shows a heads-up notification via flutter_local_notifications when countdown expires
- Replaced OrangeRingPainter solid arc/dot with glowing effect: blurred shadow arc behind ring, blurred glow circle behind position dot
- Fixed alarm save button: SnackBar now shown before Navigator.pop using outer stable context instead of sheetContext; removed empty catch block with proper error handling
- Fixed snooze action: now schedules a new notification 5 minutes from now instead of just re-enabling the alarm for its next scheduled time
- Fixed stop action for repeating alarms: replaced double-toggle fragility with dedicated _stopAlarm method that cancels current ring and reschedules next occurrence
- Added background notification handler: cancels notification sound in background isolate; schedules snooze notification 5 min ahead

## [1.0.10] - 2026-05-31
- Added AlarmSettings service with SharedPreferences persistence (auto-dismiss, vibrate, volume)
- Enhanced LockScreen: auto-dismiss countdown timer, conditional vibrate loop, adjustable volume, easeInOutCubic entry animation
- Enhanced SettingsPage: monochromatic alarm section with vibrate toggle, auto-dismiss picker, dot-matrix volume slider
- Fixed GestureDetector responsiveness: added HitTestBehavior.opaque to all tap targets in scrollable contexts
- Fixed nested GestureDetector conflict in alarm list (edit vs toggle checkmark)
- Fixed tab-switch debouncing to prevent rapid-switch animation stutter
- Increased small touch targets to 48px (day selector circles) for accessibility

## [1.0.8] - 2026-05-31
- Fixed alarm not ringing — replaced inexact with exact alarm scheduling
- Copied sound1.mp3 to Android raw resources for notification sound
- Added persistent looping alarm sound via audioplayers in AlarmRingScreen
- Added AudioAttributesUsage.alarm and Importance.max for proper alarm priority
- Replaced +/- 15min alarm time buttons with Nothing OS scroll-wheel TimePickerWheel
- Extracted OrangeRingPainter to shared widget, reused by StopwatchTab and TimerTab
- Fixed orange ring dot to always render at 12 o'clock position at 0ms
- Renamed bottom nav "Timer" → "Stopwatch" and replaced "Bedtimes" with "Timer"
- Created TimerTab — countdown timer with H/M/S input, circular ring, and finish sound
- Added "Show Nav Labels" setting to toggle icon-only / icon+label in bottom nav
- Added smooth sliding orange pill animation between nav items (Curves.easeInOutCubic)
- Added fade transition on tab content switching
- Fixed GitHub Actions release tag to follow pubspec.yaml version exactly
- Fixed GitHub Actions release notes to use current version's changelog section
- Added unified LockScreen widget with animated blur gradient background
- Added iOS-style slide-to-snooze / slide-to-stop control on lock screen
- Added circular stop button on lock screen for tap-to-dismiss
- Added notification action buttons: "Snooze 5min" and "Stop" for alarm notifications
- Added handler for notification action responses to support stop/snooze from notification shade
- Refactored AlarmRingScreen to use shared LockScreen widget
- Created StopwatchState ChangeNotifier for shared stopwatch state across app
- Added stopwatch lock screen: when app resumes and stopwatch is running, shows LockScreen with live elapsed time
- Stopwatch lock screen requires slide-to-stop to dismiss, preventing accidental stopwatch interruption

## [1.0.6] - 2026-05-31
- Restructured MainScreen with Scaffold bottomNavigationBar to prevent obscured buttons
- Redesigned StopwatchTab with orange ring CustomPainter — track arc plus adaptive position dot
- Replaced wavy circle with orange progress ring that follows current time position
- Added AnimationController for smooth ring transitions using Curves.easeInOutCubic
- Added lap recording functionality with horizontal scrollable lap list
- Fixed layout stability — all buttons use fixed SizedBox dimensions, no jumping on animation
- Added proper safe-area padding (MediaQuery bottom inset) for notched devices
- Removed stale test_check.dart scratch file
- Updated widget_test.dart to pass static analysis

## [1.0.5] - 2026-05-30
- Skipped — version aligned to match workflow iteration cadence

## [1.0.4] - 2026-05-29
- Redesigned the whole app with Nothing OS aesthetic (warm charcoal / off-white palette)
- Added alarm ring screen with animated gradient background
- Added sound picker bottom sheet with selection UI
- Added slide-to-snooze and slide-to-dismiss gesture control
- Fixed alarm toggle enable/disable not persisting across restarts
- Fixed alarm scheduling using zonedSchedule instead of periodicallyShow
- Added timezone database initialization for exact alarm scheduling
- Fixed notification tap handler — now navigates to alarm ring screen
- Added USE_FULL_SCREEN_INTENT permission for alarm heads-up notification
- Added edit alarm feature: tap alarm tile to modify time, sound, repeat, and label
- Added _selectedLabel field for alarm label editing in the picker flow
- Fixed alarm scheduling by adding flutter_native_timezone for correct IANA detection

## [1.0.3] - 2026-05-28
- Enabled ProGuard/R8 minification and resource shrinking
- Added ABI splits for smaller per-architecture APKs
- Added App Bundle (.aab) build alongside APK in CI
- Added --split-debug-info and --obfuscate to release builds
- Added proguard-rules.pro with Flutter-specific keep rules
- Fixed AGP Kotlin DSL build errors: signingConfigs, isMinifyEnabled, isShrinkResources
- Fixed R8 release build failure with expanded proguard rules and R8 full mode disabled
- Fixed missing Play Core classes in R8 (com.google.android.play.core.** keep + dontwarn)
- Created assets/audio/ directory to fix missing pubspec asset entry
- Made release signing config conditional on keystore file existence in build.gradle.kts
- Auto-generate release keystore with keytool if upload-keystore.jks does not exist
- Fixed artifact download by uploading full flutter-apk directory and finding APK dynamically
- Differentiated GitHub API rate limiting (403) from network errors in update check
- Fixed beta and release GitHub Actions workflows
- Fixed --strip flag in flutter build apk

## [1.0.2] - 2026-05-26
- Added Nothing OS themed time picker with half-wheel effect
- Added alarm list with swipe-to-delete and toggle switches
- Added dark/light theme toggle persisted to shared_preferences
- Added settings page with update channel selector
- Added in-app update checker with stable/beta channel support
- Added GitHub Actions CI for APK builds and beta prereleases
- Added animated page transitions with easeInOutCubic curve
- Added haptic feedback on interactions

## [1.0.1] - 2026-05-25
- Initial project setup with Flutter
- Added AlarmModel with JSON serialization
- Added AlarmService with shared_preferences persistence
- Added flutter_local_notifications for Android AlarmManager
- Added custom Nothing OS light/dark themes
- Added Android permissions for exact alarms and notifications
