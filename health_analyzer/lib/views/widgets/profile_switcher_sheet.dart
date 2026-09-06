import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_extensions.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/report_viewmodel.dart';
import '../../widgets/common/profile_avatar.dart';
import '../screens/add_profile_screen.dart';

/// Bottom sheet for switching between profiles
class ProfileSwitcherSheet extends StatelessWidget {
  const ProfileSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusLarge),
          topRight: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: AppTheme.spacing12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Row(
                children: [
                  Text(
                    'Switch Profile',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Profile list
            Flexible(
              child: Consumer<ProfileViewModel>(
                builder: (context, profileVM, child) {
                  if (profileVM.profiles.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No profiles yet',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: AppTheme.spacing16),
                          // Material 3 FilledButton for primary action
                          FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AddProfileScreen(),
                                ),
                              );
                            },
                            child: const Text('Add First Profile'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: profileVM.profiles.length,
                    itemBuilder: (context, index) {
                      final profile = profileVM.profiles[index];
                      final isSelected =
                          profile.id == profileVM.currentProfile?.id;
                      final age = profileVM.getAge(profile);

                      return ListTile(
                        leading: ProfileAvatar(
                          name: profile.name,
                          size: 48,
                        ),
                        title: Text(
                          profile.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        subtitle: Text(
                          [
                            if (age != null) '$age years',
                            if (profile.relationship != null)
                              profile.relationship!,
                          ].join(' • '),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: context.primaryColor,
                              )
                            : null,
                        selected: isSelected,
                        onTap: () {
                          profileVM.selectProfile(profile);
                          final reportVM = context.read<ReportViewModel>();
                          reportVM.loadReportsForProfile(profile.id!);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // Add new member button
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddProfileScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Member'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
