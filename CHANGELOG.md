# Changelog
## [preview] - 2026-06-13
- Extracted `TimezoneService` singleton — initializes IANA database once via `tz_data.initializeTimeZones()`, provides `search(query)`, `cityName()`, and `location()` helpers; eliminates redundant init on every tab visit
- Created `SearchableTimezonePicker` bottom sheet in `widgets/searchable_timezone_picker.dart` — 150ms debounced search via `Timer` prevents frame drops during typing, uses `ListView.builder` for large timezone lists, clear button in search field
- Extracted `WorldClockCard` into `widgets/world_clock_card.dart` — each card owns its own `Timer.periodic(1s)` and `RepaintBoundary` so ticking animations never rebuild the parent list or header clock
- Refactored `WorldClockTab` — delegates to `TimezoneService`, `SearchableTimezonePicker`, and `WorldClockCard`; header local clock uses its own `Timer.periodic` isolated from the list
- `WorldClockNotifier` persists favorites via Hive (`jsonEncode`/`jsonDecode`), defaults to New York/London/Tokyo
- Fixed ABI build conflict — added `ndk { abiFilters.clear() }` in `defaultConfig` to resolve `Conflicting configuration` error between plugin `ndk abiFilters` and `splits abi`
- Verified with `dart analyze` — 0 errors, 0 warnings

### Build & CI
- Fixed release build failure on CI (GitHub Actions) — removed custom Gradle build directory redirect from `android/build.gradle.kts` that sent outputs to `<repo_root>/build` instead of the default location, causing Flutter tool to report "Gradle build failed to produce an .apk file"
- Fixed silent OOM in Gradle daemon — reduced `org.gradle.jvmargs` heap from `-Xmx8G` to `-Xmx4G` in `android/gradle.properties` (GitHub Actions runners have 7GB RAM; 8G caused JVM thrashing)
- Fixed R8 minification stripping plugin classes loaded via reflection — replaced aggressive `-repackageclasses`/`-mergeinterfacesaggressively` flags with comprehensive `-keep` rules for `flutter_timezone`, `connectivity_plus`, `hive`, `kotlinx.coroutines`, and all `MethodChannel` handler base classes in `android/app/proguard-rules.pro`
- Removed outdated Gradle-level ABI splits (`splits { abi { ... } }`) and bundle config from `android/app/build.gradle.kts` — single universal APK now produced, matching Flutter tool's expected output pattern

### Performance
- Added `const` keyword to 9 constructor invocations across `alarm_edit_page.dart`, `sleep_timer_tab.dart`, `timer_tab.dart`, `alarm_service.dart` to reduce widget rebuild overhead
- `WorldClockCard` owns isolated `Timer.periodic(1s)` + `RepaintBoundary` — ticking animations never rebuild parent list or header clock

### World Clock
- Extracted `TimezoneService` singleton — initializes IANA database once via `tz_data.initializeTimeZones()`, provides `search(query)`, `cityName()`, and `location()` helpers; eliminates redundant init on every tab visit
- Created `SearchableTimezonePicker` bottom sheet in `widgets/searchable_timezone_picker.dart` — 150ms debounced search via `Timer` prevents frame drops during typing, uses `ListView.builder` for large timezone lists, clear button in search field
- Extracted `WorldClockCard` into `widgets/world_clock_card.dart` — each card owns its own `Timer.periodic(1s)` and `RepaintBoundary` so ticking animations never rebuild the parent list or header clock
- Refactored `WorldClockTab` — delegates to `TimezoneService`, `SearchableTimezonePicker`, and `WorldClockCard`; header local clock uses its own `Timer.periodic` isolated from the list
- `WorldClockNotifier` persists favorites via Hive (`jsonEncode`/`jsonDecode`), defaults to New York/London/Tokyo

### Bubble Navigation
- Integrated animated bubble navigation bar as drop-in replacement for default pill bar — 4 presets available (Bubble, Pill, Minimal, Compact) with toggle in Settings → APPEARANCE → Bubble Navigation
- Added `NavBarPreset` enum with per-preset `BubbleDecoration` configurations — circular (Bubble), rounded-square (Pill), transparent (Minimal), tight-spacing (Compact)
- Added `navStyleProvider` (Riverpod + Hive) — persists `useBubbleNav` boolean and `selectedPreset` index across restarts
- Inlined `CustomBubbleNavBar` source into `lib/packages/animated_bubble_nav/` — removed path dependency that failed in CI, fixed `BubbleShape.shape` getter by moving from extension to enum instance member
- Reduced universal APK size — removed `x86_64` from ABI splits and disabled `isUniversalApk` in `android/app/build.gradle.kts`, targeting only `arm64-v8a` and `armeabi-v7a` (~7-8MB per-ABI)

### Maintenance
- Fixed `Icons.shrink` → `Icons.space_dashboard` in `nav_style_provider.dart:34` (undefined icon constant)
- Removed unused `services` import from `world_clock_tab.dart:6` and unused `_buildSearchBox` variable on `world_clock_tab.dart:71` — `dart analyze` now passes with 0 errors

- Integrated animated bubble navigation bar as drop-in replacement for default pill bar — 4 presets available (Bubble, Pill, Minimal, Compact) with toggle in Settings → APPEARANCE → Bubble Navigation
- Added `NavBarPreset` enum with per-preset `BubbleDecoration` configurations — circular (Bubble), rounded-square (Pill), transparent (Minimal), tight-spacing (Compact)
- Added `navStyleProvider` (Riverpod + Hive) — persists `useBubbleNav` boolean and `selectedPreset` index across restarts
- Inlined `CustomBubbleNavBar` source into `lib/packages/animated_bubble_nav/` — removed path dependency that failed in CI, fixed `BubbleShape.shape` getter by moving from extension to enum instance member
- Reduced universal APK size — removed `x86_64` from ABI splits and disabled `isUniversalApk` in `android/app/build.gradle.kts`, targeting only `arm64-v8a` and `armeabi-v7a` (~7-8MB per-ABI)
- Verified with `dart analyze` — 0 errors, 0 warnings

## [preview] - 2026-06-12
- Created `DynamicThemeManager` with Hct tone-mapping (material_color_utilities) — clamps seed colours to tone 40 (light) / 75 (dark) for guaranteed WCAG contrast, enforces minimum chroma 24 to prevent muddy desaturated greys from low-quality wallpapers
- Replaced static grey fallback (`0xFF616161`/`0xFF1A1A1A`) with premium brand palette — rich deep teal (`0xFF005F56` light, `0xFF53C3B4` dark) for expressive appearance when dynamic colour is unavailable
- Wrapped `DynamicColorBuilder` in `FutureBuilder` with 16ms branded splash — eliminates null→dynamic colour flash by giving the platform channel time to resolve before the first real frame
- Added `wallpaperRefreshProvider` + `lastWallpaperCheckProvider` for throttled wallpaper change detection (30s cooldown) on app resume, with `ValueKey` forcing DynamicColorBuilder to re-mount and re-fetch platform colours
- Added `invalidateCache()` method to force fresh extraction when wallpaper changes
- Fixed `AlarmForegroundService.kt` — added missing `import android.content.BroadcastReceiver` to resolve `Unresolved reference BroadcastReceiver` and `'onReceive' overrides nothing` compilation errors
- Fixed `AlarmRingScreen` — removed redundant `ScreenWakeHandler.enable()` calls from `snooze()` and `dismiss()` (LockScreen already manages wake lock lifecycle via `initState`/`dispose`)
- Fixed deprecated Color API usage: replaced `color.value` with `color.toARGB32()`, `color.red/green/blue` with `color.r/g/b` (double 0–1)
- Verified with `dart analyze` — 0 errors, 0 warnings
- Customised M3 SwitchThemeData — active track uses `primary` (vibrant), active thumb uses `onPrimary` (high contrast); inactive track stays `surfaceContainerHighest` with `onSurfaceVariant` thumb
- Replaced single-toggle theme switcher with M3 `SegmentedButton<ThemeMode>` — three-segment horizontal group (Light / Dark / System) with expressive 14px rounded corners, removing manual `toggle()` cycling
- Removed unused `isDark` local variable from `settings_page.dart`
- Fixed update checker failing with "could not check for updates" — created `version.json` manifest at project root matching the `UpdateService` JSON schema (keys: `latest_stable_version`, `latest_stable_url`, `changelog_stable`, `latest_beta_version`, `latest_beta_url`, `changelog_beta`)
- Made `_fetchVersionJson` resilient: falls back to stale cache when the network request fails; writes a default cache entry on first run so subsequent checks never 404 immediately
- Provided app-size optimisation checklist: R8 minification/shrinking audit, asset re-encoding, unused package detection via `dart pub deps`, and `flutter build --obfuscate --split-debug-info`
- Rewrote `DynamicThemeManager._forgeScheme` — extracts **only the hue** from the platform dynamic seed, discards the OEM's chroma/tone (bypassing ColorOS/MIUI restrictions), and builds a fresh `ColorScheme.fromSeed` with guaranteed-vibrant chroma and WCAG-safe tone
- Added green-hue chroma boost (90–150° → chroma 52) — prevents the desaturated look that dynamic colour engines produce for wallpaper greens, keeping `primaryContainer` and `secondary` vibrant
- Replaced brand fallback from teal to explicit green hex: `#2E7D32` (light) / `#66BB6A` (dark)
- Added `CorePalette` pre-load in `_TempoAppState.initState()` via `DynamicColorPlugin.getCorePalette()` — primes the manager's cache before the first frame by extracting the primary accent at tone 40 from the raw platform palette
- Verified with `dart analyze` — 0 errors, 0 warnings

## [1.0.35] - 2026-06-04
- Eliminated transition jank in Card Transform animation — replaced expensive `Clip.antiAliasWithSaveLayer` with `OpenContainer`'s built-in clipping, removing GPU save‑layer bottleneck during scale
- Deferred `AlarmEditPage` heavy widget building (TextField, day selectors, dropdown, delete button) until after the container transition completes, preventing layout jank on the first animation frames
- Cached `TextEditingController` as a field instead of recreating it on every `build()` call
- Removed ABI splits from `build.gradle.kts` to resolve shrunk‑resources conflict with AAB builds
- Updated APK lookup globs in CI workflows for universal APK naming
- Rewrote beta CI workflow with Pub/Gradle caching, rolling `preview` tag, and automatic changelog extraction
## [1.0.32] - 2026-06-03
![Tempo v1.0.32](https://github.com/MoHamed-B-M/Tempo/blob/beta/android/releases/1.0.32.png)
- Implemented Material 3 Container Transform on alarm grid cards using `OpenContainer` from `animations` package
- Added reusable `ExpressiveOpenContainer` wrapper widget with configurable closed color, border radius, and transition duration
- Added full-screen `AlarmEditPage` replacing the old bottom-sheet editor — smooth scale-and-expand transition from card bounds to full screen
- Added `animations: ^2.0.0` dependency
- Removed legacy `_ExpandedAlarmPanel` expandable panel (dead code)
- Verified with `dart analyze` — 0 errors, 0 warnings

## [1.0.31] - 2026-06-03
![Tempo v1.0.31](https://github.com/MoHamed-B-M/Tempo/blob/beta/android/releases/1.0.31.png)
- Replaced app launcher icon across all densities (mdpi–xxxhdpi) for monochrome, foreground, background, and combined layers
- Reverted ABI build config to original: removed `ndk abiFilters` block, restored `x86_64` in splits and universal APK
- Verified with `dart analyze` — 0 errors, 0 warnings

## [1.0.30] - 2026-06-03
![Tempo v1.0.30](https://github.com/MoHamed-B-M/Tempo/blob/beta/android/releases/1.0.30.png)
- Fixed ABI build conflict: aligned `ndk abiFilters` with `splits abi` config by clearing Flutter plugin defaults and re-adding only `arm64-v8a` and `armeabi-v7a`
- Verified with `dart analyze` — 0 errors, 0 warnings

## [1.0.29] - 2026-06-03
- Refactored alarm grid cards with M3 Expressive container styling: distinct `primaryContainer` card background, `BorderRadius.circular(28)` expressive shape, improved inner padding
- Added optional `cardBackgroundColor` parameter to `_AlarmGridCard` for per-alarm custom card colors (falls back to `primaryContainer`)
- Disabled alarms now render at 45% opacity on the card color
- Build config: per-abi split APKs (`arm64-v8a`, `armeabi-v7a`), R8 minification + resource shrinking, ABI-split AAB support
- Verified with `dart analyze` — 0 errors, 0 warnings

## [1.0.27] - 2026-06-03
![Tempo v1.0.27](https://github.com/MoHamed-B-M/Tempo/blob/beta/android/releases/1.0.27.png)
- Replaced alarms full-width expandable card list with a 2-column `SliverGrid` of compact cards
- Each grid card shows `24px` time, label/repeat subtitle, and `Switch` toggle in a `ClipRRect` container with `20px` rounded corners
- Tap a grid card opens a bottom sheet with the full alarm editor (label, repeat days, sound, delete)
- Swipe-to-delete via `Dismissible(endToStart)` on each grid card
- Removed `DashboardScreen`; restored `AlarmsTab` as the primary tab with `Icons.alarm_outlined`
- Verified with `dart analyze` — 0 errors, 0 warnings

## [1.0.26] - 2026-06-03
![Tempo v1.0.26](https://github.com/MoHamed-B-M/Tempo/blob/beta/android/releases/1.0.26.png)
- Replaced traditional tab-based ListView with an expressive, non-uniform grid dashboard
- Added `DashboardScreen` with staggered card layout: wide Alarm card, geometric Clock card, World Clock card with abstract map painter, Timer with circular progress, and Stopwatch with media controls
- Capsule chip row (`Wake Up`, `Relax`, `Workout`, `Bloggers`) with active/inactive states using `AnimatedContainer`
- All cards use `M3EContainer.puffy` with pastel M3 container colors and extreme rounding (28dp+)
- Custom `_GeometricClockPainter` with concentric rings, geometric dot indices, and stylized clock hands
- Custom `_WorldMapPainter` with abstract continent blobs
- Wireframe stopwatch reads from existing `stopwatchProvider`; timer is self-contained with `_CircularProgressPainter`
- First tab re-themed to `Icons.grid_view_outlined`; World Clock, Stopwatch, and Timer detail tabs preserved
- Verified with `dart analyze` — 0 errors, 0 warnings

## [1.0.25] - 2026-06-02
![Tempo v1.0.25](https://github.com/MoHamed-B-M/Tempo/blob/beta/android/releases/1.0.25.png)
- Re-added immersive M3E onboarding flow (v1.0.25 revert was premature)
- Three-page `PageView` (Welcome → Expressive Interaction → Ready to Begin) with `SingleMotionBuilder` spring transitions
- First-launch gate via Hive `settings` box key `onboarding_complete`
- "Get Started" `M3EButton` with `M3EMotion.standardSpatialFast` and `M3EHapticFeedback.medium`
- Custom `StadiumBorder` page indicator with animated width
- Verified with `dart analyze` — 0 errors, 0 warnings
- Refactored main layout shell: unified `Scaffold(backgroundColor: cs.surface)` as single root background colour across all tabs — eliminates patchy dark/light container splits
- Made `SliverAppBar` in alarms tab transparent so `cs.surface` floods uninterrupted from top to bottom
- Added `android/releases/` to `.gitignore` to prevent tracking release screenshots
- Fixed release screenshot URL in changelog — changed from broken GitHub releases path to correct repo-relative path
- Verified with `dart analyze` — 0 errors, 0 warnings

## [1.0.24] - 2026-06-02
![Tempo v1.0.24](android/releases/1.0.24.png)
- Rebuilt `ThemeData.light()` with `ColorScheme.fromSeed(seedColor: Color(0xFF616161), brightness: Brightness.light)` for clean monochromatic light colours
- Added `navigationBarTheme`, `dialogTheme`, `bottomSheetTheme`, `switchTheme`, `filledButtonTheme`, `dividerTheme` to theme data
- Added reactive `SystemUiOverlayStyle` setter — dark status-bar icons in light mode, light icons in dark mode
- Replaced all remaining hardcoded `Colors.white`/`Colors.black` in UI text widgets with `colorScheme.onPrimary`/`colorScheme.onSurface` across settings, sleep timer, and FAB
- Replaced shadow `Colors.black` with `cs.shadow` in floating nav
- Fixed `navigationBarTheme.iconTheme` returning `Color` instead of `IconThemeData`
- Fixed `const SizedBox` containing non-const `CircularProgressIndicator` in settings update channel
- Removed `const` from sleep-timer `Icon(Icons.add, ...)` to allow dynamic theme colour
- Verified with `dart analyze` — 0 errors, 0 warnings

## [1.0.23] - 2026-06-02
- Fixed light mode theming — added explicit `brightness` to `ThemeData`, replaced all hardcoded `Colors.white` with `cs.onPrimary`
- Centered floating nav icons inside pill bar with `Center` widget wrapping `AnimatedScale`
- Raised FABs above floating nav bar — moved from `bottom: 24` to `bottom: 96`, increased scroll padding to 140
- Fixed distorted alarm card layout — added `crossAxisAlignment: CrossAxisAlignment.center` and `mainAxisSize: MainAxisSize.min` to header Row/Column
- Replaced `provider`/`shared_preferences` with `flutter_riverpod`/`hive` across all state layers
- Created Hive type adapter for `AlarmModel` with manual `TypeAdapter`
- Created Riverpod providers: `alarmListProvider`, `themeModeProvider`, `alarmSettingsProvider`, `stopwatchProvider`
- Removed `alarm_notifier.dart`, `alarm_settings.dart`, `theme_service.dart`, `stopwatch_state.dart`, `home_page.dart`, `constants/`
- Rewired `AlarmService`/`UpdateManager` from `SharedPreferences` to Hive box persistence
- Rewrote `sound_picker_sheet.dart` and `time_picker_wheel.dart` — replaced deleted `AppColors`/`AppTextStyles` with `Theme.of(context).colorScheme`
- Verified with `dart analyze` — 0 errors, 0 warnings

## [1.0.22] - 2026-06-01

## [1.0.21] - 2026-06-01
- Fixed edge-to-edge layout: added `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` in `main()`, refactored `MainScreen` with `extendBody: true`, transparent background, removed opaque header circle behind settings gear icon, replaced all `AppColors`/`AppTextStyles` references with `Theme.of(context).colorScheme`
- Fixed alarm card expand/collapse: wrapped `bodyBuilder` in `AnimatedSize` with `Curves.easeInOutCubic` as smooth fallback for M3E expandable state transitions
- Fixed OTA update checker: added `connectivity_plus` pre-check before API call, reduced timeout from 15s to 10s, added explicit `SocketException` and `TimeoutException` catch blocks with `debugPrint` logging for each failure mode, added new `noConnection` result type
- Fixed notification Stop button: added `debugPrint` log statements in both foreground and background notification handlers; created dedicated `tempo_timer_channel` with `'reset'` action for timer finish notifications; `_handleNotificationResponse` now cancels the notification immediately on stop/reset actions
- Rewrote World Clock tab: uses IANA timezone database from `timezone` package (offline-first), search filters all timezone IDs by city/region name, favorite cities persisted via `SharedPreferences`, `RepaintBoundary` per city card for efficient per-second timer ticks, `M3EContainer.gem` FAB, bold high-contrast monochromatic typography with `PlusJakartaSans`
- Verified with `flutter analyze` — 0 errors, 0 warnings

## [1.0.20] - 2026-06-01
- Fixed full-screen intent: added dedicated `AlarmActivity` with `showWhenLocked`/`turnScreenOn` flags in AndroidManifest, updated `MainActivity.kt` with `onNewIntent` override and method channels for alarm activity launch and permission management
- Added foreground service permissions (`FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SPECIAL_USE`) to AndroidManifest for reliable alarm triggering
- Removed problematic `taskAffinity=""` and `singleInstance` launch mode from MainActivity — full-screen intents now correctly launch the alarm screen from any app state
- Added `ScreenWakeHandler.launchAlarmActivity()`, `requestFullScreenIntentPermission()`, and `requestExactAlarmPermission()` method channels
- Added `AlarmService.ensureAlarmPermissions()` to request exact alarm and full-screen intent permissions on Android 14+
- Rewrote lock screen UI: replaced blurry gradient background with solid dark `M3EContainer.gem` card — crisp, high-contrast industrial M3E design with sharp time display, `M3EFilledButton` (red expressive dismiss), `M3EOutlinedButton` (snooze), subtle border and shadow
- Refactored alarm expandable panel for instant persistence: label changes save after 400ms debounce, repeat day toggles and sound selection commit immediately via `AlarmStateNotifier` — no more commit-on-dispose pattern
- Fixed OTA update checker with 3-attempt retry mechanism and exponential backoff; added explicit error logging via `debugPrint`; download button now prefers direct APK asset URL before falling back to release page
- Replaced all `AppColors`/`AppTextStyles` references in `update_manager.dart` with `Theme.of(context).colorScheme`
- Cleaned up unused fields in lock screen (`_slideOffset`, thresholds) and unused import in `update_manager.dart`
- Verified with `flutter analyze` — 0 errors, 0 warnings

## [1.0.19] - 2026-06-01
- Added `dynamic_color: ^1.8.0` dependency — Material You dynamic color theming with wallpaper-derived light/dark color schemes
- Added `state_notifier: ^1.0.0` dependency for state-layer alarm architecture (used as ChangeNotifier pattern for Provider compatibility)
- Rewrote `main.dart` with `DynamicColorBuilder` wrapping `MaterialApp` — color schemes passed to `AppTheme` and `MaterialApp.theme` / `darkTheme`
- Refactored `AppTheme` to accept optional `ColorScheme? dynamicColor` parameter — falls back to seeded `Color(0xFFF56D3B)` when dynamic colors unavailable
- Updated `ThemeService.toggle()` to cycle through light → dark → system modes, persisted via `SharedPreferences`
- Created `AlarmStateNotifier` (`lib/services/alarm_notifier.dart`) as a `ChangeNotifier` with `state`/`alarms` getters and full CRUD — replaces direct `AlarmService` mutation with a Provider-compatible state layer
- Rewrote `AlarmsTab` with `SliverM3EDismissibleCardList` + `buildM3EExpandableItem` — spring-powered expand/collapse, neighbor-pull swipe-to-dismiss, `M3EContainer.gem` FAB, `M3EDropdownMenu` for inline sound selection
- Replaced old sound picker bottom sheet in alarms tab with `M3EDropdownMenu<String>` — single-select, spring animations, haptic feedback
- Removed all `AppColors` references from `timer_tab.dart`, `stopwatch_tab.dart`, `sleep_timer_tab.dart`, and `settings_page.dart` — all containers, icons, and text now use `Theme.of(context).colorScheme` with dynamic palette
- Fixed alarm scheduling bug in `alarm_service.dart` — `DateTime.now()` seconds/milliseconds set to `0` so alarm triggers at the exact scheduled minute
- Fixed `flutter analyze` errors: replaced `BorderSide` with `Border.all()` in `BoxDecoration.border` across alarms tab, sleep timer tab, and settings page; replaced invalid `M3EHapticFeedback.selection` with `.light`
- Updated `AlarmRingScreen` to use `AlarmStateNotifier` for dismiss and disable actions
- Verified with `flutter analyze` — 0 errors, 0 warnings

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
