import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../screens/main_screen.dart';
import '../services/alarm_service.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _initAlarmService();
  }

  Future<void> _initAlarmService() async {
    final service = context.read<AlarmService>();
    await service.requestExactAlarmPermission();
    await service.rescheduleAll();
  }

  @override
  Widget build(BuildContext context) {
    return const MainScreen();
  }
}
