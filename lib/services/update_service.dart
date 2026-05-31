import 'dart:convert';
import 'package:http/http.dart' as http;

enum UpdateCheckResult {
  available,
  upToDate,
  noReleases,
  repoNotFound,
  rateLimited,
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
      'https://api.github.com/repos/MoHamed-B-M/Tempo/releases/latest';

  final http.Client _client;

  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  Future<UpdateCheckResponse> checkForUpdate() async {
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

      if (response.statusCode == 403) {
        return UpdateCheckResponse(result: UpdateCheckResult.rateLimited);
      }

      if (response.statusCode != 200) {
        return UpdateCheckResponse(result: UpdateCheckResult.networkError);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      return UpdateCheckResponse(
        result: UpdateCheckResult.available,
        release: ReleaseInfo.fromJson(json),
      );
    } catch (_) {
      return UpdateCheckResponse(result: UpdateCheckResult.networkError);
    }
  }

  void dispose() {
    _client.close();
  }
}
