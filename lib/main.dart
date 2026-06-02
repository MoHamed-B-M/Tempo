import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_theme.dart';
import 'core/hive_helper.dart';
import 'providers/alarm_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/timer_provider.dart';
import 'screens/main_screen.dart';
import 'services/alarm_service.dart';
import 'services/screen_wake_handler.dart';
import 'services/update_manager.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await HiveHelper.init();

  final alarmService = AlarmService(notificationsPlugin);
  AlarmService.navigatorKey = navigatorKey;
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
  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          title: 'Tempo',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          themeMode: themeMode,
          theme: AppTheme.light(dynamicColor: lightDynamic),
          darkTheme: AppTheme.dark(dynamicColor: darkDynamic),
          home: const _AppShell(),
        );
      },
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(alarmServiceProvider).processPendingAlarm();
      UpdateManager.checkAndShowUpdate(context, silent: true);
    });
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
    }
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
