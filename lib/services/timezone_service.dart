import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class TimezoneService {
  TimezoneService._();
  static final TimezoneService _instance = TimezoneService._();
  static TimezoneService get instance => _instance;

  bool _initialized = false;
  late final List<String> _allLocations;

  void initialize() {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    _allLocations = tz.timeZoneDatabase.locations.keys
        .where((id) => !id.startsWith('Etc/') && !id.startsWith('SystemV/'))
        .toList()
      ..sort();
    _initialized = true;
  }

  List<String> get allLocations => List.unmodifiable(_allLocations);

  String cityName(String tzId) =>
      tzId.split('/').last.replaceAll('_', ' ');

  String regionName(String tzId) {
    final parts = tzId.split('/');
    return parts.length > 1 ? parts[0].replaceAll('_', ' ') : '';
  }

  List<String> search(String query, {Set<String>? exclude}) {
    if (query.isEmpty) return _allLocations;
    final lower = query.toLowerCase();
    return _allLocations.where((id) {
      if (exclude?.contains(id) == true) return false;
      return id.toLowerCase().contains(lower) ||
          cityName(id).toLowerCase().contains(lower);
    }).toList();
  }

  tz.Location? location(String tzId) {
    try {
      return tz.getLocation(tzId);
    } catch (_) {
      return null;
    }
  }
}
