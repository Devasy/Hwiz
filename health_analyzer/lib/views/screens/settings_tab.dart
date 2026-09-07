import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/theme_manager.dart';
import '../../utils/page_transitions.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../widgets/common/profile_avatar.dart';
import 'settings_screen.dart';
import 'profile_list_screen.dart';
import 'profile_form_screen.dart';
import 'data_management_screen.dart';

/// Settings tab - app configuration, profiles, and theme preferences
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        title: const Text('Settings & Profiles'),
        centerTitle: false,
      ),
      body: Consumer2<ProfileViewModel, ThemeViewModel>(
        builder: (context, profileVM, themeVM, child) {
          final activeProfile = profileVM.currentProfile;
          final allProfiles = profileVM.profiles;

          return ListView(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing32),
            children: [
              // 1. Profile Switcher & Family Section
              _buildSection(
                'Active Profile & Family',
                [
                  _buildProfileSwitcherCard(context, profileVM, activeProfile, allProfiles),
                ],
              ),

              // 2. API Configuration
              _buildSection(
                'AI Configuration',
                [
                  _buildTile(
                    Icons.key,
                    'Gemini API Key & Model',
                    'Configure your Google AI API key & model settings',
                    onTap: () {
                      context.pushHorizontal(const SettingsScreen());
                    },
                  ),
                ],
              ),

              // 3. App Theming & AMOLED Preferences
              _buildSection(
                'Appearance & Theme',
                [
                  // Theme Mode (System, Light, Dark)
                  ListTile(
                    leading: Icon(
                      themeVM.themeMode == ThemeMode.dark
                          ? Icons.dark_mode_outlined
                          : themeVM.themeMode == ThemeMode.light
                              ? Icons.light_mode_outlined
                              : Icons.brightness_auto_outlined,
                      color: context.primaryColor,
                    ),
                    title: const Text('Theme Mode'),
                    subtitle: Text(
                      themeVM.themeMode == ThemeMode.dark
                          ? 'Dark Mode'
                          : themeVM.themeMode == ThemeMode.light
                              ? 'Light Mode'
                              : 'System Default',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showThemeModeDialog(context, themeVM),
                  ),

                  // AMOLED Pure Black Toggle
                  SwitchListTile(
                    secondary: Icon(
                      Icons.brightness_2,
                      color: themeVM.isAmoledMode
                          ? context.primaryColor
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    title: const Text('AMOLED Mode'),
                    subtitle: const Text('Pure black (#000000) for OLED displays'),
                    value: themeVM.isAmoledMode,
                    onChanged: (value) {
                      themeVM.setAmoledMode(value);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'AMOLED mode enabled (Pure Black)'
                                : 'AMOLED mode disabled',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),

                  // Accent Palette
                  _buildTile(
                    Icons.palette_outlined,
                    'App Theme Palette',
                    themeVM.selectedTheme,
                    onTap: () {
                      _showThemeSelector(context, themeVM);
                    },
                  ),
                ],
              ),

              // 4. Data Management
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
                ],
              ),

              // 5. About & Help
              _buildSection(
                'About & Help',
                [
                  _buildTile(
                    Icons.info_outline,
                    'App Version',
                    '1.0.4+5',
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
                    'All medical reports & data stored 100% locally',
                    onTap: () {
                      _showPrivacyDialog(context);
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileSwitcherCard(
    BuildContext context,
    ProfileViewModel profileVM,
    dynamic activeProfile,
    List<dynamic> allProfiles,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (activeProfile == null) {
      return Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          children: [
            const Text('No profile created yet.'),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Add Family Member'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileFormScreen()),
                );
              },
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: 8),
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current active profile badge & header
          Row(
            children: [
              ProfileAvatar(
                name: activeProfile.name,
                size: 48,
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            activeProfile.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Active',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${activeProfile.age} yrs • ${activeProfile.gender}${activeProfile.bloodGroup != null ? ' • ${activeProfile.bloodGroup}' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (allProfiles.length > 1) ...[
            const SizedBox(height: AppTheme.spacing16),
            const Divider(height: 1),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              'Switch Active Profile:',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: allProfiles.map((p) {
                  final isSelected = p.id == activeProfile.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      avatar: ProfileAvatar(name: p.name, size: 24),
                      label: Text(p.name.split(' ')[0]),
                      onSelected: (selected) {
                        if (selected && !isSelected) {
                          HapticFeedback.selectionClick();
                          profileVM.selectProfile(p);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Switched active profile to ${p.name}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: AppTheme.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Add Member'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileFormScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.manage_accounts_outlined, size: 18),
                label: const Text('Manage All'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileListScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showThemeModeDialog(BuildContext context, ThemeViewModel themeVM) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              subtitle: const Text('Matches device system appearance'),
              value: ThemeMode.system,
              groupValue: themeVM.themeMode,
              onChanged: (mode) {
                if (mode != null) {
                  themeVM.setThemeMode(mode);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light Mode'),
              subtitle: const Text('Clean light appearance'),
              value: ThemeMode.light,
              groupValue: themeVM.themeMode,
              onChanged: (mode) {
                if (mode != null) {
                  themeVM.setThemeMode(mode);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark Mode'),
              subtitle: const Text('Dark appearance for low-light environments'),
              value: ThemeMode.dark,
              groupValue: themeVM.themeMode,
              onChanged: (mode) {
                if (mode != null) {
                  themeVM.setThemeMode(mode);
                  Navigator.pop(context);
                }
              },
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

  void _showThemeSelector(BuildContext context, ThemeViewModel themeVM) {
    final currentTheme = themeVM.selectedTheme;
    final themes = ThemeManager.getAvailableThemes();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme Palette'),
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
                    ? const Text('Uses dynamic wallpaper colors (Material You)')
                    : null,
                onTap: () {
                  themeVM.setSelectedTheme(themeName);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Theme palette changed to $themeName'),
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
