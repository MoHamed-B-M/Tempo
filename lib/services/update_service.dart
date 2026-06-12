import 'dart:convert';
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

  VersionInfo({
    required this.version,
    required this.downloadUrl,
    this.changelog = '',
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json, UpdateChannel channel) {
    return VersionInfo(
      version: json[channel.versionKey] as String? ?? '',
      downloadUrl: json[channel.urlKey] as String? ?? '',
      changelog: json[channel.changelogKey] as String? ?? '',
    );
  }

  Version get semver {
    try {
      return Version.parse(version.startsWith(RegExp(r'[vV]'))
          ? version.substring(1)
          : version);
    } catch (_) {
      return Version(0, 0, 0);
    }
  }
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
  static const _versionUrl =
      'https://raw.githubusercontent.com/MoHamed-B-M/Tempo/main/version.json';
  static const _cacheKey = 'cached_version_json';
  static const _cacheTimestampKey = 'cached_version_timestamp';
  static const _cacheDuration = Duration(hours: 2);

  static final UpdateService _instance = UpdateService._();
  static UpdateService get instance => _instance;

  final http.Client _client;

  Map<String, dynamic>? _lastFetched;
  DateTime? _lastFetchTime;

  UpdateService._({http.Client? client})
      : _client = client ?? http.Client();

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
      final json = await _fetchVersionJson(forceRefresh: forceRefresh);
      if (json == null) {
        return const UpdateCheckResponse(result: UpdateCheckResult.networkError);
      }

      final remote = VersionInfo.fromJson(json, channel);
      if (remote.version.isEmpty) {
        debugPrint('[UpdateService] No version info for channel ${channel.label}');
        return const UpdateCheckResponse(result: UpdateCheckResult.invalidResponse);
      }

      final currentVersion = await getCurrentVersion();
      final current = Version.parse(currentVersion);
      final remoteSemver = remote.semver;

      debugPrint('[UpdateService] Current: $current, Remote: $remoteSemver (${channel.label})');

      if (remoteSemver > current) {
        return UpdateCheckResponse(
          result: UpdateCheckResult.available,
          info: remote,
        );
      }

      return const UpdateCheckResponse(result: UpdateCheckResult.upToDate);
    } on Exception catch (e) {
      debugPrint('[UpdateService] Error: $e');
      return const UpdateCheckResponse(result: UpdateCheckResult.networkError);
    }
  }

  Future<Map<String, dynamic>?> _fetchVersionJson({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _lastFetched != null && _lastFetchTime != null) {
      final age = DateTime.now().difference(_lastFetchTime!);
      if (age < _cacheDuration) {
        return _lastFetched;
      }
    }

    final cached = await _readCached();
    if (!forceRefresh && cached != null) {
      return cached;
    }

    try {
      final response = await _client
          .get(
            Uri.parse(_versionUrl),
            headers: {'User-Agent': 'Tempo-App'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('[UpdateService] HTTP ${response.statusCode}, using cache');
        return cached;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      _lastFetched = json;
      _lastFetchTime = DateTime.now();
      await _writeCache(json);
      return json;
    } catch (e) {
      debugPrint('[UpdateService] Fetch failed: $e, using cache');
      return cached;
    }
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

  Future<Map<String, dynamic>?> _readCached() async {
    try {
      final box = HiveHelper.settings;
      final jsonStr = box.get(_cacheKey) as String?;
      final timestamp = box.get(_cacheTimestampKey) as int?;
      if (jsonStr == null || timestamp == null) return null;

      final cachedTime =
          DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cachedTime) > _cacheDuration) {
        return null;
      }

      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(Map<String, dynamic> json) async {
    try {
      final box = HiveHelper.settings;
      await box.put(_cacheKey, jsonEncode(json));
      await box.put(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
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
