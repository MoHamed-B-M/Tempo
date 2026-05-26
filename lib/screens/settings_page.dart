import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/theme_service.dart';
import '../services/update_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _channel = 'stable';
  String _appVersion = '';
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final channel = await UpdateManager.getSavedChannel();
    final version = await UpdateManager.getCurrentVersion();
    setState(() {
      _channel = channel;
      _appVersion = version;
    });
  }

  Future<void> _setChannel(String channel) async {
    setState(() => _channel = channel);
    await UpdateManager.saveChannel(channel);
  }

  Future<void> _checkForUpdates() async {
    setState(() => _checking = true);
    await UpdateManager.checkAndShowUpdate(context, silent: false);
    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final isDark = themeService.isDark;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundOf(context),
        foregroundColor: AppColors.primaryTextOf(context),
        elevation: 0,
        title: Text(
          'SETTINGS',
          style: AppTextStyles.buttonLabel(context).copyWith(fontSize: 14),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              color: AppColors.borderOf(context), height: 1, thickness: 0.5),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('APPEARANCE'),
            const SizedBox(height: 12),
            _buildToggleTile(
              'Dark Mode',
              isDark,
              (value) => themeService.setMode(
                value ? ThemeMode.dark : ThemeMode.light,
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('APP VERSION'),
            const SizedBox(height: 12),
            _buildInfoTile(
              'Current Version',
              _appVersion.isNotEmpty ? 'v$_appVersion' : 'Loading...',
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('UPDATE CHANNEL'),
            const SizedBox(height: 12),
            Center(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'stable',
                    label: Text('Stable'),
                    icon: Icon(Icons.shield_outlined),
                  ),
                  ButtonSegment(
                    value: 'beta',
                    label: Text('Beta'),
                    icon: Icon(Icons.science_outlined),
                  ),
                ],
                selected: {_channel},
                onSelectionChanged: (selected) => _setChannel(selected.first),
                style: SegmentedButton.styleFrom(
                  backgroundColor: AppColors.surfaceCardOf(context),
                  selectedBackgroundColor: AppColors.primaryTextOf(context),
                  foregroundColor: AppColors.primaryTextOf(context),
                  selectedForegroundColor: AppColors.backgroundOf(context),
                  side: BorderSide(color: AppColors.borderOf(context)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _channel == 'stable'
                  ? 'Only stable releases will be shown.'
                  : 'Pre-release versions will be included.',
              style:
                  AppTextStyles.subheading(context).copyWith(fontSize: 12),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _checking ? null : _checkForUpdates,
                icon: _checking
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryTextOf(context),
                        ),
                      )
                    : Icon(Icons.refresh,
                        size: 18,
                        color: AppColors.primaryTextOf(context)),
                label: Text(
                  _checking ? 'CHECKING...' : 'CHECK FOR UPDATES',
                  style: AppTextStyles.buttonLabel(context),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryTextOf(context),
                  side: BorderSide(color: AppColors.borderOf(context)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: Text(
                'Tempo v$_appVersion',
                style:
                    AppTextStyles.subheading(context).copyWith(fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.buttonLabel(context).copyWith(
        color: AppColors.secondaryTextOf(context),
        fontSize: 12,
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardOf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body(context)),
          Text(
            value,
            style: AppTextStyles.body(context).copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardOf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: SwitchListTile(
        title: Text(label, style: AppTextStyles.body(context)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primaryTextOf(context),
        activeTrackColor: AppColors.primaryTextOf(context).withValues(alpha: 0.3),
        inactiveThumbColor: AppColors.secondaryTextOf(context),
        inactiveTrackColor: AppColors.dimWhiteOf(context),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
