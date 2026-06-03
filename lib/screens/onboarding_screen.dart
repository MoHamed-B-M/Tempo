import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:motor/motor.dart';
import '../core/hive_helper.dart';
import 'main_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _activePage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _completeOnboarding() async {
    await HiveHelper.settings.put('onboarding_complete', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeInOutCubic),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _advance() {
    if (_activePage < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _controller,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (p) => setState(() => _activePage = p),
              children: const [
                _WelcomePage(),
                _FeaturesPage(),
                _ReadyPage(),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomPad + 40,
              child: _PageIndicator(
                count: 3,
                activeIndex: _activePage,
                onTap: _advance,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpringSlide extends StatefulWidget {
  final bool active;
  final Widget child;
  const _SpringSlide({required this.active, required this.child});

  @override
  State<_SpringSlide> createState() => _SpringSlideState();
}

class _SpringSlideState extends State<_SpringSlide> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.active) _progress = 1.0;
  }

  @override
  void didUpdateWidget(_SpringSlide old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      setState(() => _progress = 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleMotionBuilder(
      value: _progress,
      motion: M3EMotion.expressiveSpatialDefault.toMotion(),
      builder: (context, value, _) {
        final t = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 28 * (1.0 - t)),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _SpringSlide(
      active: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              M3EContainer.puffy(
                color: cs.primaryContainer,
                width: 112,
                height: 112,
                child: Icon(
                  Icons.access_time_rounded,
                  size: 48,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Tempo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.5,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'A minimalist, high-fidelity\nalarm clock.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Precision timekeeping powered by a low-latency\nclock engine with spring-driven interactions\nand dynamic Material You theming.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturesPage extends StatelessWidget {
  const _FeaturesPage();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _SpringSlide(
      active: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Expressive Interaction',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Every touch feels intentional.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              _FeatureRow(
                icon: Icons.tune,
                title: 'Spring-Driven Controls',
                subtitle:
                    'Alarm toggles and sliders with mechanical spring physics',
                cs: cs,
              ),
              const SizedBox(height: 20),
              _FeatureRow(
                icon: Icons.unfold_more,
                title: 'Collapsible Cards',
                subtitle: 'Expressive expandable panels with fluid motion',
                cs: cs,
              ),
              const SizedBox(height: 20),
              _FeatureRow(
                icon: Icons.palette_outlined,
                title: 'Material You Colors',
                subtitle: 'Dynamic wallpaper-synced colour schemes',
                cs: cs,
              ),
              const SizedBox(height: 20),
              _FeatureRow(
                icon: Icons.public,
                title: 'Offline World Clock',
                subtitle: 'IANA timezone database with Hive-cached favourites',
                cs: cs,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme cs;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        M3EContainer.gem(
          color: cs.primaryContainer.withValues(alpha: 0.5),
          width: 48,
          height: 48,
          child: Icon(icon, size: 22, color: cs.onPrimaryContainer),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReadyPage extends StatelessWidget {
  const _ReadyPage();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _SpringSlide(
      active: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ready to Begin',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'One last thing before you start.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              M3EContainer.puffy(
                color: cs.tertiaryContainer,
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 28,
                      color: cs.onTertiaryContainer,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Remember: Use Dark Mode for the optimal, '
                      'high-contrast visual experience. Light Mode is '
                      'currently undergoing a complete structural refactor '
                      'and may still display layout glitches.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.6,
                        color: cs.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              M3EButton.icon(
                onPressed: () {
                  final state = context
                      .findAncestorStateOfType<_OnboardingScreenState>();
                  state?._completeOnboarding();
                },
                icon: const Icon(Icons.arrow_forward, size: 20),
                label: Text(
                  'Get Started',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                size: M3EButtonSize.lg,
                decoration: const M3EButtonDecoration(
                  motion: M3EMotion.standardSpatialFast,
                  haptic: M3EHapticFeedback.medium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;
  final VoidCallback onTap;

  const _PageIndicator({
    required this.count,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final isActive = i == activeIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 32 : 8,
            height: 8,
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              color: isActive ? cs.primary : cs.outlineVariant,
            ),
          );
        }),
      ),
    );
  }
}
