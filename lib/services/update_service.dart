import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import '../core/hive_helper.dart';

enum UpdateChannel { stable, beta }

extension UpdateChannelX on UpdateChannel {
  String get label => name;
  String get versionKey => 'latest_${name}_version';
  String get urlKey => 'latest_${name}_url';
  String get changelogKey => 'changelog_$name';

  static UpdateChannel fromString(String s) {
    return s == 'beta' ? UpdateChannel.beta : UpdateChannel.stable;
  }
}

class VersionInfo {
  final String version;
  final String downloadUrl;
  final String changelog;
  final String channel;

  VersionInfo({
    required this.version,
    required this.downloadUrl,
    this.changelog = '',
    this.channel = 'stable',
  });

  factory VersionInfo.fromGitHubRelease(
    Map<String, dynamic> json,
    UpdateChannel channel,
  ) {
    final String tagName = json['tag_name'] as String? ?? '';
    final String body = json['body'] as String? ?? '';
    final String htmlUrl = json['html_url'] as String? ?? '';
    final String version = tagName.startsWith(RegExp(r'[vV]'))
        ? tagName.substring(1)
        : tagName;

    return VersionInfo(
      version: version,
      downloadUrl: htmlUrl,
      changelog: body,
      channel: channel.label,
    );
  }

  factory VersionInfo.empty() => VersionInfo(version: '', downloadUrl: '');

  Version get semver {
    try {
      return Version.parse(
          version.startsWith(RegExp(r'[vV]')) ? version.substring(1) : version);
    } catch (_) {
      return Version(0, 0, 0);
    }
  }

  bool get isEmpty => version.isEmpty;
}

enum UpdateCheckResult {
  available,
  upToDate,
  networkError,
  noConnection,
  invalidResponse,
}

class UpdateCheckResponse {
  final UpdateCheckResult result;
  final VersionInfo? info;

  const UpdateCheckResponse({required this.result, this.info});
}

class UpdateService {
  static const _releasesUrl =
      'https://api.github.com/repos/MoHamed-B-M/Tempo/releases';
  static const _cacheKey = 'cached_releases_json';
  static const _cacheTimestampKey = 'cached_releases_timestamp';
  static const _cacheDuration = Duration(hours: 2);
  static const _requestTimeout = Duration(seconds: 8);

  static final Map<String, String> _apiHeaders = {
    'X-GitHub-Api-Version': '2026-03-10',
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'Tempo-App',
  };

  static final UpdateService _instance = UpdateService._();
  static UpdateService get instance => _instance;

  final http.Client _client;

  List<Map<String, dynamic>>? _lastFetched;
  DateTime? _lastFetchTime;

  UpdateService._({http.Client? client}) : _client = client ?? http.Client();

  factory UpdateService({http.Client? client}) {
    if (client != null) {
      _instance._client.close();
    }
    return _instance;
  }

  Future<UpdateCheckResponse> checkForUpdate({
    UpdateChannel channel = UpdateChannel.stable,
    bool forceRefresh = false,
  }) async {
    try {
      final releases = await _fetchReleases(forceRefresh: forceRefresh);
      if (releases == null) {
        return const UpdateCheckResponse(result: UpdateCheckResult.networkError);
      }

      final remote = _findLatestForChannel(releases, channel);
      if (remote.isEmpty) {
        debugPrint(
            '[UpdateService] No release found for channel ${channel.label}');
        return const UpdateCheckResponse(
            result: UpdateCheckResult.invalidResponse);
      }

      final currentVersion = await getCurrentVersion();
      final current = Version.parse(currentVersion);
      final remoteSemver = remote.semver;

      debugPrint(
          '[UpdateService] Current: $current, Remote: $remoteSemver (${channel.label})');

      if (remoteSemver > current) {
        return UpdateCheckResponse(
          result: UpdateCheckResult.available,
          info: remote,
        );
      }

      return const UpdateCheckResponse(result: UpdateCheckResult.upToDate);
    } on SocketException {
      debugPrint('[UpdateService] No internet connection');
      return const UpdateCheckResponse(result: UpdateCheckResult.noConnection);
    } on ClientException catch (e) {
      debugPrint('[UpdateService] Client error: $e');
      return const UpdateCheckResponse(result: UpdateCheckResult.networkError);
    } on TimeoutException {
      debugPrint('[UpdateService] Request timed out');
      return const UpdateCheckResponse(result: UpdateCheckResult.networkError);
    } on Exception catch (e) {
      debugPrint('[UpdateService] Error: $e');
      return const UpdateCheckResponse(result: UpdateCheckResult.networkError);
    }
  }

  VersionInfo _findLatestForChannel(
    List<Map<String, dynamic>> releases,
    UpdateChannel channel,
  ) {
    for (final release in releases) {
      final bool isPrerelease = release['prerelease'] as bool? ?? false;
      final bool match = channel == UpdateChannel.beta
          ? isPrerelease
          : !isPrerelease;

      if (match) {
        return VersionInfo.fromGitHubRelease(release, channel);
      }
    }
    return VersionInfo.empty();
  }

  Future<List<Map<String, dynamic>>?> _fetchReleases({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _lastFetched != null && _lastFetchTime != null) {
      final age = DateTime.now().difference(_lastFetchTime!);
      if (age < _cacheDuration) {
        return _lastFetched;
      }
    }

    final cached = await _readCached();

    try {
      final response = await _client
          .get(Uri.parse(_releasesUrl), headers: _apiHeaders)
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        final releases =
            jsonList.cast<Map<String, dynamic>>().toList();
        _lastFetched = releases;
        _lastFetchTime = DateTime.now();
        await _writeCache(releases);
        return releases;
      }

      debugPrint('[UpdateService] HTTP ${response.statusCode}');
    } on SocketException catch (e) {
      debugPrint('[UpdateService] Socket error (offline): $e');
    } on ClientException catch (e) {
      debugPrint('[UpdateService] Client error: $e');
    } on TimeoutException {
      debugPrint('[UpdateService] Request timed out');
    } catch (e) {
      debugPrint('[UpdateService] Fetch failed: $e');
    }

    if (cached != null) {
      debugPrint('[UpdateService] Using stale cache');
      return cached;
    }

    return null;
  }

  Future<String> getCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final v = info.version;
      await HiveHelper.settings.put('app_version', v);
      return v;
    } catch (_) {
      return '0.0.0';
    }
  }

  Future<List<Map<String, dynamic>>?> _readCached() async {
    try {
      final box = HiveHelper.settings;
      final jsonStr = box.get(_cacheKey) as String?;
      final timestamp = box.get(_cacheTimestampKey) as int?;
      if (jsonStr == null || timestamp == null) return null;

      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cachedTime) > _cacheDuration) {
        return null;
      }

      final List<dynamic> jsonList = jsonDecode(jsonStr) as List<dynamic>;
      return jsonList.cast<Map<String, dynamic>>().toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(List<Map<String, dynamic>> releases) async {
    try {
      final box = HiveHelper.settings;
      await box.put(_cacheKey, jsonEncode(releases));
      await box
          .put(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<int> clearCache() async {
    try {
      final box = HiveHelper.settings;
      await box.delete(_cacheKey);
      await box.delete(_cacheTimestampKey);
      _lastFetched = null;
      _lastFetchTime = null;
      return 0;
    } catch (_) {
      return -1;
    }
  }

  void dispose() {
    _client.close();
  }
}
