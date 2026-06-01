import 'package:hive_flutter/hive_flutter.dart';
import '../models/alarm_model.dart';

class HiveHelper {
  static const alarmsBox = 'alarms';
  static const settingsBox = 'settings';
  static const worldClockBox = 'world_clock';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(AlarmModelAdapter());
    await Hive.openBox<AlarmModel>(alarmsBox);
    await Hive.openBox(settingsBox);
    await Hive.openBox(worldClockBox);
  }

  static Box<AlarmModel> get alarms => Hive.box<AlarmModel>(alarmsBox);
  static Box get settings => Hive.box(settingsBox);
  static Box get worldClock => Hive.box(worldClockBox);
}
