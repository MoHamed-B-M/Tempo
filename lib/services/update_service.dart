import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

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

  String get version {
    final stripped = tagName.startsWith(RegExp(r'[vV]'))
        ? tagName.substring(1)
        : tagName;
    return stripped.toLowerCase();
  }

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
  static const _maxRetries = 3;

  final http.Client _client;

  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  Future<UpdateCheckResponse> checkForUpdate() async {
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          final delay = Duration(
            milliseconds: (pow(2, attempt) * 1000).toInt(),
          );
          debugPrint('[UpdateService] Retry $attempt after ${delay.inSeconds}s');
          await Future.delayed(delay);
        }

        final response = await _client
            .get(
              Uri.parse(_apiUrl),
              headers: {
                'Accept': 'application/vnd.github.v3+json',
                'User-Agent': 'Tempo-App',
              },
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 404) {
          debugPrint('[UpdateService] Repo not found (404)');
          return UpdateCheckResponse(result: UpdateCheckResult.repoNotFound);
        }

        if (response.statusCode == 403) {
          debugPrint('[UpdateService] Rate limited (403)');
          return UpdateCheckResponse(result: UpdateCheckResult.rateLimited);
        }

        if (response.statusCode != 200) {
          debugPrint('[UpdateService] HTTP ${response.statusCode}');
          if (attempt < _maxRetries - 1) continue;
          return UpdateCheckResponse(result: UpdateCheckResult.networkError);
        }

        final body = response.body;
        if (body.isEmpty) {
          debugPrint('[UpdateService] Empty response body');
          if (attempt < _maxRetries - 1) continue;
          return UpdateCheckResponse(result: UpdateCheckResult.noReleases);
        }

        final json = jsonDecode(body) as Map<String, dynamic>;
        final tagName = json['tag_name'] as String?;
        if (tagName == null || tagName.isEmpty) {
          debugPrint('[UpdateService] Missing tag_name in response');
          if (attempt < _maxRetries - 1) continue;
          return UpdateCheckResponse(result: UpdateCheckResult.noReleases);
        }

        return UpdateCheckResponse(
          result: UpdateCheckResult.available,
          release: ReleaseInfo.fromJson(json),
        );
      } on http.ClientException catch (e) {
        debugPrint('[UpdateService] ClientException (attempt $attempt): $e');
        if (attempt < _maxRetries - 1) continue;
        return UpdateCheckResponse(result: UpdateCheckResult.networkError);
      } on FormatException catch (e) {
        debugPrint('[UpdateService] FormatException (attempt $attempt): $e');
        if (attempt < _maxRetries - 1) continue;
        return UpdateCheckResponse(result: UpdateCheckResult.networkError);
      } catch (e) {
        debugPrint('[UpdateService] Unexpected error (attempt $attempt): $e');
        if (attempt < _maxRetries - 1) continue;
        return UpdateCheckResponse(result: UpdateCheckResult.networkError);
      }
    }

    return UpdateCheckResponse(result: UpdateCheckResult.networkError);
  }

  void dispose() {
    _client.close();
  }
}
