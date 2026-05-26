import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late int _selectedHour;
  late int _selectedMinute;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialHour;
    _selectedMinute = widget.initialMinute;
    _hourController = FixedExtentScrollController(
      initialItem: widget.initialHour + (24 * 5),
    );
    _minuteController = FixedExtentScrollController(
      initialItem: widget.initialMinute + (60 * 5),
    );
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
    required double wheelWidth,
  }) {
    final itemHeight = MediaQuery.textScalerOf(context)
        .scale(MediaQuery.of(context).size.height * 0.065)
        .clamp(40.0, 64.0);
    final visibleItems = 5;
    final wheelHeight = itemHeight * visibleItems;

    return ClipRect(
      clipper: _HalfWheelClipper(),
      child: Container(
        width: wheelWidth,
        height: wheelHeight,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.borderOf(context), width: 0.5),
            bottom:
                BorderSide(color: AppColors.borderOf(context), width: 0.5),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: wheelHeight / 2 - itemHeight / 2,
              left: 0,
              right: 0,
              child: Container(
                height: itemHeight,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: AppColors.borderOf(context), width: 0.5),
                    bottom: BorderSide(
                        color: AppColors.borderOf(context), width: 0.5),
                  ),
                ),
              ),
            ),
            ListWheelScrollView(
              controller: controller,
              itemExtent: itemHeight,
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
                        ? AppTextStyles.wheelItem(context)
                        : AppTextStyles.wheelItemDim(context),
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
                      AppColors.backgroundOf(context),
                      AppColors.backgroundOf(context).withValues(alpha: 0),
                      AppColors.backgroundOf(context).withValues(alpha: 0),
                      AppColors.backgroundOf(context),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final wheelWidth = (screenWidth - 80) / 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('HOUR', style: AppTextStyles.buttonLabel(context)),
                  Text('MIN', style: AppTextStyles.buttonLabel(context)),
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
                  wheelWidth: wheelWidth,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 2,
                        height: 4,
                        color: AppColors.primaryTextOf(context),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 2,
                        height: 4,
                        color: AppColors.primaryTextOf(context),
                      ),
                    ],
                  ),
                ),
                _buildWheel(
                  controller: _minuteController,
                  itemCount: 60 * 10,
                  labelBuilder: (v) => v.toString().padLeft(2, '0'),
                  selected: _selectedMinute,
                  wheelWidth: wheelWidth,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 56,
              height: 56,
              child: TextButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.onConfirmed?.call();
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(
                        color: AppColors.primaryTextOf(context), width: 1.5),
                  ),
                ),
                child: Icon(
                  Icons.check,
                  color: AppColors.primaryTextOf(context),
                  size: 28,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HalfWheelClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width, size.height);
  }

  @override
  bool shouldReclip(_HalfWheelClipper oldClipper) => false;
}
