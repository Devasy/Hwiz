import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/theme_manager.dart';
import '../../utils/page_transitions.dart';
import 'settings_screen.dart';
import 'profile_list_screen.dart';
import 'data_management_screen.dart';

/// Settings tab - app configuration and preferences
class SettingsTab extends StatelessWidget {
  final Function(bool)? onAmoledModeChanged;
  final Function(String)? onThemeChanged;

  const SettingsTab({
    super.key,
    this.onAmoledModeChanged,
    this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Open menu',
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      body: ListView(
        children: [
          _buildSection(
            'Family Members',
            [
              _buildTile(
                Icons.people,
                'Manage Profiles',
                'Add, edit, or remove family members',
                onTap: () {
                  context.pushHorizontal(const ProfileListScreen());
                },
              ),
            ],
          ),
          _buildSection(
            'API Configuration',
            [
              _buildTile(
                Icons.key,
                'Gemini API Key',
                'Configure your AI API key',
                onTap: () {
                  context.pushHorizontal(const SettingsScreen());
                },
              ),
            ],
          ),
          _buildSection(
            'Data Management',
            [
              _buildTile(
                Icons.import_export,
                'Export & Import Data',
                'Export reports to CSV/JSON or import from backup',
                onTap: () {
                  context.pushHorizontal(const DataManagementScreen());
                },
              ),
              _buildTile(
                Icons.delete_outline,
                'Clear All Data (Coming Soon)',
                'Feature under development',
                onTap: null,
                isDestructive: false,
              ),
            ],
          ),
          _buildSection(
            'App Preferences',
            [
              _buildTile(
                Icons.palette_outlined,
                'App Theme',
                'Choose your favorite color theme',
                onTap: () {
                  _showThemeSelector(context);
                },
              ),
              FutureBuilder<bool>(
                future: ThemeManager.getAmoledMode(),
                builder: (context, snapshot) {
                  final isEnabled = snapshot.data ?? false;
                  return SwitchListTile(
                    secondary: const Icon(Icons.brightness_2),
                    title: const Text('AMOLED Mode'),
                    subtitle:
                        const Text('Pure black background for dark theme'),
                    value: isEnabled,
                    onChanged: (value) {
                      if (onAmoledModeChanged != null) {
                        onAmoledModeChanged!(value);
                      }
                    },
                  );
                },
              ),
            ],
          ),
          _buildSection(
            'About & Help',
            [
              _buildTile(
                Icons.info_outline,
                'App Version',
                '1.0.3+3',
              ),
              _buildTile(
                Icons.code,
                'GitHub Repository',
                'View source code & contribute',
                onTap: () {
                  _openGitHub(context);
                },
              ),
              _buildTile(
                Icons.person_outline,
                'Developer',
                'Created by @Devasy23',
                onTap: () {
                  _showDeveloperInfo(context);
                },
              ),
              _buildTile(
                Icons.help_outline,
                'How to Use LabLens',
                'Tutorial and guide',
                onTap: () {
                  _showTutorialDialog(context);
                },
              ),
              _buildTile(
                Icons.privacy_tip_outlined,
                'Privacy Policy',
                'All data stored locally',
                onTap: () {
                  _showPrivacyDialog(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacing16,
              AppTheme.spacing24,
              AppTheme.spacing16,
              AppTheme.spacing8,
            ),
            child: Text(
              title,
              style: AppTheme.labelLarge.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Material(
            color: context.surfaceColor,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    IconData icon,
    String title,
    String? subtitle, {
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return Builder(
      builder: (context) => ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? AppTheme.errorColor : context.primaryColor,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isDestructive ? AppTheme.errorColor : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }

  void _showThemeSelector(BuildContext context) async {
    final currentTheme = await ThemeManager.getSelectedTheme();
    final themes = ThemeManager.getAvailableThemes();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: themes.length,
            itemBuilder: (context, index) {
              final themeName = themes[index];
              final themeColor = ThemeManager.getThemeColor(themeName);
              final isSelected = themeName == currentTheme;

              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: themeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: _getContrastColor(themeColor),
                          size: 20,
                        )
                      : null,
                ),
                title: Text(themeName),
                subtitle: themeName == 'Adaptive Theme'
                    ? const Text('Uses system wallpaper colors')
                    : null,
                onTap: () {
                  if (onThemeChanged != null) {
                    onThemeChanged!(themeName);
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Theme changed to $themeName'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Color _getContrastColor(Color backgroundColor) {
    // Calculate relative luminance
    final luminance = backgroundColor.computeLuminance();
    // Return white for dark colors, black for light colors
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  void _showTutorialDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Use LabLens'),
        content: SingleChildScrollView(
          child: Text(
            '📱 Getting Started\n\n'
            '1. Create Profile\n'
            '   Add family member profiles to organize reports\n\n'
            '2. Setup API Key\n'
            '   Configure your Gemini API key in settings\n\n'
            '3. Scan Report\n'
            '   Use camera, gallery, or PDF to add blood reports\n\n'
            '4. View Analysis\n'
            '   Get AI-powered health insights and trends\n\n'
            '5. Track Progress\n'
            '   Monitor parameter changes over time\n\n'
            '💡 Tips\n'
            '• Ensure good lighting when scanning\n'
            '• Keep reports flat and in focus\n'
            '• All data is stored locally on your device\n'
            '• Regular updates help track health trends',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(
            'LabLens Privacy Policy\n\n'
            '1. Data Storage\n'
            'All your health records and profiles are stored locally in SQLite on your device. '
            'We do not operate backend servers that store your medical information.\n\n'
            '2. API Key & Security\n'
            'Your Gemini API key is stored securely using Android EncryptedSharedPreferences (KeyStore). '
            'It is only used to communicate with Google\'s Gemini API.\n\n'
            '3. Third-Party Services (AI Processing)\n'
            'When you scan a blood report or request AI insights, selected report files and biomarker parameters '
            'are sent directly to Google Gemini API for extraction and analysis.\n\n'
            '4. Data Ownership\n'
            'You own all your data. You can export your data to CSV/JSON at any time.\n\n'
            '5. No Analytics\n'
            'We do not collect usage analytics or personal information.\n\n'
            '6. Security\n'
            'We use industry-standard encryption for sensitive data storage.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openGitHub(BuildContext context) async {
    const url = 'https://github.com/Devasy23/Hwiz';
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback - copy to clipboard
        await Clipboard.setData(const ClipboardData(text: url));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('GitHub URL copied to clipboard!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Copy to clipboard as fallback
      await Clipboard.setData(const ClipboardData(text: url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GitHub URL copied to clipboard!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showDeveloperInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.favorite, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            const Text('About the Developer'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LabLens',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Created with ❤️ by',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'D',
                        style: TextStyle(
                          color: context.onPrimaryColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@Devasy23',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Full Stack Developer',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.onSurfaceColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '🚀 Open Source Contribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This app is open source! Feel free to contribute, report issues, or suggest features on GitHub.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openGitHub(context);
                    },
                    icon: const Icon(Icons.code, size: 18),
                    label: const Text('View on GitHub'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
