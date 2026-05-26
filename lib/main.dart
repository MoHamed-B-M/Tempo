import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'constants/app_colors.dart';
import 'services/alarm_service.dart';
import 'services/update_manager.dart';
import 'widgets/home_page.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final alarmService = AlarmService(notificationsPlugin);
  await alarmService.initialize();

  runApp(TempoApp(alarmService: alarmService));
}

class TempoApp extends StatelessWidget {
  final AlarmService alarmService;

  const TempoApp({super.key, required this.alarmService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: alarmService,
      child: MaterialApp(
        title: 'Tempo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            surface: AppColors.background,
            onSurface: AppColors.primaryText,
            primary: AppColors.primaryText,
            onPrimary: AppColors.background,
          ),
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: GoogleFonts.inter().fontFamily,
          useMaterial3: true,
        ),
        home: const _AppShell(),
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateManager.checkAndShowUpdate(context, silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}
