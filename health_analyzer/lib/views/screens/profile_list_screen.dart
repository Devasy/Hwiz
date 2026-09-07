import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../models/profile.dart';
import '../../utils/page_transitions.dart';
import 'profile_form_screen.dart';
import 'report_list_screen.dart';
import '../widgets/profile_card.dart';

/// Screen to display and manage all profiles
class ProfileListScreen extends StatefulWidget {
  const ProfileListScreen({super.key});

  @override
  State<ProfileListScreen> createState() => _ProfileListScreenState();
}

class _ProfileListScreenState extends State<ProfileListScreen> {
  @override
  void initState() {
    super.initState();
    // Load profiles when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().loadProfiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Profiles'),
        centerTitle: true,
      ),
      body: Consumer<ProfileViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      viewModel.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => viewModel.loadProfiles(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!viewModel.hasProfiles) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.loadProfiles(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.profiles.length,
              itemBuilder: (context, index) {
                final profile = viewModel.profiles[index];
                return RepaintBoundary(
                  child: ProfileCard(
                    profile: profile,
                    isSelected: viewModel.selectedProfile?.id == profile.id,
                    onTap: () {
                      viewModel.selectProfile(profile);
                      _showProfileDetails(context, profile);
                    },
                    onEdit: () => _navigateToEditProfile(context, profile),
                    onDelete: () => _showDeleteConfirmation(context, profile),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddProfile(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Profile'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 120,
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Profiles Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create profiles for family members\nto track their blood reports',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddProfile(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Create First Profile'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToAddProfile(BuildContext context) async {
    final result = await context.pushVertical<bool>(
      const ProfileFormScreen(),
    );

    if (result == true && mounted) {
      // Refresh list after adding
      context.read<ProfileViewModel>().loadProfiles();
    }
  }

  Future<void> _navigateToEditProfile(
    BuildContext context,
    Profile profile,
  ) async {
    final result = await context.pushVertical<bool>(
      ProfileFormScreen(profile: profile),
    );

    if (result == true && mounted) {
      // Refresh list after editing
      context.read<ProfileViewModel>().loadProfiles();
    }
  }

  void _showProfileDetails(BuildContext context, Profile profile) {
    final viewModel = context.read<ProfileViewModel>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FutureBuilder<ProfileStatistics>(
        future: viewModel.getProfileStatistics(profile.id!),
        builder: (context, snapshot) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Profile header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: Text(
                            profile.name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 32,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              if (profile.gender != null)
                                Text(
                                  profile.gender!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Profile details
                    _DetailRow(
                      icon: Icons.cake,
                      label: 'Date of Birth',
                      value: profile.dateOfBirth ?? 'Not set',
                    ),
                    if (viewModel.getAge(profile) != null) ...[
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.calendar_today,
                        label: 'Age',
                        value: '${viewModel.getAge(profile)} years',
                      ),
                    ],
                    if (snapshot.hasData) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Statistics',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _StatCard(
                        icon: Icons.description,
                        label: 'Total Reports',
                        value: '${snapshot.data!.totalReports}',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      _StatCard(
                        icon: Icons.science,
                        label: 'Parameters Tracked',
                        value: '${snapshot.data!.uniqueParameters}',
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      if (snapshot.data!.latestReportDate != null) ...[
                        const SizedBox(height: 8),
                        _StatCard(
                          icon: Icons.update,
                          label: 'Last Report',
                          value: _formatDate(snapshot.data!.latestReportDate!),
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _navigateToEditProfile(context, profile);
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              debugPrint('🔵 "View Reports" button tapped');
                              debugPrint('  Profile ID: ${profile.id}');
                              debugPrint('  Profile Name: ${profile.name}');
                              Navigator.pop(context);
                              try {
                                context
                                    .pushVertical(
                                  ReportListScreen(
                                    profileId: profile.id!,
                                    profileName: profile.name,
                                  ),
                                )
                                    .then((value) {
                                  debugPrint(
                                      '🔙 Returned from ReportListScreen');
                                }).catchError((error) {
                                  debugPrint('❌ Navigation error: $error');
                                });
                              } catch (e) {
                                debugPrint(
                                    '❌ Exception navigating to reports: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.error,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.assessment),
                            label: const Text('View Reports'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Profile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text(
          'Are you sure you want to delete ${profile.name}\'s profile? '
          'This will also delete all associated blood reports. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<ProfileViewModel>()
                  .deleteProfile(profile.id!);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${profile.name}\'s profile deleted'),
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
