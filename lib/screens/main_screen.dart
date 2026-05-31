import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/theme_service.dart';
import 'settings_page.dart';
import 'tabs/alarms_tab.dart';
import 'tabs/world_clock_tab.dart';
import 'tabs/stopwatch_tab.dart';
import 'tabs/timer_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _slideController;
  late Animation<double> _contentFade;
  bool _tabSwitchLock = false;

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
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOutCubic,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceCardOf(context),
                        border: Border.all(
                          color: AppColors.borderOf(context),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        size: 20,
                        color: AppColors.primaryTextOf(context),
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
      ),
      bottomNavigationBar: _buildFloatingBottomBar(),
    );
  }

  Widget _buildFloatingBottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset + 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceCardDark : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppColors.borderOf(context),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth) / 4;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  left: _currentIndex * itemWidth,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: itemWidth,
                    decoration: BoxDecoration(
                      color: AppColors.accentOf(context),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                Row(
                  children: [
                    _buildNavItem(0, Icons.alarm_outlined, 'Alarms'),
                    _buildNavItem(1, Icons.public_outlined, 'Clock'),
                    _buildNavItem(2, Icons.timer_outlined, 'Stopwatch'),
                    _buildNavItem(3, Icons.hourglass_bottom, 'Timer'),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final showLabels = context.watch<ThemeService>().showNavLabels;
    final showText = isSelected && showLabels;
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
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.secondaryTextOf(context),
                size: 22,
              ),
              if (showText) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.buttonLabel(context).copyWith(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
