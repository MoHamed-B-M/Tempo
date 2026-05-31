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
  String? _pendingAlarmId;

  List<AlarmModel> get alarms => List.unmodifiable(_alarms);
  String? get pendingAlarmId => _pendingAlarmId;

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
      onDidReceiveBackgroundNotificationResponse:
          _backgroundNotificationHandler,
    );

    await _createNotificationChannel();
    await _loadAlarms();

    // Check if app was launched from a notification tap
    final launchDetails = await _notifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      _pendingAlarmId = launchDetails!.notificationResponse?.payload;
    }

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
      importance: Importance.max,
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
    final soundName =
        sound != 'default' && sound != 'sound1' ? 'alarm_$sound' : 'sound1';
    return AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Plays when an alarm triggers',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: RawResourceAndroidNotificationSound(soundName),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction('snooze', 'Snooze 5min',
            showsUserInterface: true),
        const AndroidNotificationAction('stop', 'Stop',
            showsUserInterface: true),
      ],
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
    _handleNotificationResponse(response);
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final alarmId = response.payload;
    if (alarmId == null) return;

    AlarmModel? found;
    for (final a in _alarms) {
      if (a.id == alarmId) { found = a; break; }
    }
    if (found == null) return;
    final alarm = found;

    if (response.actionId == 'stop') {
      _stopAlarm(alarm);
      return;
    }

    if (response.actionId == 'snooze') {
      _snoozeAlarm(alarm);
      return;
    }

    _showAlarmScreen(alarm);
  }

  void _showAlarmScreen(AlarmModel alarm) {
    final navigator = navigatorKey?.currentState;
    if (navigator == null) {
      _pendingAlarmId = alarm.id;
      return;
    }

    navigator.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AlarmRingScreen(alarm: alarm),
      ),
    );
  }

  void processPendingAlarm() {
    if (_pendingAlarmId == null) return;
    final id = _pendingAlarmId!;
    _pendingAlarmId = null;

    AlarmModel? alarm;
    for (final a in _alarms) {
      if (a.id == id) { alarm = a; break; }
    }
    if (alarm != null) {
      _showAlarmScreen(alarm);
    }
  }

  void checkMissedAlarms() {
    final now = DateTime.now();

    for (final alarm in _alarms) {
      if (!alarm.enabled) continue;

      // Skip repeating alarms — they are handled by rescheduleAll
      if (alarm.isRepeating) continue;

      final alarmDateTime = DateTime(
        now.year, now.month, now.day, alarm.hour, alarm.minute,
      );
      if (!alarmDateTime.isBefore(now)) continue;

      final diff = now.difference(alarmDateTime);
      if (diff.inMinutes > 2) continue;

      _showAlarmScreen(alarm);
      return;
    }
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

  Future<void> _stopAlarm(AlarmModel alarm) async {
    await _cancelAlarmNotification(alarm);
    if (alarm.isRepeating) {
      await _scheduleAlarm(alarm);
    } else {
      final idx = _alarms.indexWhere((a) => a.id == alarm.id);
      if (idx != -1) {
        _alarms[idx] = _alarms[idx].copyWith(enabled: false);
        await _saveAlarms();
        notifyListeners();
      }
    }
  }

  Future<void> _snoozeAlarm(AlarmModel alarm) async {
    await _cancelAlarmNotification(alarm);

    final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
    final androidDetails = _buildAndroidDetails(alarm.sound);
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.zonedSchedule(
      alarm.id.hashCode,
      'Tempo Alarm',
      alarm.label.isNotEmpty ? alarm.label : 'Alarm',
      tz.TZDateTime.from(snoozeTime, tz.local),
      details,
      payload: alarm.id,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

@pragma('vm:entry-point')
Future<void> _backgroundNotificationHandler(NotificationResponse response) async {
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.cancel(response.id ?? -1);

  if (response.actionId == 'snooze') {
    const androidDetails = AndroidNotificationDetails(
      'tempo_alarm_channel',
      'Alarm Notifications',
      channelDescription: 'Plays when an alarm triggers',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );
    await plugin.show(
      (response.id ?? 0) + 1000,
      'Tempo Alarm',
      'Snoozed — ringing in 5 min',
      NotificationDetails(android: androidDetails),
    );
  }
}
