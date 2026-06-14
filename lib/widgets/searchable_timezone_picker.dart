import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/timezone_service.dart';

Future<String?> showSearchableTimezonePicker(
  BuildContext context, {
  Set<String>? exclude,
}) {
  HapticFeedback.mediumImpact();
  final cs = Theme.of(context).colorScheme;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SearchableTimezonePicker(cs: cs, exclude: exclude),
  );
}

class _SearchableTimezonePicker extends ConsumerStatefulWidget {
  final ColorScheme cs;
  final Set<String>? exclude;

  const _SearchableTimezonePicker({required this.cs, this.exclude});

  @override
  ConsumerState<_SearchableTimezonePicker> createState() =>
      _SearchableTimezonePickerState();
}

class _SearchableTimezonePickerState
    extends ConsumerState<_SearchableTimezonePicker> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _query = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final tz = TimezoneService.instance;
    final filtered = tz.search(_query, exclude: widget.exclude);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 48, height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'ADD LOCATION',
                  style: GoogleFonts.nunito(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: cs.onSurface, letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: GoogleFonts.nunito(
                    fontSize: 14, color: cs.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search timezone or city...',
                    hintStyle: GoogleFonts.nunito(
                      fontSize: 14, color: cs.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: cs.surfaceContainerHigh,
                    prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: cs.onSurfaceVariant),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      _query.isEmpty ? 'Type to search timezones' : 'No timezones found',
                      style: GoogleFonts.nunito(
                        fontSize: 13, color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final tzId = filtered[index];
                      final name = tz.cityName(tzId);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.pop(context, tzId),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.public, color: cs.primary, size: 20,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: GoogleFonts.nunito(
                                        fontSize: 14, fontWeight: FontWeight.w600,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: cs.onSurfaceVariant, size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
