import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';
import '../models/alarm_model.dart';
import '../screens/alarm_ring_screen.dart';

class AlarmService extends ChangeNotifier {
  static const _storageKey = 'alarms';
  static const _channelId = 'tempo_alarm_channel';
  static const _channelName = 'Alarm Notifications';

  static GlobalKey<NavigatorState>? navigatorKey;

  final FlutterLocalNotificationsPlugin _notifications;
  List<AlarmModel> _alarms = [];
  bool _initialized = false;

  List<AlarmModel> get alarms => List.unmodifiable(_alarms);

  AlarmService(this._notifications);

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    await _detectLocalTimezone();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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

  Future<void> _detectLocalTimezone() async {
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
      } catch (_) {}
    }
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

  Future<void> updateAlarm({
    required String id,
    required int hour,
    required int minute,
    String sound = 'default',
    List<int> repeatDays = const [],
    String label = '',
  }) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final updated = _alarms[index].copyWith(
      hour: hour,
      minute: minute,
      sound: sound,
      repeatDays: repeatDays,
      label: label,
    );
    _alarms[index] = updated;
    await _saveAlarms();
    await _cancelAlarmNotification(updated);
    if (updated.enabled) {
      await _scheduleAlarm(updated);
    }
    notifyListeners();
  }

  Future<void> toggleAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final updated = _alarms[index].copyWith(enabled: !_alarms[index].enabled);
    _alarms[index] = updated;
    await _saveAlarms();
    await _cancelAlarmNotification(updated);
    if (updated.enabled) {
      await _scheduleAlarm(updated);
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
      now.second,
      now.millisecond,
    );

    if (alarm.isRepeating) {
      await _scheduleRepeatingNotifications(alarm, scheduledDate, now);
    } else {
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      await _scheduleOneShot(alarm, scheduledDate);
    }
  }

  AndroidNotificationDetails _buildAndroidDetails(String sound) {
    final soundName = sound != 'default' ? 'alarm_$sound' : null;
    return AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Plays when an alarm triggers',
      importance: Importance.high,
      priority: Priority.high,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      sound: soundName != null
          ? RawResourceAndroidNotificationSound(soundName)
          : null,
    );
  }

  Future<void> _scheduleOneShot(
    AlarmModel alarm,
    DateTime date,
  ) async {
    final androidDetails = _buildAndroidDetails(alarm.sound);
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.zonedSchedule(
      alarm.id.hashCode,
      'Tempo Alarm',
      alarm.label.isNotEmpty ? alarm.label : 'Alarm',
      tz.TZDateTime.from(date, tz.local),
      details,
      payload: alarm.id,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _scheduleRepeatingNotifications(
    AlarmModel alarm,
    DateTime scheduledDate,
    DateTime now,
  ) async {
    final androidDetails = _buildAndroidDetails(alarm.sound);
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    if (alarm.repeatDays.length == 7) {
      await _notifications.zonedSchedule(
        alarm.id.hashCode,
        'Tempo Alarm',
        alarm.label.isNotEmpty ? alarm.label : 'Alarm',
        tz.TZDateTime.from(scheduledDate.isBefore(now)
            ? scheduledDate.add(const Duration(days: 1))
            : scheduledDate,
            tz.local),
        details,
        payload: alarm.id,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else {
      for (final day in alarm.repeatDays) {
        var nextDate = DateTime(
          now.year,
          now.month,
          now.day,
          alarm.hour,
          alarm.minute,
        );
        while (nextDate.weekday != day) {
          nextDate = nextDate.add(const Duration(days: 1));
        }
        if (nextDate.isBefore(now)) {
          nextDate = nextDate.add(const Duration(days: 7));
        }
        final notifId = (alarm.id.hashCode * 10) + day;
        await _notifications.zonedSchedule(
          notifId,
          'Tempo Alarm',
          alarm.label.isNotEmpty ? alarm.label : 'Alarm',
          tz.TZDateTime.from(nextDate, tz.local),
          details,
          payload: alarm.id,
          matchDateTimeComponents:
              DateTimeComponents.dayOfWeekAndTime,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  Future<void> _cancelAlarmNotification(AlarmModel alarm) async {
    await _notifications.cancel(alarm.id.hashCode);
    if (alarm.isRepeating) {
      for (final day in alarm.repeatDays) {
        final notifId = (alarm.id.hashCode * 10) + day;
        await _notifications.cancel(notifId);
      }
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    final alarmId = response.payload;
    if (alarmId == null) return;

    final alarm = _alarms.firstWhere(
      (a) => a.id == alarmId,
      orElse: () => _alarms.first,
    );

    navigatorKey?.currentState?.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AlarmRingScreen(alarm: alarm),
      ),
    );
  }

  Future<void> rescheduleAll() async {
    for (final alarm in _alarms) {
      await _cancelAlarmNotification(alarm);
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
