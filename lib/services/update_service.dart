import 'dart:convert';
import 'package:http/http.dart' as http;

class ReleaseInfo {
  final String tagName;
  final String url;
  final String body;
  final bool prerelease;
  final String? apkDownloadUrl;

  ReleaseInfo({
    required this.tagName,
    required this.url,
    required this.body,
    required this.prerelease,
    this.apkDownloadUrl,
  });

  String get version => tagName.startsWith('v') ? tagName.substring(1) : tagName;

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    final assets = json['assets'] as List?;
    String? apkUrl;
    if (assets != null) {
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String?;
          break;
        }
      }
    }
    return ReleaseInfo(
      tagName: json['tag_name'] as String? ?? '',
      url: json['html_url'] as String? ?? '',
      body: json['body'] as String? ?? '',
      prerelease: json['prerelease'] as bool? ?? false,
      apkDownloadUrl: apkUrl,
    );
  }
}

class UpdateService {
  static const _apiUrl = 'https://api.github.com/repos/MoHamed-B-M/Tempo/releases';

  final http.Client _client;

  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  Future<ReleaseInfo?> checkForUpdate(String channel) async {
    try {
      final response = await _client.get(
        Uri.parse(_apiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Tempo-App',
        },
      );

      if (response.statusCode != 200) return null;

      final List<dynamic> releases = jsonDecode(response.body) as List;

      List<Map<String, dynamic>> filtered;
      if (channel == 'beta') {
        filtered = releases
            .where((r) => r['prerelease'] == true)
            .map((r) => r as Map<String, dynamic>)
            .toList();
      } else {
        filtered = releases
            .where((r) => r['prerelease'] == false)
            .map((r) => r as Map<String, dynamic>)
            .toList();
      }

      if (filtered.isEmpty) return null;

      filtered.sort((a, b) {
        final aTag = (a['tag_name'] as String?) ?? '';
        final bTag = (b['tag_name'] as String?) ?? '';
        return _compareVersions(bTag, aTag);
      });

      return ReleaseInfo.fromJson(filtered.first);
    } catch (_) {
      return null;
    }
  }

  int _compareVersions(String a, String b) {
    final aParts = _parseVersion(a);
    final bParts = _parseVersion(b);
    for (var i = 0; i < 3; i++) {
      if (aParts[i] != bParts[i]) return aParts[i].compareTo(bParts[i]);
    }
    return 0;
  }

  List<int> _parseVersion(String tag) {
    final v = tag.startsWith('v') ? tag.substring(1) : tag;
    final base = v.split('-')[0];
    final parts = base.split('.');
    return [
      parts.length > 0 ? int.tryParse(parts[0]) ?? 0 : 0,
      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
    ];
  }

  void dispose() {
    _client.close();
  }
}
