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
      parts.length > 0 ? int.tryParse(parts[0]) ?? 0 : 0,
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
    final release = await service.checkForUpdate(channel);
    service.dispose();

    if (release == null) {
      if (!silent && context.mounted) {
        _showNoUpdateSnackBar(context);
      }
      return;
    }

    final currentVersion = await getCurrentVersion();
    final remoteVersion = stripV(release.tagName);

    if (!isNewer(remoteVersion, currentVersion)) {
      if (!silent && context.mounted) {
        _showNoUpdateSnackBar(context);
      }
      return;
    }

    if (context.mounted) {
      _showUpdateDialog(context, release);
    }
  }

  static void _showNoUpdateSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('You are on the latest version'),
        backgroundColor: const Color(0xFF0E0E0E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _showUpdateDialog(BuildContext context, ReleaseInfo release) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0E0E0E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF1A1A1A)),
        ),
        title: Text(
          'Update Available',
          style: TextStyle(
            color: Colors.white,
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
                color: Colors.white.withValues(alpha: 0.7),
                letterSpacing: 0.5,
              ),
            ),
            if (release.body.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                release.body,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
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
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 1,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _launchReleaseUrl(release.url);
            },
            child: const Text(
              'Update Now',
              style: TextStyle(
                color: Colors.white,
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
