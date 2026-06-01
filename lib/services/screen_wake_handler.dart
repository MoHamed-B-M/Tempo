import 'package:flutter/services.dart';

class ScreenWakeHandler {
  static const _channel = MethodChannel('com.example.tempo/screen_wake');

  static Future<void> enable() async {
    try {
      await _channel.invokeMethod('enable');
    } catch (_) {}
  }

  static Future<void> disable() async {
    try {
      await _channel.invokeMethod('disable');
    } catch (_) {}
  }

  static Future<void> launchAlarmActivity() async {
    try {
      await _channel.invokeMethod('launchAlarmActivity');
    } catch (_) {}
  }

  static Future<bool> requestFullScreenIntentPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestFullScreenIntentPermission');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> requestExactAlarmPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestExactAlarmPermission');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }
}
