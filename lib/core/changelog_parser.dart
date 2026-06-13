import 'package:flutter/services.dart';

class ChangelogParser {
  static Map<String, List<String>>? _cache;

  static Future<Map<String, List<String>>> parse() async {
    if (_cache != null) return _cache!;
    final manifest = await rootBundle.loadString('CHANGELOG.md');
    _cache = _parseString(manifest);
    return _cache!;
  }

  static Map<String, List<String>> _parseString(String content) {
    final result = <String, List<String>>{};
    final lines = content.split('\n');
    String? currentVersion;
    final entries = <String>[];

    for (final line in lines) {
      if (line.startsWith('## ')) {
        if (currentVersion != null && entries.isNotEmpty) {
          result[currentVersion] = List.from(entries);
          entries.clear();
        }
        final match = RegExp(r'\[([\w.]+)\]').firstMatch(line);
        currentVersion = match?.group(1);
      } else if (currentVersion != null && line.trim().isNotEmpty) {
        entries.add(line);
      }
    }

    if (currentVersion != null && entries.isNotEmpty) {
      result[currentVersion] = List.from(entries);
    }
    return result;
  }

  static Future<List<String>> getChangelogForVersion(String version) async {
    final parsed = await parse();
    return parsed[version] ?? [];
  }

  static void clearCache() => _cache = null;
}
