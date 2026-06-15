import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _onHourChanged(int index) {
    final hour = index % 24;
    if (hour != _selectedHour) {
      setState(() => _selectedHour = hour);
      widget.onChanged?.call(TimeOfDay(hour: hour, minute: _selectedMinute));
    }
  }

  void _onMinuteChanged(int index) {
    final minute = index % 60;
    if (minute != _selectedMinute) {
      setState(() => _selectedMinute = minute);
      widget.onChanged?.call(TimeOfDay(hour: _selectedHour, minute: minute));
    }
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) labelBuilder,
    required int selected,
    required double wheelWidth,
  }) {
    final cs = Theme.of(context).colorScheme;
    final itemHeight = MediaQuery.textScalerOf(context)
        .scale(MediaQuery.of(context).size.height * 0.065)
        .clamp(40.0, 64.0);
    const visibleItems = 5;
    final wheelHeight = itemHeight * visibleItems;

    return ClipRect(
      clipper: _HalfWheelClipper(),
      child: Container(
        width: wheelWidth,
        height: wheelHeight,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: cs.outlineVariant, width: 0.5),
            bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
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
                    top: BorderSide(color: cs.outlineVariant, width: 0.5),
                    bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
                  ),
                ),
              ),
            ),
            ListWheelScrollView(
              controller: controller,
              itemExtent: itemHeight,
              diameterRatio: 1.35,
              offAxisFraction: 0.0,
              useMagnifier: true,
              magnification: 1.15,
              clipBehavior: Clip.none,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: controller == _hourController
                  ? _onHourChanged
                  : _onMinuteChanged,
              children: List.generate(itemCount, (index) {
                final value = index % (itemCount ~/ 10);
                final isSelected = value == selected;
                return Center(
                  child: Text(
                    labelBuilder(value),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 28,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w300,
                      color: isSelected ? cs.onSurface : cs.onSurfaceVariant,
                    ),
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
                      cs.surface,
                      cs.surface.withValues(alpha: 0),
                      cs.surface.withValues(alpha: 0),
                      cs.surface,
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
    final cs = Theme.of(context).colorScheme;
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
                  Text('HOUR',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 1.5,
                      )),
                  Text('MIN',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 1.5,
                      )),
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
                        color: cs.onSurface,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 2,
                        height: 4,
                        color: cs.onSurface,
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
                    side: BorderSide(color: cs.primary, width: 1.5),
                  ),
                ),
                child: Icon(
                  Icons.check,
                  color: cs.primary,
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
    return Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2);
  }

  @override
  bool shouldReclip(_HalfWheelClipper oldClipper) => false;
}
