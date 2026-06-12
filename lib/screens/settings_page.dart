import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';
import '../core/navigation.dart';
import '../providers/nav_style_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../services/update_manager.dart';
import '../widgets/expressive_settings_tile.dart';
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
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: cs.onSurface,
              ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _SettingsSection(
            label: 'ALARM',
            child: _buildCardWithTheme(context, cs, [
              ExpressiveSettingsTile(
                icon: Icons.vibration_outlined,
                title: 'Vibrate on alarm',
                iconBackground: cs.surfaceContainerHighest,
                iconColor: cs.onSurfaceVariant,
                trailing: Switch(
                  value: alarmSettings.vibrateOnAlarm,
                  onChanged: (v) => ref
                      .read(alarmSettingsProvider.notifier)
                      .setVibrateOnAlarm(v),
                ),
                onTap: () => ref
                    .read(alarmSettingsProvider.notifier)
                    .setVibrateOnAlarm(!alarmSettings.vibrateOnAlarm),
              ),
              const Divider(height: 1, indent: 72),
              ExpressiveSettingsTile.navigation(
                icon: Icons.timer_outlined,
                title: 'Auto-dismiss alarm',
                subtitle: alarmSettings.autoDismissEnabled
                    ? 'After ${alarmSettings.autoDismissMinutes} min'
                    : 'Off',
                iconBackground: cs.surfaceContainerHighest,
                iconColor: cs.onSurfaceVariant,
                onTap: _showAutoDismissSheet,
              ),
              const Divider(height: 1, indent: 72),
              _VolumeTile(cs: cs, value: alarmSettings.volume, onChanged: (v) {
                ref.read(alarmSettingsProvider.notifier).setVolume(v);
              }),
            ]),
          ),
          const SizedBox(height: 12),
          _SettingsSection(
            label: 'APPEARANCE',
            child: _buildCardWithTheme(context, cs, [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THEME',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            letterSpacing: 1.5,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_outlined),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined),
                            label: Text('Dark'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.settings_outlined),
                            label: Text('System'),
                          ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (selected) {
                          HapticFeedback.selectionClick();
                          ref
                              .read(themeModeProvider.notifier)
                              .setMode(selected.first);
                        },
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 72),
              ExpressiveSettingsTile.navigation(
                icon: Icons.palette_outlined,
                title: 'About Tempo',
                subtitle: 'Version $_appVersion',
                iconBackground: cs.surfaceContainerHighest,
                iconColor: cs.onSurfaceVariant,
                onTap: () => SmoothNavigator.push(
                  context,
                  const AboutPage(),
                ),
              ),
              const Divider(height: 1, indent: 72),
              ExpressiveSettingsTile(
                icon: Icons.bubble_chart_outlined,
                title: 'Bubble Navigation',
                iconBackground: cs.surfaceContainerHighest,
                iconColor: cs.onSurfaceVariant,
                trailing: Switch(
                  value: ref.watch(navStyleProvider).useBubbleNav,
                  onChanged: (_) =>
                      ref.read(navStyleProvider.notifier).toggle(),
                ),
                onTap: () => ref.read(navStyleProvider.notifier).toggle(),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          _SettingsSection(
            label: 'GENERAL',
            child: _buildCardWithTheme(context, cs, [
              ..._buildUpdateChannelSection(cs),
              const Divider(height: 1, indent: 72),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: M3EButton.icon(
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
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          if (_currentQuote.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '"$_currentQuote"',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
              ),
            ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  'Tempo',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v$_appVersion',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCardWithTheme(BuildContext context, ColorScheme cs, List<Widget> children) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: cs.onPrimaryContainer,
          displayColor: cs.onPrimaryContainer,
        ),
        dividerColor: cs.onPrimaryContainer.withValues(alpha: 0.12),
      ),
      child: _ExpressiveCard(children: children),
    );
  }

  List<Widget> _buildUpdateChannelSection(ColorScheme cs) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Text(
          'UPDATE CHANNEL',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 1.5,
              ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
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
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Text(
          _channel == 'stable'
              ? 'Only stable releases will be shown.'
              : 'Pre-release versions will be included.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      ),
    ];
  }
}

class _SettingsSection extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingsSection({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
          ),
        ),
        child,
      ],
    );
  }
}

class _ExpressiveCard extends StatelessWidget {
  final List<Widget> children;

  const _ExpressiveCard({
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _VolumeTile extends StatelessWidget {
  final ColorScheme cs;
  final double value;
  final ValueChanged<double> onChanged;

  const _VolumeTile({
    required this.cs,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.volume_up_outlined,
                  size: 20,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Alarm volume',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.onPrimaryContainer,
                      ),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DotMatrixSlider(
            cs: cs,
            value: value,
            onChanged: onChanged,
          ),
        ],
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
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
