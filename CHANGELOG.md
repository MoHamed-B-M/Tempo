# Changelog

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
