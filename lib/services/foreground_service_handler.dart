import 'package:flutter/services.dart';

class ForegroundServiceHandler {
  static const _channel = MethodChannel('com.example.tempo/foreground_service');

  static Future<void> start() async {
    try {
      await _channel.invokeMethod('start');
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {}
  }

  static Future<bool> isRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isRunning');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> checkBootCompleted() async {
    try {
      final result = await _channel.invokeMethod<bool>('bootCompleted');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
