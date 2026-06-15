# Changelog
## [1.5.1] - 2026-06-14

### What's New
- Redesigned AboutPage with M3 Expressive cards — hero card with pill-shaped version badge, info chips (Open source / M3 Expressive / Mohamed), GitHub & Telegram action buttons, dynamic "What's New" section that reads changelog entries from CHANGELOG.md
- One-time "What's New" popup on app launch after update — detects version change via `last_seen_version` in Hive, displays changelog for the new version, supports both auto-check and manual update flows
- Replaced Plus Jakarta Sans and RobotoFlex with Nunito as the app-wide font — all ~140 `GoogleFonts` usages updated for a rounded, friendly M3 expressive look
- Simplified navigation bar — removed Pill, Minimal, Compact preset options; Bubble is now the only nav style. Removed settings toggle and 130-line preset selector

### Dynamic Color & Theming
- Created `DynamicThemeManager` with Hct tone-mapping (`material_color_utilities`) — clamps seed colours to tone 40 (light) / 75 (dark) for WCAG contrast, enforces minimum chroma 24
- Replaced static grey fallback (`#616161`/`#1A1A1A`) with premium green brand palette (`#2E7D32` light, `#66BB6A` dark)
- Wrapped `DynamicColorBuilder` in `FutureBuilder` with 16ms branded splash — eliminates null→dynamic colour flash
- Added `wallpaperRefreshProvider` + `lastWallpaperCheckProvider` for throttled wallpaper change detection (30s cooldown)
- Green-hue chroma boost (90–150° → chroma 52) prevents desaturated greens from OEM dynamic colour engines
- Added `CorePalette` pre-load in `_TempoAppState.initState()` via `DynamicColorPlugin.getCorePalette()`
- Customised M3 `SwitchThemeData` — active track uses primary, active thumb uses onPrimary
- Replaced single-toggle theme switcher with M3 `SegmentedButton<ThemeMode>` (Light / Dark / System)

### World Clock
- Extracted `TimezoneService` singleton — initializes IANA database once, provides `search(query)`, `cityName()`, `location()` helpers
- Created `SearchableTimezonePicker` bottom sheet — 150ms debounced search, `ListView.builder` for large timezone lists
- Extracted `WorldClockCard` with isolated `Timer.periodic(1s)` + `RepaintBoundary`
- Refactored `WorldClockTab` — delegates to extracted services, header clock isolated from list
- `WorldClockNotifier` persists favourites via Hive, defaults to New York / London / Tokyo

### Bubble Navigation
- Integrated animated bubble navigation bar — 4 presets (Bubble, Pill, Minimal, Compact) with per-preset `BubbleDecoration`
- Added `navStyleProvider` (Riverpod + Hive) for persistence across restarts
- Inlined `CustomBubbleNavBar` source into `lib/packages/animated_bubble_nav/` — removed CI path dependency
- Reduced universal APK size — targets `arm64-v8a` and `armeabi-v7a` only

### Settings
- Redesigned settings page with expressive card-based sections
- Added `ExpressiveSettingsTile` with icon background, navigation chevron
- Added dedicated AboutPage with developer credit, GitHub link, and dynamic release notes
- Added update channel selector (Stable / Beta) with Hive persistence

### Update System
- Created `version.json` manifest at project root matching `UpdateService` JSON schema
- Made `_fetchVersionJson` resilient — falls back to stale cache on network failure, writes default cache on first run
- Added channel-aware `checkForUpdate()` with `pub_semver` comparison
- Added `last_seen_version` tracking in Hive for one-time update changelog popup

### Build & CI
- Fixed "Gradle build failed to produce an .apk file" — removed custom Gradle build directory redirect that sent outputs to `<repo_root>/build`
- Fixed silent OOM in Gradle daemon — reduced JVM heap from `-Xmx8G` to `-Xmx4G` (GitHub Actions runner has 7GB RAM)
- Fixed R8 minification stripping plugin classes — comprehensive `-keep` rules for `flutter_timezone`, `connectivity_plus`, `hive`, `kotlinx.coroutines`
- Removed ABI splits — single universal APK matches Flutter tool's expected output pattern
- Added `--obfuscate --split-debug-info` flags with DWARF strip
- Updated beta CI workflow with Pub/Gradle caching, rolling `preview` tag, automatic changelog extraction
- Fixed APK lookup in CI — dynamic `find` pattern for version-suffixed filenames
- Updated AGP to 8.11.1, Kotlin to 2.2.20

### Bug Fixes
- Fixed `AlarmForegroundService.kt` — added missing `import android.content.BroadcastReceiver`
- Fixed `AlarmRingScreen` — removed redundant `ScreenWakeHandler.enable()` calls
- Fixed deprecated Color API: `color.value` → `color.toARGB32()`, `color.red/green/blue` → `color.r/g/b`
- Fixed `Icons.shrink` → `Icons.space_dashboard` (undefined icon constant)
- Fixed unused `services` import and `_buildSearchBox` variable in `world_clock_tab.dart`
- Fixed ABI build conflict — `ndk { abiFilters.clear() }` resolves plugin `ndk abiFilters` conflict

### Performance
- Added `const` keyword to 9 constructor invocations across `alarm_edit_page.dart`, `sleep_timer_tab.dart`, `timer_tab.dart`, `alarm_service.dart`
- `WorldClockCard` owns isolated `Timer.periodic(1s)` + `RepaintBoundary` — ticking never rebuilds parent
- Eliminated transition jank — `Clip.antiAliasWithSaveLayer` replaced with `OpenContainer` built-in clipping
- Deferred `AlarmEditPage` heavy widget building until after container transition completes

