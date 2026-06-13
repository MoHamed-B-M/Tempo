import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/changelog_dialog.dart';
import '../core/changelog_parser.dart';
import '../core/hive_helper.dart';
import 'update_service.dart';

class UpdateManager {
  static const _channelKey = 'update_channel';

  static Future<String> getSavedChannel() async {
    return HiveHelper.settings.get(_channelKey) as String? ?? 'stable';
  }

  static Future<void> saveChannel(String channel) async {
    await HiveHelper.settings.put(_channelKey, channel);
  }

  static Future<String> getCurrentVersion() async {
    try {
      final service = UpdateService.instance;
      return await service.getCurrentVersion();
    } catch (_) {
      return '0.0.0';
    }
  }

  static Future<void> checkForVersionChange(BuildContext context) async {
    const lastSeenKey = 'last_seen_version';
    final box = HiveHelper.settings;
    final lastSeen = box.get(lastSeenKey) as String?;

    final currentVersion = await getCurrentVersion();
    if (currentVersion == '0.0.0') return;

    if (lastSeen == null || lastSeen.isEmpty) {
      await box.put(lastSeenKey, currentVersion);
      return;
    }

    if (currentVersion == lastSeen) return;

    try {
      final current = Version.parse(currentVersion);
      final last = Version.parse(lastSeen);
      if (current <= last) {
        await box.put(lastSeenKey, currentVersion);
        return;
      }
    } catch (_) {
      return;
    }

    final entries =
        await ChangelogParser.getChangelogForVersion(currentVersion);
    if (entries.isEmpty) {
      await box.put(lastSeenKey, currentVersion);
      return;
    }

    if (!context.mounted) return;
    await showChangelogDialog(context, currentVersion, entries);
    await box.put(lastSeenKey, currentVersion);
  }

  static Future<void> checkAndShowUpdate(
    BuildContext context, {
    bool silent = false,
  }) async {
    final channelStr = await getSavedChannel();
    final channel = UpdateChannelX.fromString(channelStr);

    final service = UpdateService.instance;
    final response = await service.checkForUpdate(
      channel: channel,
      forceRefresh: !silent,
    );

    if (!context.mounted) return;

    switch (response.result) {
      case UpdateCheckResult.networkError:
        if (!silent) {
          _showSnackBar(context, 'Could not check for updates. Check your connection.');
        }
        break;
      case UpdateCheckResult.noConnection:
        if (!silent) {
          _showSnackBar(context, 'No internet connection');
        }
        break;
      case UpdateCheckResult.invalidResponse:
        if (!silent) {
          _showSnackBar(context, 'Update check failed: invalid response');
        }
        break;
      case UpdateCheckResult.upToDate:
        if (!silent) {
          _showSnackBar(context, 'You are on the latest version');
        }
        break;
      case UpdateCheckResult.available:
        final info = response.info!;
        if (context.mounted) {
          _showUpdateSheet(context, info, channel);
        }
        break;
    }
  }

  static void _showSnackBar(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: cs.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _showUpdateSheet(
    BuildContext context,
    VersionInfo info,
    UpdateChannel channel,
  ) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        final sheetCs = Theme.of(ctx).colorScheme;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: sheetCs.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: sheetCs.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.system_update_alt_rounded,
                      color: sheetCs.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UPDATE AVAILABLE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: sheetCs.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Version ${info.version} (${channel.label})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: sheetCs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (info.changelog.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sheetCs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    info.changelog,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: sheetCs.onSurface,
                      height: 1.5,
                    ),
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _launchDownload(info.downloadUrl);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sheetCs.primary,
                    foregroundColor: sheetCs.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'DOWNLOAD',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: sheetCs.onPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'NOT NOW',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sheetCs.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _launchDownload(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
