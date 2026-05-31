import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/main_screen.dart';
import '../services/alarm_service.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlarmService>().processPendingAlarm();
    });
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
