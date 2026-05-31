import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class LocationInfo {
  final String name;
  final String timezoneId; // For relative time calculations
  final double utcOffset;   // In hours

  LocationInfo({
    required this.name,
    required this.timezoneId,
    required this.utcOffset,
  });
}

class WorldClockTab extends StatefulWidget {
  const WorldClockTab({super.key});

  @override
  State<WorldClockTab> createState() => _WorldClockTabState();
}

class _WorldClockTabState extends State<WorldClockTab> {
  late Timer _timer;
  late DateTime _currentTime;
  String? _highlightedLocation; // Tap to highlight orange

  // Default cities shown in Screen 1
  final List<LocationInfo> _locations = [
    LocationInfo(name: 'Tokyo', timezoneId: 'Asia/Tokyo', utcOffset: 9.0),
    LocationInfo(name: 'Mumbai', timezoneId: 'Asia/Kolkata', utcOffset: 5.5),
    LocationInfo(name: 'Los Angeles', timezoneId: 'America/Los_Angeles', utcOffset: -7.0),
  ];

  // List of other cities available to add
  final List<LocationInfo> _availableLocations = [
    LocationInfo(name: 'London', timezoneId: 'Europe/London', utcOffset: 1.0),
    LocationInfo(name: 'New York', timezoneId: 'America/New_York', utcOffset: -4.0),
    LocationInfo(name: 'Sydney', timezoneId: 'Australia/Sydney', utcOffset: 10.0),
    LocationInfo(name: 'Cairo', timezoneId: 'Africa/Cairo', utcOffset: 3.0),
    LocationInfo(name: 'Dubai', timezoneId: 'Asia/Dubai', utcOffset: 4.0),
    LocationInfo(name: 'Singapore', timezoneId: 'Asia/Singapore', utcOffset: 8.0),
    LocationInfo(name: 'Paris', timezoneId: 'Europe/Paris', utcOffset: 2.0),
  ];

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
    // Pre-highlight Mumbai to match mockup Screen 1
    _highlightedLocation = 'Mumbai';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatLocalTime(DateTime time) {
    return DateFormat('h:mm').format(time);
  }

  String _formatLocalAmPm(DateTime time) {
    return DateFormat('a').format(time).toLowerCase();
  }

  String _formatLocalDate(DateTime time) {
    return DateFormat('EEE, d MMM').format(time);
  }

  String _getCityTime(double offset) {
    // Calculate UTC
    final utc = _currentTime.toUtc();
    // Apply offset
    final cityTime = utc.add(Duration(minutes: (offset * 60).round()));
    return DateFormat('h:mm').format(cityTime);
  }

  String _getCityAmPm(double offset) {
    final utc = _currentTime.toUtc();
    final cityTime = utc.add(Duration(minutes: (offset * 60).round()));
    return DateFormat('a').format(cityTime).toLowerCase();
  }

  String _getRelativeTimeDiffText(double offset) {
    // Current local offset
    final localOffset = _currentTime.timeZoneOffset.inMinutes / 60.0;
    final diff = offset - localOffset;
    final diffInt = diff.round();
    if (diffInt == 0) return 'Same time';
    final sign = diffInt > 0 ? '+' : '';
    return '$sign${diffInt}h';
  }

  void _showAddCitySheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = _availableLocations.where((loc) {
              final alreadyAdded = _locations.any((l) => l.name == loc.name);
              return !alreadyAdded && loc.name.toLowerCase().contains(query.toLowerCase());
            }).toList();

            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 40,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryTextOf(context).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'ADD LOCATION',
                    style: AppTextStyles.buttonLabel(context).copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  TextField(
                    onChanged: (val) {
                      setModalState(() {
                        query = val;
                      });
                    },
                    style: AppTextStyles.body(context),
                    decoration: InputDecoration(
                      hintText: 'Search city name...',
                      hintStyle: AppTextStyles.subheading(context),
                      filled: true,
                      fillColor: AppColors.surfaceCardOf(context),
                      prefixIcon: Icon(Icons.search, color: AppColors.secondaryTextOf(context)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'No cities found',
                                style: AppTextStyles.subheading(context),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (ctx, index) {
                              final loc = filtered[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.public, color: AppColors.accentOf(context)),
                                title: Text(
                                  loc.name,
                                  style: AppTextStyles.body(context),
                                ),
                                trailing: Text(
                                  'UTC ${loc.utcOffset >= 0 ? '+' : ''}${loc.utcOffset}',
                                  style: AppTextStyles.subheading(context),
                                ),
                                onTap: () {
                                  setState(() {
                                    _locations.add(loc);
                                  });
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'World Clock',
                style: AppTextStyles.heading(context),
              ),
              const SizedBox(height: 24),
              // Big Local Clock (Styled like 5:15pm in Screen 1)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _formatLocalTime(_currentTime),
                          style: AppTextStyles.displayTime(context),
                        ),
                        Text(
                          _formatLocalAmPm(_currentTime),
                          style: AppTextStyles.displayTime(context).copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatLocalDate(_currentTime).toUpperCase(),
                      style: AppTextStyles.subheading(context).copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              Text(
                'LOCATIONS',
                style: AppTextStyles.buttonLabel(context).copyWith(
                  color: AppColors.secondaryTextOf(context),
                ),
              ),
              const SizedBox(height: 12),
              // Global Locations List
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _locations.length,
                  padding: const EdgeInsets.only(bottom: 100),
                  itemBuilder: (ctx, index) {
                    final loc = _locations[index];
                    final isHighlighted = _highlightedLocation == loc.name;
                    final timeStr = _getCityTime(loc.utcOffset);
                    final amPmStr = _getCityAmPm(loc.utcOffset);
                    final diffText = _getRelativeTimeDiffText(loc.utcOffset);

                    return Dismissible(
                      key: ValueKey(loc.name),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        setState(() {
                          _locations.removeAt(index);
                          if (isHighlighted) _highlightedLocation = null;
                        });
                      },
                      background: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _highlightedLocation = isHighlighted ? null : loc.name;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          decoration: BoxDecoration(
                            color: isHighlighted ? AppColors.accentOf(context) : AppColors.surfaceCardOf(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isHighlighted ? Colors.transparent : AppColors.borderOf(context),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.name,
                                    style: AppTextStyles.body(context).copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: isHighlighted ? Colors.white : AppColors.primaryTextOf(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    diffText,
                                    style: AppTextStyles.subheading(context).copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isHighlighted ? Colors.white.withValues(alpha: 0.8) : AppColors.secondaryTextOf(context),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    timeStr,
                                    style: AppTextStyles.alarmTime(context).copyWith(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: isHighlighted ? Colors.white : AppColors.primaryTextOf(context),
                                    ),
                                  ),
                                  Text(
                                    amPmStr,
                                    style: AppTextStyles.subheading(context).copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isHighlighted ? Colors.white : AppColors.primaryTextOf(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Add Location button matching Screen 1's squircle "+" button
        Positioned(
          right: 24,
          bottom: 24,
          child: GestureDetector(
            onTap: _showAddCitySheet,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.accentOf(context),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentOf(context).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
