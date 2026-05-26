import 'dart:convert';
import 'package:flutter/material.dart';

class AlarmModel {
  final String id;
  final int hour;
  final int minute;
  final bool enabled;
  final String sound;
  final List<int> repeatDays;
  final String label;

  AlarmModel({
    required this.id,
    required this.hour,
    required this.minute,
    this.enabled = true,
    this.sound = 'default',
    this.repeatDays = const [],
    this.label = '',
  });

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  bool get isRepeating => repeatDays.isNotEmpty;

  AlarmModel copyWith({
    String? id,
    int? hour,
    int? minute,
    bool? enabled,
    String? sound,
    List<int>? repeatDays,
    String? label,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      sound: sound ?? this.sound,
      repeatDays: repeatDays ?? this.repeatDays,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'hour': hour,
    'minute': minute,
    'enabled': enabled,
    'sound': sound,
    'repeatDays': jsonEncode(repeatDays),
    'label': label,
  };

  factory AlarmModel.fromJson(Map<String, dynamic> json) => AlarmModel(
    id: json['id'] as String,
    hour: json['hour'] as int,
    minute: json['minute'] as int,
    enabled: json['enabled'] as bool? ?? true,
    sound: json['sound'] as String? ?? 'default',
    repeatDays: json['repeatDays'] != null
        ? List<int>.from(jsonDecode(json['repeatDays'] as String))
        : [],
    label: json['label'] as String? ?? '',
  );
}
