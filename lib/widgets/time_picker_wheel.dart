import 'package:flutter/material.dart';
import '../constants/app_text_styles.dart';

class TimePickerWheel extends StatefulWidget {
  const TimePickerWheel({super.key});

  @override
  State<TimePickerWheel> createState() => _TimePickerWheelState();
}

class _TimePickerWheelState extends State<TimePickerWheel> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  int _selectedHour = 9;
  int _selectedMinute = 41;

  @override
  void initState() {
    super.initState();
    _hourController = FixedExtentScrollController(initialItem: 9);
    _minuteController = FixedExtentScrollController(initialItem: 41);
    _hourController.addListener(_onHourScrollEnd);
    _minuteController.addListener(_onMinuteScrollEnd);
  }

  void _onHourScrollEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hourController.hasClients) return;
      setState(() {
        _selectedHour = _hourController.selectedItem % 24;
      });
    });
  }

  void _onMinuteScrollEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_minuteController.hasClients) return;
      setState(() {
        _selectedMinute = _minuteController.selectedItem % 60;
      });
    });
  }

  @override
  void dispose() {
    _hourController
      ..removeListener(_onHourScrollEnd)
      ..dispose();
    _minuteController
      ..removeListener(_onMinuteScrollEnd)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          child: ListWheelScrollView(
            controller: _hourController,
            itemExtent: 60,
            diameterRatio: 1.5,
            useMagnifier: true,
            magnification: 1.2,
            children: List.generate(24 * 10, (index) {
              final hour = index % 24;
              return Center(
                child: Text(
                  hour.toString().padLeft(2, '0'),
                  style: AppTextStyles.wheelItem,
                ),
              );
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(':', style: AppTextStyles.wheelItem),
        ),
        SizedBox(
          width: 100,
          child: ListWheelScrollView(
            controller: _minuteController,
            itemExtent: 60,
            diameterRatio: 1.5,
            useMagnifier: true,
            magnification: 1.2,
            children: List.generate(60 * 10, (index) {
              final minute = index % 60;
              return Center(
                child: Text(
                  minute.toString().padLeft(2, '0'),
                  style: AppTextStyles.wheelItem,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
