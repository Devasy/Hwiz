import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../models/profile.dart';
import '../../widgets/common/profile_avatar.dart';
import '../../utils/page_transitions.dart';
import '../../views/screens/profile_list_screen.dart';
import '../../views/screens/settings_screen.dart';
import '../../views/screens/data_management_screen.dart';

/// Enhanced navigation drawer with smooth animations and user info
///
/// Features:
/// - User profile header with avatar and info
/// - Smooth slide-in animation
/// - Quick profile switcher
/// - Organized menu sections
/// - Material 3 styling
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: NavigationDrawer(
          children: [
            // User Profile Header
            _buildUserHeader(context),

            const Divider(height: 1),

            // Profile Management Section
            _buildSectionHeader('Profile'),
            _buildDrawerTile(
              context,
              icon: Icons.people_outline,
              selectedIcon: Icons.people,
              label: 'Manage Profiles',
              onTap: () {
                Navigator.pop(context);
                context.pushHorizontal(const ProfileListScreen());
              },
            ),

            const SizedBox(height: 8),

            // Data Section
            _buildSectionHeader('Data'),
            _buildDrawerTile(
              context,
              icon: Icons.import_export_outlined,
              selectedIcon: Icons.import_export,
              label: 'Export & Import',
              onTap: () {
                Navigator.pop(context);
                context.pushHorizontal(const DataManagementScreen());
              },
            ),

            const SizedBox(height: 8),

            // Settings Section
            _buildSectionHeader('Configuration'),
            _buildDrawerTile(
              context,
              icon: Icons.key_outlined,
              selectedIcon: Icons.key,
              label: 'API Settings',
              onTap: () {
                Navigator.pop(context);
                context.pushHorizontal(const SettingsScreen());
              },
            ),

            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // App Info Footer
            _buildAppInfo(context),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, profileVM, child) {
        final profile = profileVM.currentProfile;
        final profileCount = profileVM.profiles.length;

        return Material(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              context.pushHorizontal(const ProfileListScreen());
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar and Name
                  Row(
                    children: [
                      Hero(
                        tag: 'profile_avatar_${profile?.id ?? 0}',
                        child: ProfileAvatar(
                          name: profile?.name ?? 'No Profile',
                          size: 56,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.name ?? 'No Profile Selected',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getProfileSubtitle(profile),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withValues(alpha: 0.7),
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Profile count and switch button
                  if (profileCount > 1) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$profileCount profiles',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getProfileSubtitle(Profile? profile) {
    if (profile == null) return 'Tap to create a profile';

    final age = profile.dateOfBirth != null
        ? _calculateAge(profile.dateOfBirth!)
        : null;
    final gender =
        profile.gender?.isNotEmpty == true ? profile.gender : 'Unknown';

    if (age != null) {
      return '$age • $gender';
    } else {
      return gender ?? 'Unknown';
    }
  }

  int _calculateAge(String birthDateStr) {
    try {
      final birthDate = DateTime.parse(birthDateStr);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(icon),
          title: Text(label),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LabLens',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            'Version 1.0.1 • Made with ❤️',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}
