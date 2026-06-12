import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../packages/animated_bubble_nav/animated_bubble_nav.dart';
import '../core/navigation.dart';
import '../providers/nav_style_provider.dart';
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

  static const _labels = ['Alarm', 'Clock', 'Timer', 'Stopwatch'];

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
    selectedIndexNotifier.addListener(_onBubbleNavChanged);
  }

  void _onBubbleNavChanged() {
    final index = selectedIndexNotifier.value;
    if (index != _currentIndex && index < _tabs.length) {
      _switchTab(index);
    }
  }

  @override
  void dispose() {
    selectedIndexNotifier.removeListener(_onBubbleNavChanged);
    _slideController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (_currentIndex == index || _tabSwitchLock) return;
    _tabSwitchLock = true;
    HapticFeedback.selectionClick();
    _slideController.forward(from: 0.0);
    setState(() {
      _currentIndex = index;
      selectedIndexNotifier.value = index;
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _tabSwitchLock = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final useBubble = ref.watch(navStyleProvider).useBubbleNav;

    return Scaffold(
      extendBody: true,
      backgroundColor: cs.surface,
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
                        SmoothNavigator.push(
                          context,
                          const SettingsPage(),
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
            child: useBubble ? _buildBubbleNav(cs) : _buildFloatingBar(cs),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleNav(ColorScheme cs) {
    return CustomBubbleNavBar(
      items: List.generate(4, (i) => BubbleItem(label: _labels[i], icon: _icons[i])),
      bubbleDecoration: BubbleDecoration(
        backgroundColor: cs.surfaceContainer.withValues(alpha: 0.92),
        selectedBubbleBackgroundColor: cs.primary,
        unSelectedBubbleBackgroundColor: Colors.transparent,
        selectedBubbleIconColor: cs.onPrimary,
        unSelectedBubbleIconColor: cs.onSurfaceVariant.withValues(alpha: 0.6),
        iconSize: 22,
        shapes: BubbleShape.square,
        squareBordersRadius: 32,
        bubbleItemSize: 10,
        innerIconLabelSpacing: 4,
        padding: const EdgeInsets.all(6),
        margin: EdgeInsets.zero,
        alignment: Alignment.bottomCenter,
        bubbleDuration: const Duration(milliseconds: 300),
        selectedBubbleLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cs.onPrimary,
        ),
        unSelectedBubbleLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
        ),
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
            color: cs.shadow.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: RepaintBoundary(
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
    );
  }

  Widget _buildNavItem(int index) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _switchTab(index),
        child: Center(
          child: AnimatedScale(
            scale: isSelected ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            child: Icon(
              _icons[index],
              color: isSelected
                  ? cs.onPrimary
                  : cs.onSurfaceVariant.withValues(alpha: 0.6),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
