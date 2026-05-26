# Changelog

## [Unreleased]
- Added alarm ring screen with animated gradient background
- Added sound picker bottom sheet with selection UI
- Added slide-to-snooze and slide-to-dismiss gesture control
- Fixed alarm toggle enable/disable not persisting
- Fixed alarm scheduling using zonedSchedule instead of periodicallyShow
- Added timezone database initialization for exact alarm scheduling
- Enabled ProGuard/R8 minification and resource shrinking
- Added ABI splits for smaller per-architecture APKs
- Added App Bundle (.aab) build alongside APK in CI
- Added --split-debug-info and --obfuscate to release builds
- Added proguard-rules.pro with Flutter-specific keep rules
- Fixed notification tap handler navigates to alarm ring screen
- Removed stale test_check.dart scratch file
- Updated widget_test.dart to pass static analysis
- Fixed AGP Kotlin DSL build errors: signingConfigs, isMinifyEnabled, isShrinkResources
- Fixed R8 release build failure with expanded proguard rules and R8 full mode disabled
- Fixed missing Play Core classes in R8 (com.google.android.play.core.** keep + dontwarn)
- Created assets/audio/ directory to fix missing pubspec asset entry

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
