import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m3e_core/m3e_core.dart';
import '../models/alarm_model.dart';
import '../providers/alarm_provider.dart';

class AlarmEditPage extends ConsumerStatefulWidget {
  final AlarmModel alarm;

  const AlarmEditPage({super.key, required this.alarm});

  @override
  ConsumerState<AlarmEditPage> createState() => _AlarmEditPageState();
}

class _AlarmEditPageState extends ConsumerState<AlarmEditPage> {
  late String _label;
  late List<int> _repeatDays;
  late String _sound;
  late final M3EDropdownController<String> _soundController;
  late final TextEditingController _labelController;
  Timer? _labelDebounce;

  bool _ready = false;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _sounds = [
    ('default', 'Default'),
    ('radar', 'Radar'),
    ('crystal', 'Crystal'),
    ('pulse', 'Pulse'),
    ('echo', 'Echo'),
    ('ripple', 'Ripple'),
  ];

  @override
  void initState() {
    super.initState();
    _label = widget.alarm.label;
    _repeatDays = List.from(widget.alarm.repeatDays);
    _sound = widget.alarm.sound;
    _soundController = M3EDropdownController<String>();
    _labelController = TextEditingController(text: _label);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route?.animation == null) {
        _markReady();
        return;
      }
      if (route!.animation!.status == AnimationStatus.completed) {
        _markReady();
      } else {
        route.animation!.addStatusListener(_onAnimStatus);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final match = _sounds.firstWhere(
        (s) => s.$1 == _sound,
        orElse: () => _sounds.first,
      );
      _soundController.toggleOnly(
        M3EDropdownItem<String>(label: match.$2, value: match.$1),
      );
    });
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      final route = ModalRoute.of(context);
      route?.animation?.removeStatusListener(_onAnimStatus);
      _markReady();
    }
  }

  void _markReady() {
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    final route = ModalRoute.of(context);
    route?.animation?.removeStatusListener(_onAnimStatus);
    _labelController.dispose();
    _labelDebounce?.cancel();
    _soundController.dispose();
    super.dispose();
  }

  void _saveLabel(String val) {
    _label = val;
    _labelDebounce?.cancel();
    _labelDebounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(alarmListProvider.notifier).updateAlarmLabel(
            widget.alarm.id,
            _label,
          );
    });
  }

  void _saveRepeatDays() {
    ref.read(alarmListProvider.notifier).updateAlarmRepeatDays(
          widget.alarm.id,
          _repeatDays,
        );
  }

  void _saveSound(String value) {
    _sound = value;
    ref.read(alarmListProvider.notifier).updateAlarmSound(
          widget.alarm.id,
          value,
        );
  }

  void _deleteAlarm() {
    HapticFeedback.mediumImpact();
    ref.read(alarmListProvider.notifier).removeAlarm(widget.alarm.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _ready ? _buildFull(context) : _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: Center(
        child: Text(
          '${widget.alarm.hour.toString().padLeft(2, '0')}:${widget.alarm.minute.toString().padLeft(2, '0')}',
          style: GoogleFonts.nunito(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            letterSpacing: -2,
            color: cs.onSurface,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
        leading: const BackButton(),
        title: Text(
          'Edit Alarm',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '${widget.alarm.hour.toString().padLeft(2, '0')}:${widget.alarm.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.nunito(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2,
                  color: cs.onSurface,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _labelController,
              onChanged: _saveLabel,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Alarm label',
                hintStyle: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
                prefixIcon:
                    Icon(Icons.label_outline, color: cs.onSurfaceVariant, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'REPEAT',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final dayNum = i + 1;
                final selected = _repeatDays.contains(dayNum);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (selected) {
                        _repeatDays.remove(dayNum);
                      } else {
                        _repeatDays.add(dayNum);
                      }
                    });
                    _saveRepeatDays();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOutCubic,
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? cs.primary : cs.surfaceContainerHigh,
                      border: selected
                          ? null
                          : Border.all(color: cs.outlineVariant),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _dayNames[i],
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? cs.onPrimary : cs.onSurface,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),
            M3EDropdownMenu<String>(
              controller: _soundController,
              singleSelect: true,
              items: _sounds
                  .map((s) => M3EDropdownItem(label: s.$2, value: s.$1))
                  .toList(),
              onSelectionChanged: (items) {
                if (items.isNotEmpty && items.first.value != _sound) {
                  setState(() => _sound = items.first.value);
                  _saveSound(_sound);
                }
              },
              fieldStyle: M3EDropdownFieldStyle(
                hintText: 'Sound',
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                borderRadius: BorderRadius.circular(12),
                backgroundColor: cs.surfaceContainerHigh,
                border: BorderSide(color: cs.outlineVariant),
              ),
              dropdownStyle: const M3EDropdownStyle(
                containerRadius: 12,
                maxHeight: 300,
              ),
              itemStyle: const M3EDropdownItemStyle(
                outerRadius: 8,
                innerRadius: 4,
              ),
              haptic: M3EHapticFeedback.light,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: M3EOutlinedButton.icon(
                onPressed: _deleteAlarm,
                icon: Icon(Icons.delete_outline_rounded,
                    color: cs.error, size: 20),
                label: Text(
                  'Delete alarm',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.error,
                  ),
                ),
                size: M3EButtonSize.md,
                decoration: M3EButtonDecoration(
                  side: WidgetStatePropertyAll(
                    BorderSide(color: cs.error.withValues(alpha: 0.3)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
