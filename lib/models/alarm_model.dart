import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class AlarmModel extends HiveObject {
  final String id;
  final int hour;
  final int minute;
  final bool enabled;
  final String sound;
  final List<int> repeatDays;
  final String label;

  AlarmModel({
    String? id,
    required this.hour,
    required this.minute,
    this.enabled = true,
    this.sound = 'default',
    this.repeatDays = const [],
    this.label = '',
  }) : id = id ?? const Uuid().v4();

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
}

class AlarmModelAdapter extends TypeAdapter<AlarmModel> {
  @override
  final int typeId = 0;

  @override
  AlarmModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmModel(
      id: fields[0] as String,
      hour: fields[1] as int,
      minute: fields[2] as int,
      enabled: fields[3] as bool? ?? true,
      sound: fields[4] as String? ?? 'default',
      repeatDays: (fields[5] as List?)?.cast<int>() ?? [],
      label: fields[6] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, AlarmModel obj) {
    writer.writeByte(7);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.hour);
    writer.writeByte(2);
    writer.write(obj.minute);
    writer.writeByte(3);
    writer.write(obj.enabled);
    writer.writeByte(4);
    writer.write(obj.sound);
    writer.writeByte(5);
    writer.write(obj.repeatDays);
    writer.writeByte(6);
    writer.write(obj.label);
  }
}
