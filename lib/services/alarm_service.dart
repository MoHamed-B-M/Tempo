import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/alarm_model.dart';
import '../screens/alarm_ring_screen.dart';
import 'screen_wake_handler.dart';

class AlarmService {
  static const _channelId = 'tempo_alarm_channel';
  static const _channelName = 'Alarm Notifications';

  static GlobalKey<NavigatorState>? navigatorKey;

  final FlutterLocalNotificationsPlugin _notifications;
  bool _initialized = false;
  String? _pendingAlarmId;

  /// Called when a notification stop action fires for a one-shot alarm.
  late void Function(String alarmId) onStopFromNotification;

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

    final launchDetails =
        await _notifications.getNotificationAppLaunchDetails();
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
            showsUserInterface: false),
      ],
    );
  }

  int _notifId(AlarmModel alarm) => alarm.id.hashCode.abs();
  int _notifIdForDay(AlarmModel alarm, int day) =>
      (alarm.id.hashCode.abs() * 10) + day;

  Future<void> scheduleAlarm(AlarmModel alarm) async {
    if (!alarm.enabled) return;

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.hour,
      alarm.minute,
      0,
      0,
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

  Future<void> _scheduleOneShot(AlarmModel alarm, DateTime date) async {
    final androidDetails = _buildAndroidDetails(alarm.sound);
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.zonedSchedule(
      _notifId(alarm),
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
        _notifId(alarm),
        'Tempo Alarm',
        alarm.label.isNotEmpty ? alarm.label : 'Alarm',
        tz.TZDateTime.from(
            scheduledDate.isBefore(now)
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
        await _notifications.zonedSchedule(
          _notifIdForDay(alarm, day),
          'Tempo Alarm',
          alarm.label.isNotEmpty ? alarm.label : 'Alarm',
          tz.TZDateTime.from(nextDate, tz.local),
          details,
          payload: alarm.id,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  Future<void> cancelAlarm(AlarmModel alarm) async {
    await _notifications.cancel(_notifId(alarm));
    if (alarm.isRepeating) {
      for (final day in alarm.repeatDays) {
        await _notifications.cancel(_notifIdForDay(alarm, day));
      }
    }
  }

  Future<void> scheduleAll(List<AlarmModel> alarms) async {
    for (final alarm in alarms) {
      await cancelAlarm(alarm);
      if (alarm.enabled) {
        await scheduleAlarm(alarm);
      }
    }
  }

  Future<void> stopAlarm(AlarmModel alarm) async {
    await cancelAlarm(alarm);
    if (alarm.isRepeating) {
      await scheduleAlarm(alarm);
    }
  }

  Future<void> snoozeAlarm(AlarmModel alarm) async {
    await cancelAlarm(alarm);

    final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
    final androidDetails = _buildAndroidDetails(alarm.sound);
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.zonedSchedule(
      _notifId(alarm),
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

  void _onNotificationTap(NotificationResponse response) {
    _handleNotificationResponse(response);
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final alarmId = response.payload;
    if (alarmId == null) return;

    if (response.actionId == 'stop') {
      _persistStopFlag(alarmId);
      onStopFromNotification(alarmId);
      navigatorKey?.currentState?.maybePop();
      return;
    }

    if (response.actionId == 'snooze') {
      // Build a minimal AlarmModel for scheduling — we only need id/sound/label
      final alarm = AlarmModel(
        id: alarmId,
        hour: 0,
        minute: 0,
        sound: 'default',
      );
      snoozeAlarm(alarm);
      navigatorKey?.currentState?.maybePop();
      return;
    }

    _showAlarmScreen(alarmId, 'Tempo Alarm');
  }

  Future<void> _persistStopFlag(String alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    final stopped = prefs.getStringList('stopped_alarms') ?? [];
    if (!stopped.contains(alarmId)) {
      stopped.add(alarmId);
      await prefs.setStringList('stopped_alarms', stopped);
    }
  }

  void _showAlarmScreen(String alarmId, String title) {
    final navigator = navigatorKey?.currentState;
    if (navigator == null) {
      _pendingAlarmId = alarmId;
      return;
    }

    ScreenWakeHandler.enable();
    navigator.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AlarmRingScreen(
          alarm: AlarmModel(id: alarmId, hour: 0, minute: 0),
        ),
      ),
    );
  }

  void processPendingAlarm() {
    if (_pendingAlarmId == null) return;
    final id = _pendingAlarmId!;
    _pendingAlarmId = null;
    _showAlarmScreen(id, 'Alarm');
  }

  Future<List<String>> fetchAndClearStoppedAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final stopped = prefs.getStringList('stopped_alarms') ?? [];
    await prefs.remove('stopped_alarms');
    return stopped;
  }

  void checkMissedAlarms(List<AlarmModel> alarms) {
    final now = DateTime.now();

    for (final alarm in alarms) {
      if (!alarm.enabled) continue;
      if (alarm.isRepeating) continue;

      final alarmDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        alarm.hour,
        alarm.minute,
      );
      if (!alarmDateTime.isBefore(now)) continue;

      final diff = now.difference(alarmDateTime);
      if (diff.inMinutes > 2) continue;

      _showAlarmScreen(alarm.id, alarm.label.isNotEmpty ? alarm.label : 'Alarm');
      return;
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

  Future<void> launchAlarmFullScreen() async {
    await ScreenWakeHandler.launchAlarmActivity();
  }

  Future<bool> ensureAlarmPermissions() async {
    try {
      await requestExactAlarmPermission();
      await ScreenWakeHandler.requestFullScreenIntentPermission();
      await ScreenWakeHandler.requestExactAlarmPermission();
      return true;
    } catch (_) {
      return false;
    }
  }
}

@pragma('vm:entry-point')
Future<void> _backgroundNotificationHandler(
    NotificationResponse response) async {
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

  if (response.actionId == 'stop' || response.actionId == 'snooze') {
    final prefs = await SharedPreferences.getInstance();
    final stopped = prefs.getStringList('stopped_alarms') ?? [];
    final id = response.payload;
    if (id != null && !stopped.contains(id)) {
      stopped.add(id);
      await prefs.setStringList('stopped_alarms', stopped);
    }
  }
}
