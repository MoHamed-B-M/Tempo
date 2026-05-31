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
}
