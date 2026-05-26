import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        title: Text(
          'SETTINGS',
          style: AppTextStyles.buttonLabel.copyWith(fontSize: 14),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: AppColors.border, height: 1, thickness: 0.5),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  backgroundColor: AppColors.surfaceCard,
                  selectedBackgroundColor: AppColors.primaryText,
                  foregroundColor: AppColors.primaryText,
                  selectedForegroundColor: AppColors.background,
                  side: BorderSide(color: AppColors.border),
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
              style: AppTextStyles.subheading.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _checking ? null : _checkForUpdates,
                icon: _checking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryText,
                        ),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: Text(
                  _checking ? 'CHECKING...' : 'CHECK FOR UPDATES',
                  style: AppTextStyles.buttonLabel,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryText,
                  side: const BorderSide(color: AppColors.border),
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
                style: AppTextStyles.subheading.copyWith(fontSize: 12),
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
      style: AppTextStyles.buttonLabel.copyWith(
        color: AppColors.secondaryText,
        fontSize: 12,
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
