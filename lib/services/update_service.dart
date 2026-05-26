import 'dart:convert';
import 'package:http/http.dart' as http;

enum UpdateCheckResult {
  available,
  upToDate,
  noReleases,
  repoNotFound,
  networkError,
}

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

  String get version =>
      tagName.startsWith('v') ? tagName.substring(1) : tagName;

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

class UpdateCheckResponse {
  final UpdateCheckResult result;
  final ReleaseInfo? release;

  UpdateCheckResponse({required this.result, this.release});
}

class UpdateService {
  static const _apiUrl =
      'https://api.github.com/repos/MoHamed-B-M/Tempo/releases';

  final http.Client _client;

  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  Future<UpdateCheckResponse> checkForUpdate(String channel) async {
    try {
      final response = await _client.get(
        Uri.parse(_apiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Tempo-App',
        },
      );

      if (response.statusCode == 404) {
        return UpdateCheckResponse(result: UpdateCheckResult.repoNotFound);
      }

      if (response.statusCode != 200) {
        return UpdateCheckResponse(result: UpdateCheckResult.networkError);
      }

      final List<dynamic> releases = jsonDecode(response.body) as List;

      if (releases.isEmpty) {
        return UpdateCheckResponse(result: UpdateCheckResult.noReleases);
      }

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

      if (filtered.isEmpty) {
        return UpdateCheckResponse(result: UpdateCheckResult.noReleases);
      }

      filtered.sort((a, b) {
        final aTag = (a['tag_name'] as String?) ?? '';
        final bTag = (b['tag_name'] as String?) ?? '';
        return _compareVersions(bTag, aTag);
      });

      return UpdateCheckResponse(
        result: UpdateCheckResult.available,
        release: ReleaseInfo.fromJson(filtered.first),
      );
    } catch (_) {
      return UpdateCheckResponse(result: UpdateCheckResult.networkError);
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
