import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> showChangelogDialog(
  BuildContext context,
  String version,
  List<String> entries,
) async {
  final cleaned = _cleanEntries(entries);

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final dialogCs = Theme.of(ctx).colorScheme;
      return Dialog(
        backgroundColor: dialogCs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dialogCs.primary.withValues(alpha: 0.15),
                ),
                child: Icon(
                  Icons.new_releases_rounded,
                  color: dialogCs.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'WHAT\'S NEW',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: dialogCs.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'v$version',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: dialogCs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: dialogCs.surfaceContainerHigh,
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: cleaned.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final line = cleaned[i];
                        final isSubHeading = line.startsWith('###');
                        final display = line
                            .replaceAll(RegExp(r'^###\s*'), '')
                            .replaceAll(RegExp(r'^-\s*'), '')
                            .trim();

                        if (isSubHeading && display.isNotEmpty) {
                          return Text(
                            display.toUpperCase(),
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: dialogCs.primary,
                              letterSpacing: 1.2,
                            ),
                          );
                        }

                        if (display.isEmpty) return const SizedBox.shrink();

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: dialogCs.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                display,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: dialogCs.onSurface,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dialogCs.primary,
                    foregroundColor: dialogCs.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'GOT IT',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: dialogCs.onPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

List<String> _cleanEntries(List<String> entries) {
  final seen = <String>{};
  final result = <String>[];
  for (final entry in entries) {
    final trimmed = entry.trim();
    if (trimmed.isEmpty) continue;
    if (seen.contains(trimmed)) continue;
    seen.add(trimmed);
    result.add(trimmed);
  }
  return result;
}
