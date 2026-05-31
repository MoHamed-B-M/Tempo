import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'constants/app_colors.dart';
import 'services/alarm_service.dart';
import 'services/alarm_settings.dart';
import 'services/stopwatch_state.dart';
import 'services/theme_service.dart';
import 'services/update_manager.dart';
import 'widgets/home_page.dart';
import 'widgets/lock_screen.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final alarmService = AlarmService(notificationsPlugin);
  AlarmService.navigatorKey = navigatorKey;
  await alarmService.initialize();

  final themeService = ThemeService();
  await themeService.load();

  final alarmSettings = AlarmSettings();
  await alarmSettings.load();

  runApp(TempoApp(
    alarmService: alarmService,
    themeService: themeService,
    alarmSettings: alarmSettings,
  ));
}

class TempoApp extends StatelessWidget {
  final AlarmService alarmService;
  final ThemeService themeService;
  final AlarmSettings alarmSettings;

  const TempoApp({
    super.key,
    required this.alarmService,
    required this.themeService,
    required this.alarmSettings,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: alarmService),
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: alarmSettings),
        ChangeNotifierProvider(create: (_) => StopwatchState()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp(
            title: 'Tempo',
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            themeMode: themeService.mode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            home: const _AppShell(),
          );
        },
      ),
    );
  }

  static final _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: _NothingPageTransitionBuilder(),
      TargetPlatform.iOS: _NothingPageTransitionBuilder(),
    },
  );

  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.light(
      surface: AppColors.backgroundLight,
      onSurface: AppColors.primaryTextLight,
      primary: AppColors.primaryTextLight,
      onPrimary: AppColors.backgroundLight,
      secondary: AppColors.secondaryTextLight,
      onSecondary: AppColors.backgroundLight,
    );
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      useMaterial3: true,
      pageTransitionsTheme: _pageTransitionsTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.primaryTextLight,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceCardLight,
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.primaryTextLight,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.borderLight,
        thickness: 0.5,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.dark(
      surface: AppColors.backgroundDark,
      onSurface: AppColors.primaryTextDark,
      primary: AppColors.primaryTextDark,
      onPrimary: AppColors.backgroundDark,
      secondary: AppColors.secondaryTextDark,
      onSecondary: AppColors.backgroundDark,
    );
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      useMaterial3: true,
      pageTransitionsTheme: _pageTransitionsTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.primaryTextDark,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceCardDark,
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.primaryTextDark,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.borderDark,
        thickness: 0.5,
      ),
    );
  }
}

class _NothingPageTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        )),
        child: child,
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
      final alarmService = context.read<AlarmService>();
      alarmService.rescheduleAll();
      alarmService.processStoppedAlarms();
      alarmService.checkMissedAlarms();

      final sw = context.read<StopwatchState>();
      if (sw.isRunning && !_showingStopwatchLock) {
        _showStopwatchLockScreen();
      }
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
