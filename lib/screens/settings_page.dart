import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    HapticFeedback.selectionClick();
    setState(() => _channel = channel);
    await UpdateManager.saveChannel(channel);
  }

  Future<void> _checkForUpdates() async {
    HapticFeedback.mediumImpact();
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
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primaryTextOf(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.primaryTextOf(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SETTINGS',
          style: AppTextStyles.buttonLabel(context).copyWith(fontSize: 14, letterSpacing: 1),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('APPEARANCE'),
            const SizedBox(height: 12),
            // Custom Setting Card for Dark Mode matching mockup Screen 3 active/inactive card layout
            _buildCustomSettingToggle(
              icon: Icons.dark_mode_outlined,
              label: 'Dark Mode',
              enabled: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                themeService.setMode(
                  isDark ? ThemeMode.light : ThemeMode.dark,
                );
              },
            ),
            const SizedBox(height: 12),
            _buildCustomSettingToggle(
              icon: Icons.tab,
              label: 'Show Nav Labels',
              enabled: themeService.showNavLabels,
              onTap: () {
                HapticFeedback.selectionClick();
                themeService.setShowNavLabels(!themeService.showNavLabels);
              },
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('APP VERSION'),
            const SizedBox(height: 12),
            _buildInfoTile(
              Icons.info_outline,
              'Current Version',
              _appVersion.isNotEmpty ? 'v$_appVersion' : 'Loading...',
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('UPDATE CHANNEL'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildChannelButton('stable', 'Stable', Icons.shield_outlined),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildChannelButton('beta', 'Beta', Icons.science_outlined),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _channel == 'stable'
                    ? 'Only stable releases will be shown.'
                    : 'Pre-release versions will be included.',
                style: AppTextStyles.subheading(context).copyWith(fontSize: 12),
              ),
            ),
            const SizedBox(height: 48),
            // Update Check Action Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _checking ? null : _checkForUpdates,
                icon: _checking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh, size: 18, color: Colors.white),
                label: Text(
                  _checking ? 'CHECKING...' : 'CHECK FOR UPDATES',
                  style: AppTextStyles.buttonLabel(context).copyWith(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOf(context),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 64),
            Center(
              child: Column(
                children: [
                  Text(
                    'Tempo',
                    style: AppTextStyles.buttonLabel(context).copyWith(
                      color: AppColors.secondaryTextOf(context),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v$_appVersion',
                    style: AppTextStyles.subheading(context).copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
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
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildCustomSettingToggle({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: enabled ? AppColors.accentOf(context) : AppColors.surfaceCardOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: enabled ? Colors.transparent : AppColors.borderOf(context),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: enabled ? Colors.white : AppColors.primaryTextOf(context),
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body(context).copyWith(
                  color: enabled ? Colors.white : AppColors.primaryTextOf(context),
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: enabled ? Colors.white : AppColors.secondaryTextOf(context).withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: enabled
                  ? Icon(
                      Icons.check,
                      size: 14,
                      color: AppColors.accentOf(context),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondaryTextOf(context), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: AppTextStyles.body(context)),
          ),
          Text(
            value,
            style: AppTextStyles.body(context).copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.accentOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelButton(String channelVal, String label, IconData icon) {
    final isSelected = _channel == channelVal;
    return GestureDetector(
      onTap: () => _setChannel(channelVal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentOf(context) : AppColors.surfaceCardOf(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.borderOf(context),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.secondaryTextOf(context),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.buttonLabel(context).copyWith(
                color: isSelected ? Colors.white : AppColors.primaryTextOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
