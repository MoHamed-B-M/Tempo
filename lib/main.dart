import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_theme.dart';
import 'core/dynamic_theme_manager.dart';
import 'core/hive_helper.dart';
import 'providers/alarm_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/timer_provider.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/alarm_service.dart';
import 'services/foreground_service_handler.dart';
import 'services/screen_wake_handler.dart';
import 'services/update_manager.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Increment to force DynamicColorBuilder to re-mount and re-fetch platform
/// colors (e.g. after a wallpaper change).
final wallpaperRefreshProvider = StateProvider<int>((_) => 0);

/// Timestamp of the last wallpaper check — used to throttle refreshes.
final lastWallpaperCheckProvider = StateProvider<DateTime>(
  (_) => DateTime(2000),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await HiveHelper.init();

  final alarmService = AlarmService(notificationsPlugin);
  AlarmService.navigatorKey = navigatorKey;
  alarmService.onStopFromNotification = (alarmId) {
    debugPrint('[Main] Stop from notification — alarm $alarmId');
    navigatorKey.currentState?.maybePop();
  };
  await alarmService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        alarmServiceProvider.overrideWithValue(alarmService),
      ],
      child: const _TempoApp(),
    ),
  );
}

class _TempoApp extends ConsumerStatefulWidget {
  const _TempoApp();

  @override
  ConsumerState<_TempoApp> createState() => _TempoAppState();
}

class _TempoAppState extends ConsumerState<_TempoApp> {
  // Short splash delay so the platform channel can resolve before the first
  // real frame, preventing a null-dynamic-colour → dynamic-colour shift.
  static final _splashDone = Future<void>.delayed(
    const Duration(milliseconds: 16),
  );

  @override
  void initState() {
    super.initState();
    // Pre-load the raw CorePalette from the platform so the DynamicThemeManager
    // can cache a forced-extraction scheme before DynamicColorBuilder fires.
    _preloadCorePalette();

    ref.listen(themeModeProvider, (prev, next) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarIconBrightness:
              next == ThemeMode.light ? Brightness.dark : Brightness.light,
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness:
              next == ThemeMode.light ? Brightness.dark : Brightness.light,
        ),
      );
    });
  }

  /// Fetch the platform [CorePalette] early and feed it to the theme manager
  /// so schemes are cached before the first frame paints.
  Future<void> _preloadCorePalette() async {
    try {
      final cp = await DynamicColorPlugin.getCorePalette();
      if (!mounted || cp == null) return;
      // The manager's _forgeScheme only uses the hue, so we pass the primary
      // accent colour at tone 40 (standard light primary tone) as a seed.
      final seed = Color(cp.primary.get(40));
      DynamicThemeManager.instance.processLight(
        ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
      );
      DynamicThemeManager.instance.processDark(
        ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      );
    } catch (_) {
      // Platform channel failed — DynamicColorBuilder will retry later.
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final refreshKey = ref.watch(wallpaperRefreshProvider);

    return FutureBuilder<void>(
      future: _splashDone,
      builder: (context, snapshot) {
        final showApp = snapshot.connectionState == ConnectionState.done;

        return DynamicColorBuilder(
          // Unique key forces re-mount + re-fetch from the platform when
          // the wallpaper refresh counter increments.
          key: ValueKey(refreshKey),
          builder: (lightDynamic, darkDynamic) {
            final light =
                DynamicThemeManager.instance.processLight(lightDynamic);
            final dark =
                DynamicThemeManager.instance.processDark(darkDynamic);
            return MaterialApp(
              title: 'Tempo',
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey,
              themeMode: themeMode,
              theme: AppTheme.light(dynamicColor: light),
              darkTheme: AppTheme.dark(dynamicColor: dark),
              home: showApp ? const _AppShell() : const _SplashScreen(),
            );
          },
        );
      },
    );
  }
}

/// Brief branded splash shown while the platform dynamic-colour channel
/// resolves.  Uses the current (fallback or dynamic) theme seamlessly.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Text(
          'Tempo',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w200,
            color: cs.primary,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}

class _AppShell extends ConsumerStatefulWidget {
  const _AppShell();

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell>
    with WidgetsBindingObserver {
  bool _showingStopwatchLock = false;
  bool? _showOnboarding;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(alarmServiceProvider).processPendingAlarm();
      _checkBootReschedule();
      UpdateManager.checkAndShowUpdate(context, silent: true);
    });
    _checkOnboarding();
  }

  Future<void> _checkBootReschedule() async {
    final bootFlag = await ForegroundServiceHandler.checkBootCompleted();
    if (bootFlag) {
      debugPrint('[Main] Boot completed flag detected — rescheduling alarms');
      final alarmService = ref.read(alarmServiceProvider);
      final alarms = ref.read(alarmListProvider);
      await alarmService.rescheduleAll(alarms);
    }
  }

  void _checkOnboarding() {
    final complete =
        HiveHelper.settings.get('onboarding_complete', defaultValue: false)
            as bool;
    setState(() => _showOnboarding = !complete);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onResume();
      _checkWallpaperRefresh();
    }
  }

  Future<void> _checkWallpaperRefresh() async {
    const minInterval = Duration(seconds: 30);
    final lastCheck = ref.read(lastWallpaperCheckProvider);
    if (DateTime.now().difference(lastCheck) < minInterval) return;
    ref.read(lastWallpaperCheckProvider.notifier).state = DateTime.now();
    ref.read(wallpaperRefreshProvider.notifier).state++;
  }

  Future<void> _onResume() async {
    final alarmNotifier = ref.read(alarmListProvider.notifier);
    final alarmService = ref.read(alarmServiceProvider);

    alarmNotifier.sortAndUpdate();

    final stoppedIds = await alarmService.fetchAndClearStoppedAlarms();
    for (final id in stoppedIds) {
      alarmNotifier.disableAlarm(id);
    }

    alarmService.checkMissedAlarms(ref.read(alarmListProvider));

    final swState = ref.read(stopwatchProvider);
    if (swState.isRunning && !_showingStopwatchLock) {
      _showStopwatchLockScreen();
    }
  }

  void _showStopwatchLockScreen() {
    _showingStopwatchLock = true;
    final navigator = Navigator.of(context);

    ScreenWakeHandler.enable();
    navigator.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _StopwatchLockProxy(),
      ),
    ).then((_) {
      _showingStopwatchLock = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding == null) return const SizedBox.shrink();
    if (_showOnboarding!) return const OnboardingScreen();
    return const MainScreen();
  }
}

class _StopwatchLockProxy extends ConsumerWidget {
  const _StopwatchLockProxy();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = ref.watch(stopwatchProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatStopwatchTime(sw.elapsedMs),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w200,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(stopwatchProvider.notifier).stop();
                ScreenWakeHandler.disable();
                Navigator.of(context).pop();
              },
              child: const Text('STOP'),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatStopwatchTime(int ms) {
    final minutes = (ms ~/ 60000) % 60;
    final seconds = (ms ~/ 1000) % 60;
    final hundredths = (ms ~/ 10) % 100;
    final hours = ms ~/ 3600000;
    if (hours > 0) {
      final mins = (ms ~/ 60000) % 60;
      return '${hours}h ${mins.toString().padLeft(2, '0')}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${hundredths.toString().padLeft(2, '0')}';
  }
}
