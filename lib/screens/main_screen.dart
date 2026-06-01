import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_page.dart';
import 'tabs/alarms_tab.dart';
import 'tabs/world_clock_tab.dart';
import 'tabs/stopwatch_tab.dart';
import 'tabs/timer_tab.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _slideController;
  late Animation<double> _contentFade;
  bool _tabSwitchLock = false;

  static const _icons = [
    Icons.alarm_outlined,
    Icons.public_outlined,
    Icons.timer_outlined,
    Icons.hourglass_bottom,
  ];

  final List<Widget> _tabs = const [
    AlarmsTab(),
    WorldClockTab(),
    StopwatchTab(),
    TimerTab(),
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _contentFade = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (_currentIndex == index || _tabSwitchLock) return;
    _tabSwitchLock = true;
    HapticFeedback.selectionClick();
    _slideController.forward(from: 0.0);
    setState(() => _currentIndex = index);
    Future.delayed(const Duration(milliseconds: 400), () {
      _tabSwitchLock = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: topPad + 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsPage(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.settings_outlined,
                          size: 22,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FadeTransition(
                  opacity: _contentFade,
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _tabs,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: bottomInset + 20,
            child: _buildFloatingBar(cs),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBar(ColorScheme cs) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: cs.surfaceContainer.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth) / 4;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                    left: _currentIndex * itemWidth + 6,
                    top: 6,
                    bottom: 6,
                    child: Container(
                      width: itemWidth - 12,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(4, (i) => _buildNavItem(i)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                child: Icon(
                  _icons[index],
                  color: isSelected
                      ? Colors.white
                      : cs.onSurfaceVariant.withValues(alpha: 0.6),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
