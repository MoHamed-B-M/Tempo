import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m3e_core/m3e_core.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../services/update_manager.dart';
import 'about_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _channel = 'stable';
  String _appVersion = '';
  bool _checking = false;
  String _currentQuote = '';

  static const _quotes = [
    'Time is what we want most, but what we use worst. — William Penn',
    'The key is in not spending time, but in investing it. — Stephen Covey',
    'Lost time is never found again. — Benjamin Franklin',
    'Time flies over us, but leaves its shadow behind. — Nathaniel Hawthorne',
    'The two most powerful warriors are patience and time. — Leo Tolstoy',
    'Better three hours too soon than a minute too late. — William Shakespeare',
    'Time is the wisest counselor of all. — Pericles',
    'Punctuality is the thief of time. — Oscar Wilde',
    'The future is something which everyone reaches at the rate of sixty minutes an hour. — C.S. Lewis',
    'Time is what prevents everything from happening at once. — John Archibald Wheeler',
    'Every moment is a fresh beginning. — T.S. Eliot',
    'Yesterday is history, tomorrow is a mystery, today is a gift. — Eleanor Roosevelt',
    'Time stays long enough for anyone who will use it. — Leonardo da Vinci',
    'The bad news is time flies. The good news is you\'re the pilot. — Michael Altshuler',
    'It\'s not that we have little time, but more that we waste a good deal of it. — Seneca',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final channel = await UpdateManager.getSavedChannel();
    final version = await UpdateManager.getCurrentVersion();
    final quote = _quotes[Random().nextInt(_quotes.length)];
    setState(() {
      _channel = channel;
      _appVersion = version;
      _currentQuote = quote;
    });
  }

  Future<void> _setChannel(String channel) async {
    HapticFeedback.selectionClick();
    setState(() => _channel = channel);
    await UpdateManager.saveChannel(channel);
  }

  Future<void> _checkForUpdates() async {
    HapticFeedback.mediumImpact();
    setState(() => _checking = true);
    await UpdateManager.checkAndShowUpdate(context, silent: false);
    setState(() => _checking = false);
  }

  void _showAutoDismissSheet() {
    final settings = ref.read(alarmSettingsProvider);
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AutoDismissSheet(
        currentMinutes: settings.autoDismissMinutes,
        onSelected: (minutes) =>
            ref.read(alarmSettingsProvider.notifier).setAutoDismissMinutes(minutes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final alarmSettings = ref.watch(alarmSettingsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SETTINGS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(cs, 'ALARM'),
            const SizedBox(height: 12),
            _buildMonochromaticToggle(
              cs: cs,
              icon: Icons.vibration_outlined,
              label: 'Vibrate on alarm',
              enabled: alarmSettings.vibrateOnAlarm,
              onTap: () => ref
                  .read(alarmSettingsProvider.notifier)
                  .setVibrateOnAlarm(!alarmSettings.vibrateOnAlarm),
            ),
            const SizedBox(height: 12),
            _buildAutoDismissTile(cs, alarmSettings),
            const SizedBox(height: 12),
            _buildMonochromaticSlider(
              cs: cs,
              icon: Icons.volume_up_outlined,
              label: 'Alarm volume',
              value: alarmSettings.volume,
              onChanged: (v) =>
                  ref.read(alarmSettingsProvider.notifier).setVolume(v),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(cs, 'APPEARANCE'),
            const SizedBox(height: 12),
            _buildCustomSettingToggle(
              cs: cs,
              icon: Icons.dark_mode_outlined,
              label: isDark
                  ? 'Dark Mode'
                  : (themeMode == ThemeMode.light
                      ? 'Light Mode'
                      : 'System Theme'),
              enabled: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(themeModeProvider.notifier).toggle();
              },
            ),
            const SizedBox(height: 12),
            _buildNavigationTile(
                cs,
                Icons.info_outline,
                'About',
                () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutPage()),
                    )),
            const SizedBox(height: 32),
            _buildSectionTitle(cs, 'APP VERSION'),
            const SizedBox(height: 12),
            _buildInfoTile(cs, Icons.info_outline, 'Current Version',
                _appVersion.isNotEmpty ? 'v$_appVersion' : 'Loading...'),
            const SizedBox(height: 32),
            _buildSectionTitle(cs, 'UPDATE CHANNEL'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: M3EButton.icon(
                    onPressed: () => _setChannel('stable'),
                    icon: Icon(Icons.shield_outlined,
                        color: _channel == 'stable' ? cs.onPrimary : null,
                        size: 18),
                    label: Text(
                      'Stable',
                      style: TextStyle(
                          color: _channel == 'stable' ? cs.onPrimary : null),
                    ),
                    style: _channel == 'stable'
                        ? M3EButtonStyle.filled
                        : M3EButtonStyle.outlined,
                    size: M3EButtonSize.md,
                    decoration: M3EButtonDecoration(
                      backgroundColor: _channel == 'stable'
                          ? WidgetStatePropertyAll(cs.primary)
                          : null,
                      side: _channel == 'stable'
                          ? null
                          : WidgetStatePropertyAll(
                              BorderSide(color: cs.outlineVariant)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: M3EButton.icon(
                    onPressed: () => _setChannel('beta'),
                    icon: Icon(Icons.science_outlined,
                        color: _channel == 'beta' ? cs.onPrimary : null,
                        size: 18),
                    label: Text(
                      'Beta',
                      style: TextStyle(
                          color: _channel == 'beta' ? cs.onPrimary : null),
                    ),
                    style: _channel == 'beta'
                        ? M3EButtonStyle.filled
                        : M3EButtonStyle.outlined,
                    size: M3EButtonSize.md,
                    decoration: M3EButtonDecoration(
                      backgroundColor: _channel == 'beta'
                          ? WidgetStatePropertyAll(cs.primary)
                          : null,
                      side: _channel == 'beta'
                          ? null
                          : WidgetStatePropertyAll(
                              BorderSide(color: cs.outlineVariant)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _channel == 'stable'
                    ? 'Only stable releases will be shown.'
                    : 'Pre-release versions will be included.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 48),
            M3EButton.icon(
              onPressed: _checking ? null : _checkForUpdates,
              icon: _checking
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : const Icon(Icons.refresh, size: 18),
              label: Text(
                _checking ? 'CHECKING...' : 'CHECK FOR UPDATES',
                style: TextStyle(color: cs.onPrimary),
              ),
              style: M3EButtonStyle.filled,
              size: M3EButtonSize.md,
              decoration: M3EButtonDecoration(
                backgroundColor: WidgetStatePropertyAll(cs.primary),
                foregroundColor: WidgetStatePropertyAll(cs.onPrimary),
                borderRadius: 18,
              ),
            ),
            const SizedBox(height: 32),
            if (_currentQuote.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '"$_currentQuote"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            Center(
              child: Column(
                children: [
                  Text(
                    'Tempo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v$_appVersion',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ColorScheme cs, String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: cs.onSurfaceVariant,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildMonochromaticToggle({
    required ColorScheme cs,
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.onSurfaceVariant, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: enabled ? cs.primary : cs.outlineVariant,
              ),
              padding: const EdgeInsets.all(3),
              child: Align(
                alignment:
                    enabled ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: enabled ? cs.onPrimary : cs.surface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoDismissTile(ColorScheme cs, AlarmSettingsState settings) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showAutoDismissSheet,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.timer_outlined, color: cs.onSurfaceVariant, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto-dismiss alarm',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    settings.autoDismissEnabled
                        ? 'After ${settings.autoDismissMinutes} min'
                        : 'Off',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMonochromaticSlider({
    required ColorScheme cs,
    required IconData icon,
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cs.onSurfaceVariant, size: 22),
              const SizedBox(width: 16),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).round()}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DotMatrixSlider(
            cs: cs,
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomSettingToggle({
    required ColorScheme cs,
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: enabled ? cs.primary : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: enabled ? Colors.transparent : cs.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: enabled ? cs.onPrimary : cs.onSurface, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: enabled ? cs.onPrimary : cs.onSurface,
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled ? cs.onPrimary : Colors.transparent,
                border: Border.all(
                  color: enabled
                      ? cs.onPrimary
                      : cs.onSurfaceVariant.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: enabled
                  ? Icon(Icons.check, size: 14, color: cs.primary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
      ColorScheme cs, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.onSurfaceVariant, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile(
      ColorScheme cs, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.onSurfaceVariant, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 22),
          ],
        ),
      ),
    );
  }
}

class _DotMatrixSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final ColorScheme cs;
  final _sliderKey = GlobalKey();

  _DotMatrixSlider({
    required this.cs,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const dotCount = 20;
    final activeDots = (value * dotCount).round();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => _updateFromPosition(details.localPosition.dx),
      onHorizontalDragUpdate: (details) =>
          _updateFromPosition(details.localPosition.dx),
      child: LayoutBuilder(
        key: _sliderKey,
        builder: (context, constraints) {
          final dotWidth =
              (constraints.maxWidth - (dotCount - 1) * 4) / dotCount;
          return SizedBox(
            height: 24,
            child: Row(
              children: List.generate(dotCount, (i) {
                final isActive = i < activeDots;
                return Padding(
                  padding: EdgeInsets.only(right: i < dotCount - 1 ? 4 : 0),
                  child: Container(
                    width: dotWidth,
                    height: isActive ? 20 : 8,
                    decoration: BoxDecoration(
                      color: isActive ? cs.primary : cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  void _updateFromPosition(double dx) {
    final renderBox =
        _sliderKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final width = renderBox.size.width;
    if (width <= 0) return;
    final clamped = (dx / width).clamp(0.0, 1.0);
    onChanged(clamped);
  }
}

class _AutoDismissSheet extends StatefulWidget {
  final int currentMinutes;
  final ValueChanged<int> onSelected;

  const _AutoDismissSheet({
    required this.currentMinutes,
    required this.onSelected,
  });

  @override
  State<_AutoDismissSheet> createState() => _AutoDismissSheetState();
}

class _AutoDismissSheetState extends State<_AutoDismissSheet> {
  late int _selected;

  static const _options = [0, 1, 2, 5, 10, 15, 30];

  @override
  void initState() {
    super.initState();
    _selected = widget.currentMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'AUTO-DISMISS ALARM',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ..._options.map((minutes) {
            final isSelected = _selected == minutes;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() => _selected = minutes);
                widget.onSelected(minutes);
                Navigator.pop(context);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary : cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: isSelected
                      ? null
                      : Border.all(color: cs.outlineVariant, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      minutes == 0 ? 'Off' : '$minutes minutes',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? cs.onPrimary : cs.onSurface,
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check, color: cs.onPrimary, size: 18),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
