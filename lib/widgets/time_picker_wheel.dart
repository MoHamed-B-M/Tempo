import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class TimePickerWheel extends StatefulWidget {
  final int initialHour;
  final int initialMinute;
  final ValueChanged<TimeOfDay>? onChanged;
  final VoidCallback? onConfirmed;

  const TimePickerWheel({
    super.key,
    this.initialHour = 0,
    this.initialMinute = 0,
    this.onChanged,
    this.onConfirmed,
  });

  @override
  State<TimePickerWheel> createState() => _TimePickerWheelState();
}

class _TimePickerWheelState extends State<TimePickerWheel> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  int _selectedHour = 0;
  int _selectedMinute = 0;

  static const _itemHeight = 56.0;
  static const _visibleItems = 5;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialHour;
    _selectedMinute = widget.initialMinute;
    _hourController = FixedExtentScrollController(initialItem: widget.initialHour + (24 * 5));
    _minuteController = FixedExtentScrollController(initialItem: widget.initialMinute + (60 * 5));
    _hourController.addListener(_onScroll);
    _minuteController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _hourController
      ..removeListener(_onScroll)
      ..dispose();
    _minuteController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hourController.hasClients || !_minuteController.hasClients) return;
    final hour = _hourController.selectedItem % 24;
    final minute = _minuteController.selectedItem % 60;
    if (hour != _selectedHour || minute != _selectedMinute) {
      setState(() {
        _selectedHour = hour;
        _selectedMinute = minute;
      });
      widget.onChanged?.call(TimeOfDay(hour: hour, minute: minute));
    }
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) labelBuilder,
    required int selected,
  }) {
    final wheelHeight = _itemHeight * _visibleItems;

    return ClipRect(
      child: SizedBox(
        width: 100,
        height: wheelHeight,
        child: Stack(
          children: [
            Positioned(
              top: wheelHeight / 2 - _itemHeight / 2,
              left: 0,
              right: 0,
              child: Container(
                height: _itemHeight,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 0.5),
                    bottom: BorderSide(color: AppColors.border, width: 0.5),
                  ),
                ),
              ),
            ),
            ListWheelScrollView(
              controller: controller,
              itemExtent: _itemHeight,
              diameterRatio: 1.2,
              offAxisFraction: -0.35,
              useMagnifier: false,
              clipBehavior: Clip.none,
              physics: const FixedExtentScrollPhysics(),
              children: List.generate(itemCount, (index) {
                final value = index % (itemCount ~/ 10);
                final isSelected = value == selected;
                return Center(
                  child: Text(
                    labelBuilder(value),
                    style: isSelected
                        ? AppTextStyles.wheelItem
                        : AppTextStyles.wheelItemDim,
                  ),
                );
              }),
            ),
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.background,
                      AppColors.background.withValues(alpha: 0),
                      AppColors.background.withValues(alpha: 0),
                      AppColors.background,
                    ],
                    stops: const [0.0, 0.25, 0.75, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('HOUR', style: AppTextStyles.buttonLabel),
              Text('MIN', style: AppTextStyles.buttonLabel),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildWheel(
              controller: _hourController,
              itemCount: 24 * 10,
              labelBuilder: (v) => v.toString().padLeft(2, '0'),
              selected: _selectedHour,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 2,
                    height: 4,
                    color: AppColors.primaryText,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 2,
                    height: 4,
                    color: AppColors.primaryText,
                  ),
                ],
              ),
            ),
            _buildWheel(
              controller: _minuteController,
              itemCount: 60 * 10,
              labelBuilder: (v) => v.toString().padLeft(2, '0'),
              selected: _selectedMinute,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 56,
          height: 56,
          child: TextButton(
            onPressed: () {
              widget.onConfirmed?.call();
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(color: AppColors.primaryText, width: 1.5),
              ),
            ),
            child: Icon(
              Icons.check,
              color: AppColors.primaryText,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}
