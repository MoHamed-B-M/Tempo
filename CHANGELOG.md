# Changelog

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
- Added AlarmSettings service with SharedPreferences persistence (auto-dismiss, vibrate, volume)
- Enhanced LockScreen: auto-dismiss countdown timer, conditional vibrate loop, adjustable volume, easeInOutCubic entry animation
- Enhanced SettingsPage: monochromatic alarm section with vibrate toggle, auto-dismiss picker, dot-matrix volume slider
- Fixed GestureDetector responsiveness: added HitTestBehavior.opaque to all tap targets in scrollable contexts
- Fixed nested GestureDetector conflict in alarm list (edit vs toggle checkmark)
- Fixed tab-switch debouncing to prevent rapid-switch animation stutter
- Increased small touch targets to 48px (day selector circles) for accessibility

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
