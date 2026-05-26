import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm_model.dart';

class AlarmService extends ChangeNotifier {
  static const _storageKey = 'alarms';
  static const _channelId = 'tempo_alarm_channel';
  static const _channelName = 'Alarm Notifications';

  final FlutterLocalNotificationsPlugin _notifications;
  List<AlarmModel> _alarms = [];
  bool _initialized = false;

  List<AlarmModel> get alarms => List.unmodifiable(_alarms);

  AlarmService(this._notifications);

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createNotificationChannel();
    await _loadAlarms();
    _initialized = true;
  }

  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Plays when an alarm triggers',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final list = jsonDecode(data) as List;
      _alarms = list
          .map((e) => AlarmModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_alarms.map((a) => a.toJson()).toList());
    await prefs.setString(_storageKey, data);
  }

  Future<AlarmModel> addAlarm({
    required int hour,
    required int minute,
    String sound = 'default',
    List<int> repeatDays = const [],
    String label = '',
  }) async {
    final alarm = AlarmModel(
      id: const Uuid().v4(),
      hour: hour,
      minute: minute,
      sound: sound,
      repeatDays: repeatDays,
      label: label,
    );
    _alarms.add(alarm);
    await _saveAlarms();
    await _scheduleAlarm(alarm);
    notifyListeners();
    return alarm;
  }

  Future<void> toggleAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final updated = _alarms[index].copyWith(enabled: !_alarms[index].enabled);
    _alarms[index] = updated;
    await _saveAlarms();
    if (updated.enabled) {
      await _scheduleAlarm(updated);
    } else {
      await _cancelAlarmNotification(updated);
    }
    notifyListeners();
  }

  Future<void> removeAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index == -1) return;
    await _cancelAlarmNotification(_alarms[index]);
    _alarms.removeAt(index);
    await _saveAlarms();
    notifyListeners();
  }

  Future<void> _scheduleAlarm(AlarmModel alarm) async {
    if (!alarm.enabled) return;

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.hour,
      alarm.minute,
    );

    if (alarm.isRepeating) {
      for (final day in alarm.repeatDays) {
        var nextDay = scheduledDate;
        while (nextDay.weekday != day) {
          nextDay = nextDay.add(const Duration(days: 1));
        }
        if (nextDay.isBefore(now)) {
          nextDay = nextDay.add(const Duration(days: 7));
        }
        await _scheduleRepeatingNotification(alarm.id, nextDay);
      }
    } else {
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      await _scheduleOneShotNotification(alarm.id, scheduledDate);
    }
  }

  Future<void> _scheduleOneShotNotification(
    String alarmId,
    DateTime date,
  ) async {
    final hour = DateFormat('HH:mm').format(date);
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Plays when an alarm triggers',
      importance: Importance.high,
      priority: Priority.high,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = alarmId.hashCode;
    await _notifications.periodicallyShow(
      id,
      'Tempo Alarm',
      'Alarm set for $hour',
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> _scheduleRepeatingNotification(
    String alarmId,
    DateTime date,
  ) async {
    final hour = DateFormat('HH:mm').format(date);
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Plays when an alarm triggers',
      importance: Importance.high,
      priority: Priority.high,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = alarmId.hashCode;
    await _notifications.periodicallyShow(
      id,
      'Tempo Alarm',
      'Alarm set for $hour',
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> _cancelAlarmNotification(AlarmModel alarm) async {
    await _notifications.cancel(alarm.id.hashCode);
  }

  void _onNotificationTap(NotificationResponse response) {}

  Future<void> rescheduleAll() async {
    for (final alarm in _alarms) {
      if (alarm.enabled) {
        await _scheduleAlarm(alarm);
      }
    }
  }

  Future<void> requestExactAlarmPermission() async {
    final plugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (plugin != null) {
      await plugin.requestExactAlarmsPermission();
    }
  }
}
