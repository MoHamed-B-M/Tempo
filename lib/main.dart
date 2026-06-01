import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'services/alarm_notifier.dart';
import 'services/alarm_service.dart';
import 'services/alarm_settings.dart';
import 'services/screen_wake_handler.dart';
import 'services/stopwatch_state.dart';
import 'services/theme_service.dart';
import 'services/update_manager.dart';
import 'theme/app_theme.dart';
import 'widgets/home_page.dart';
import 'widgets/lock_screen.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final alarmService = AlarmService(notificationsPlugin);
  AlarmService.navigatorKey = navigatorKey;
  await alarmService.initialize();

  final alarmNotifier = AlarmStateNotifier(alarmService);
  await alarmNotifier.load();
  alarmService.onStopFromNotification = alarmNotifier.disableAlarm;

  final themeService = ThemeService();
  await themeService.load();

  final alarmSettings = AlarmSettings();
  await alarmSettings.load();

  runApp(TempoApp(
    alarmService: alarmService,
    alarmNotifier: alarmNotifier,
    themeService: themeService,
    alarmSettings: alarmSettings,
  ));
}

class TempoApp extends StatelessWidget {
  final AlarmService alarmService;
  final AlarmStateNotifier alarmNotifier;
  final ThemeService themeService;
  final AlarmSettings alarmSettings;

  const TempoApp({
    super.key,
    required this.alarmService,
    required this.alarmNotifier,
    required this.themeService,
    required this.alarmSettings,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: alarmService),
        ChangeNotifierProvider.value(value: alarmNotifier),
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: alarmSettings),
        ChangeNotifierProvider(create: (_) => StopwatchState()),
      ],
      child: DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          return Consumer<ThemeService>(
            builder: (context, themeService, _) {
              return MaterialApp(
                title: 'Tempo',
                debugShowCheckedModeBanner: false,
                navigatorKey: navigatorKey,
                themeMode: themeService.mode,
                theme: AppTheme.light(dynamicColor: lightDynamic),
                darkTheme: AppTheme.dark(dynamicColor: darkDynamic),
                home: const _AppShell(),
              );
            },
          );
        },
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> with WidgetsBindingObserver {
  bool _showingStopwatchLock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    final alarmNotifier = context.read<AlarmStateNotifier>();
    await alarmNotifier.scheduleAll();

    final stoppedIds = await context.read<AlarmService>().fetchAndClearStoppedAlarms();
    for (final id in stoppedIds) {
      alarmNotifier.disableAlarm(id);
    }

    alarmNotifier.checkMissedAlarms();

    final sw = context.read<StopwatchState>();
    if (sw.isRunning && !_showingStopwatchLock) {
      _showStopwatchLockScreen();
    }
  }

  void _showStopwatchLockScreen() {
    _showingStopwatchLock = true;
    final sw = context.read<StopwatchState>();
    final navigator = Navigator.of(context);
    final timeNotifier = ValueNotifier<String>(
      _formatStopwatchTime(sw.elapsedMs),
    );

    sw.addListener(() {
      timeNotifier.value = _formatStopwatchTime(sw.elapsedMs);
    });

    ScreenWakeHandler.enable();
    navigator.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LockScreen(
          mode: LockScreenMode.stopwatch,
          title: 'Stopwatch',
          timeDisplay: _formatStopwatchTime(sw.elapsedMs),
          liveTime: timeNotifier,
          showSnooze: false,
          onStop: () {
            _showingStopwatchLock = false;
            sw.stop();
            ScreenWakeHandler.disable();
            navigator.pop();
          },
        ),
      ),
    ).then((_) {
      _showingStopwatchLock = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}
