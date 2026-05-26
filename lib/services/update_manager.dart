import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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
    return tag.startsWith('v') ? tag.substring(1) : tag;
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
    final channel = await getSavedChannel();
    final service = UpdateService();
    final response = await service.checkForUpdate(channel);
    service.dispose();

    if (!context.mounted) return;

    switch (response.result) {
      case UpdateCheckResult.repoNotFound:
        if (!silent) {
          _showSnackBar(context,
              'Update check failed: repository not found');
        }
      case UpdateCheckResult.networkError:
        if (!silent) {
          _showSnackBar(context,
              'Could not check for updates. Check your connection.');
        }
      case UpdateCheckResult.noReleases:
        if (!silent) {
          _showSnackBar(context, 'No releases found on this channel');
        }
      case UpdateCheckResult.upToDate:
        if (!silent) {
          _showSnackBar(context, 'You are on the latest version');
        }
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
          _showUpdateDialog(context, release);
        }
    }
  }

  static void _showSnackBar(BuildContext context, String message) {
    final brightness = Theme.of(context).brightness;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF0E0E0E)
            : const Color(0xFFF2F2F2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _showUpdateDialog(BuildContext context, ReleaseInfo release) {
    final brightness = Theme.of(context).brightness;
    final bgColor = brightness == Brightness.dark
        ? const Color(0xFF0E0E0E)
        : const Color(0xFFFFFFFF);
    final textColor = brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    final dimColor = brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: brightness == Brightness.dark
                ? const Color(0xFF1A1A1A)
                : const Color(0xFFE5E5EA),
          ),
        ),
        title: Text(
          'Update Available',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${release.version}',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
                letterSpacing: 0.5,
              ),
            ),
            if (release.body.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                release.body,
                style: TextStyle(color: dimColor, fontSize: 13),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: dimColor, letterSpacing: 1),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _launchReleaseUrl(release.url);
            },
            child: Text(
              'Update Now',
              style: TextStyle(
                color: textColor,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _launchReleaseUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
