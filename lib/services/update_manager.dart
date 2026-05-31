import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'update_service.dart';

class UpdateManager {
  static const _channelKey = 'update_channel';

  static Future<String> getSavedChannel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_channelKey) ?? 'stable';
  }

  static Future<void> saveChannel(String channel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_channelKey, channel);
  }

  static Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  static String stripV(String tag) {
    final stripped = tag.startsWith(RegExp(r'[vV]')) ? tag.substring(1) : tag;
    return stripped.toLowerCase();
  }

  static List<int> parseVersion(String v) {
    final parts = v.split('.');
    return [
      parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0,
      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
    ];
  }

  static bool isNewer(String remoteVersion, String currentVersion) {
    final remote = parseVersion(remoteVersion);
    final current = parseVersion(currentVersion);
    for (var i = 0; i < 3; i++) {
      if (remote[i] > current[i]) return true;
      if (remote[i] < current[i]) return false;
    }
    return false;
  }

  static Future<void> checkAndShowUpdate(
    BuildContext context, {
    bool silent = false,
  }) async {
    final service = UpdateService();
    final response = await service.checkForUpdate();
    service.dispose();

    if (!context.mounted) return;

    switch (response.result) {
      case UpdateCheckResult.repoNotFound:
        if (!silent) {
          _showSnackBar(context, 'Update check failed: repository not found');
        }
        break;
      case UpdateCheckResult.rateLimited:
        if (!silent) {
          _showSnackBar(context, 'Rate limited. Try again later.');
        }
        break;
      case UpdateCheckResult.networkError:
        if (!silent) {
          _showSnackBar(
            context,
            'Could not check for updates. Check your connection.',
          );
        }
        break;
      case UpdateCheckResult.noReleases:
        if (!silent) {
          _showSnackBar(context, 'No releases found');
        }
        break;
      case UpdateCheckResult.upToDate:
        if (!silent) {
          _showSnackBar(context, 'You are on the latest version');
        }
        break;
      case UpdateCheckResult.available:
        final release = response.release!;
        final currentVersion = await getCurrentVersion();
        final remoteVersion = stripV(release.tagName);

        if (!isNewer(remoteVersion, currentVersion)) {
          if (!silent) {
            _showSnackBar(context, 'You are on the latest version');
          }
          return;
        }

        if (context.mounted) {
          _showUpdateSheet(context, release);
        }
        break;
    }
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surfaceCardOf(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _showUpdateSheet(BuildContext context, ReleaseInfo release) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
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
                    color: AppColors.secondaryTextOf(ctx)
                        .withValues(alpha: 0.3),
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
                      color: AppColors.accentOf(ctx)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.system_update_alt_rounded,
                      color: AppColors.accentOf(ctx),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UPDATE AVAILABLE',
                        style: AppTextStyles.buttonLabel(ctx).copyWith(
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Version ${release.version}',
                        style: AppTextStyles.body(ctx).copyWith(
                          fontSize: 13,
                          color: AppColors.secondaryTextOf(ctx),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (release.body.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCardOf(ctx),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    release.body,
                    style: AppTextStyles.body(ctx).copyWith(
                      fontSize: 13,
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
                    _launchReleaseUrl(release.url);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentOf(ctx),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'DOWNLOAD',
                    style: AppTextStyles.buttonLabel(ctx).copyWith(
                      color: Colors.white,
                      fontSize: 14,
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
                    style: AppTextStyles.buttonLabel(ctx).copyWith(
                      color: AppColors.secondaryTextOf(ctx),
                      fontSize: 13,
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

  static Future<void> _launchReleaseUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
