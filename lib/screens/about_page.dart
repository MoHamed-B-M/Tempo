import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/changelog_parser.dart';
import '../services/update_manager.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _appVersion = '';
  List<String> _releaseNotes = [];
  bool _loadingNotes = true;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final version = await UpdateManager.getCurrentVersion();
    if (!mounted) return;
    setState(() => _appVersion = version);
    _loadChangelog(version);
  }

  Future<void> _loadChangelog(String version) async {
    final entries = await ChangelogParser.getChangelogForVersion(version);
    if (!mounted) return;
    setState(() {
      _releaseNotes = entries;
      _loadingNotes = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
        title: Text(
          'ABOUT',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // ── Hero card ──────────────────────────────────────────
            Card(
              color: cs.surfaceContainerHigh,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  children: [
                    // App icon
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primaryContainer,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'T',
                        style: textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // App name
                    Text(
                      'Tempo',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Version badge (pill)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'Version v$_appVersion',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.onPrimaryContainer,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Description
                    Text(
                      'A Nothing OS-inspired alarm, timer, and stopwatch app crafted with Flutter.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Info chips
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildChip(cs, Icons.code_rounded, 'Open source'),
                        _buildChip(cs, Icons.palette_rounded, 'M3 Expressive'),
                        _buildChip(cs, Icons.person_rounded, 'Mohamed'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            cs,
                            Icons.code_rounded,
                            'GitHub',
                            'https://github.com/MoHamed-B-M/Tempo',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            cs,
                            Icons.telegram_rounded,
                            'Telegram',
                            'https://t.me/tempo_app',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            // ── What's New card ────────────────────────────────────
            if (!_loadingNotes) ...[
              if (_releaseNotes.isNotEmpty) ...[
                Card(
                  color: cs.surfaceContainerHigh,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.new_releases_rounded,
                                size: 18, color: cs.primary),
                            const SizedBox(width: 8),
                            Text(
                              "WHAT'S NEW IN v$_appVersion",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurfaceVariant,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ..._buildChangelogItems(cs),
                      ],
                    ),
                  ),
                ),
              ],
            ] else ...[
              Card(
                color: cs.surfaceContainerHigh,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Row(
                    children: [
                      Icon(Icons.new_releases_rounded,
                          size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(
                        "WHAT'S NEW IN v$_appVersion",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip(ColorScheme cs, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(ColorScheme cs, IconData icon, String label, String url) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          HapticFeedback.lightImpact();
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildChangelogItems(ColorScheme cs) {
    final seen = <String>{};
    final widgets = <Widget>[];
    for (final line in _releaseNotes) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) continue;
      seen.add(trimmed);

      final isSubHeading = trimmed.startsWith('###');
      final display = trimmed
          .replaceAll(RegExp(r'^###\s*'), '')
          .replaceAll(RegExp(r'^-\s*'), '')
          .trim();

      if (isSubHeading && display.isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            display.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cs.primary,
              letterSpacing: 1.2,
            ),
          ),
        ));
        continue;
      }

      if (display.isEmpty) continue;

      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                display,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurface,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ));
    }
    return widgets;
  }
}
