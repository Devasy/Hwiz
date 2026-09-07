import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/report_viewmodel.dart';
import '../../models/profile.dart';
import '../../widgets/common/profile_avatar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/expandable_fab.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../widgets/profile_switcher_sheet.dart';
import 'report_scan_screen.dart';
import 'report_details_screen.dart';
import 'compare_reports_screen.dart';
import 'profile_list_screen.dart';
import 'profile_form_screen.dart';
import 'ask_ai_screen.dart';
import 'settings_tab.dart';

/// Home tab - main view with profile content
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Profile? _lastLoadedProfile;

  @override
  void initState() {
    super.initState();
    // Initial load will happen in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadReportsIfNeeded();
  }

  void _loadReportsIfNeeded() {
    final profileVM = context.read<ProfileViewModel>();
    final reportVM = context.read<ReportViewModel>();
    final currentProfile = profileVM.currentProfile;

    // Load reports if:
    // 1. There's a current profile
    // 2. It's different from the last loaded profile (or first time)
    if (currentProfile != null && _lastLoadedProfile?.id != currentProfile.id) {
      debugPrint(
          '📊 Loading reports for profile: ${currentProfile.name} (ID: ${currentProfile.id})');
      _lastLoadedProfile = currentProfile;
      reportVM.loadReportsForProfile(currentProfile.id!);
    }
  }

  void _showProfileSwitcher() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProfileSwitcherSheet(),
    );
  }

  void _navigateToScan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ReportScanScreen(),
      ),
    );
  }

  void _navigateToCompare(Profile profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CompareReportsScreen(
          profileId: profile.id!,
          profileName: profile.name,
        ),
      ),
    );
  }

  void _navigateToProfiles() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileListScreen(),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsTab(),
      ),
    );
  }

  void _navigateToCompareForCurrent() {
    final profile = context.read<ProfileViewModel>().currentProfile;
    if (profile != null) {
      _navigateToCompare(profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(),

            // Content
            Expanded(
              child: Consumer2<ProfileViewModel, ReportViewModel>(
                builder: (context, profileVM, reportVM, child) {
                  final profile = profileVM.currentProfile;

                  // Trigger reload when profile changes
                  // This will be handled by didChangeDependencies on the next frame
                  if (profile != null && _lastLoadedProfile?.id != profile.id) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _loadReportsIfNeeded();
                      }
                    });
                  }

                  if (profile == null) {
                    return EmptyState(
                      icon: Icons.person_add,
                      title: 'No Profile Selected',
                      message: 'Create or select a profile to get started',
                      actionLabel: 'Add Profile',
                      onAction: _showProfileSwitcher,
                    );
                  }

                  return _buildProfileContent(profile, reportVM);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Consumer<ProfileViewModel>(
        builder: (context, profileVM, child) {
          final hasProfile = profileVM.currentProfile != null;

          return ExpandableFab(
            actions: [
              // Scan Report - Primary action
              ExpandableFabAction(
                icon: Icons.camera_alt,
                label: 'Scan Report',
                onPressed: _navigateToScan,
              ),
              // Compare Reports - if profile exists
              if (hasProfile)
                ExpandableFabAction(
                  icon: Icons.compare_arrows,
                  label: 'Compare',
                  onPressed: _navigateToCompareForCurrent,
                ),
              // Manage Profiles
              ExpandableFabAction(
                icon: Icons.people,
                label: 'Profiles',
                onPressed: _navigateToProfiles,
              ),
            ],
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          // App logo/name
          Text(
            'LabLens',
            style: AppTheme.headingMedium.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),

          // Action buttons
          Consumer2<ProfileViewModel, ReportViewModel>(
            builder: (context, profileVM, reportVM, child) {
              final profile = profileVM.currentProfile;
              final hasReports = reportVM.reports.isNotEmpty;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Compare button
                  if (hasReports && reportVM.reports.length >= 2)
                    IconButton(
                      icon: const Icon(Icons.compare_arrows),
                      tooltip: 'Compare Reports',
                      onPressed: () => _navigateToCompare(profile!),
                    ),

                  // Ask AI quick shortcut
                  IconButton(
                    icon: const Icon(Icons.auto_awesome_rounded),
                    tooltip: 'Ask AI',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AskAiScreen()),
                      );
                    },
                  ),

                  const SizedBox(width: AppTheme.spacing8),
                ],
              );
            },
          ),

          // Profile & Settings shortcut
          Consumer<ProfileViewModel>(
            builder: (context, profileVM, child) {
              final profile = profileVM.currentProfile;

              if (profile == null) {
                return IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings & Profiles',
                  onPressed: _navigateToSettings,
                );
              }

              return Tooltip(
                message: 'Settings & Profiles (${profile.name})',
                child: InkWell(
                  onTap: _navigateToSettings,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ProfileAvatar(
                          name: profile.name,
                          size: 34,
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 80),
                          child: Text(
                            profile.name.split(' ')[0],
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.settings_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(Profile profile, ReportViewModel reportVM) {
    return CustomScrollView(
      slivers: [
        // Profile Summary Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: reportVM.isLoading
                ? ProfileSummarySkeleton()
                : _buildProfileSummaryCard(profile, reportVM),
          ),
        ),

        // Recent Reports
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
            child: Text(
              'Recent Reports',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: AppTheme.spacing12),
        ),

        // Reports List or Empty State
        if (reportVM.isLoading)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16,
                  vertical: AppTheme.spacing8,
                ),
                child: ReportCardSkeleton(),
              ),
              childCount: 3,
            ),
          )
        else if (reportVM.reports.isEmpty)
          SliverFillRemaining(
            child: EmptyState(
              icon: Icons.description_outlined,
              title: 'No reports yet',
              message: 'Tap the + button to scan your first report',
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final report = reportVM.reports[index];
                return RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing8,
                    ),
                    child: _buildReportCard(report),
                  ),
                );
              },
              childCount: reportVM.reports.length,
            ),
          ),

        // Bottom padding for FAB
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildProfileSummaryCard(Profile profile, ReportViewModel reportVM) {
    final age = profile.dateOfBirth != null && profile.dateOfBirth!.isNotEmpty
        ? _calculateAge(DateTime.parse(profile.dateOfBirth!))
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfileAvatar(
                  name: profile.name,
                  size: 60,
                ),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        [
                          if (age != null) '$age years',
                          if (profile.relationship != null)
                            profile.relationship!,
                        ].where((s) => s.isNotEmpty).join(' • '),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Profile',
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProfileFormScreen(profile: profile),
                      ),
                    );
                    if (mounted) {
                      context.read<ProfileViewModel>().loadProfiles();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            const Divider(),
            const SizedBox(height: AppTheme.spacing12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Reports',
                  '${reportVM.reports.length}',
                  Icons.description,
                ),
                _buildStatItem(
                  'Last Test',
                  reportVM.reports.isNotEmpty
                      ? _formatDate(reportVM.reports.first.testDate)
                      : 'N/A',
                  Icons.calendar_today,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Column(
          children: [
            Icon(icon, color: colorScheme.primary, size: 24),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              value,
              style: AppTheme.titleMedium.copyWith(
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportCard(dynamic report) {
    final profile = context.read<ProfileViewModel>().currentProfile;

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ReportDetailsScreen(
                report: report,
                profileName: profile?.name,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatFullDate(report.testDate),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (report.labName?.isNotEmpty ?? false) ...[
                          const SizedBox(height: AppTheme.spacing4),
                          Text(
                            report.labName!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                '${report.parameters.length} parameters',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    if (diff < 30) return '${(diff / 7).floor()} weeks ago';

    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatFullDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
