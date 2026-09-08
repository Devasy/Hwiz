import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/report_viewmodel.dart';
import '../../models/blood_report.dart';
import '../../utils/page_transitions.dart';
import '../../widgets/common/shimmer_loading.dart';
import 'report_details_screen.dart';
import 'package:intl/intl.dart';

/// Screen to display all blood reports for a profile
class ReportListScreen extends StatefulWidget {
  final int profileId;
  final String profileName;

  const ReportListScreen({
    super.key,
    required this.profileId,
    required this.profileName,
  });

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload reports when coming back to this screen
    _loadReports();
  }

  void _loadReports() {
    debugPrint('📊 DEBUG: Loading reports for profile ${widget.profileId}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReportViewModel>().loadReportsForProfile(widget.profileId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.profileName}\'s Reports'),
        centerTitle: true,
      ),
      body: Consumer<ReportViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ReportCardSkeleton(),
              ),
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
                    'Error loading reports',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(viewModel.error!),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        viewModel.loadReportsForProfile(widget.profileId),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!viewModel.hasReports) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.loadReportsForProfile(widget.profileId),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.reports.length,
              itemBuilder: (context, index) {
                final report = viewModel.reports[index];
                debugPrint(
                    '📄 Report #$index: ID=${report.id}, Params=${report.parameters.length}');
                return RepaintBoundary(
                  child: _ReportCard(
                    report: report,
                    onTap: () {
                      debugPrint(
                          '👆 Report card tapped: Report ID ${report.id}');
                      _navigateToReportDetail(context, report);
                    },
                    onDelete: () => _showDeleteConfirmation(context, report),
                  ),
                );
              },
            ),
          );
        },
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
              Icons.description_outlined,
              size: 100,
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Reports Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Scan your first blood report\nto start tracking health data',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToReportDetail(BuildContext context, BloodReport report) {
    debugPrint('🔍 DEBUG: Attempting to navigate to report detail');
    debugPrint('  Report ID: ${report.id}');
    debugPrint('  Test Date: ${report.testDate}');
    debugPrint('  Lab Name: ${report.labName}');
    debugPrint('  Parameters Count: ${report.parameters.length}');
    debugPrint('  Image Path: ${report.reportImagePath}');

    try {
      context
          .pushVertical(
        ReportDetailsScreen(
          report: report,
          profileName: widget.profileName,
        ),
      )
          .then((value) {
        debugPrint('🔙 Returned from ReportDetailsScreen');
      }).catchError((error) {
        debugPrint('❌ Navigation error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening report: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      });
    } catch (e) {
      debugPrint('❌ Exception during navigation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open report: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, BloodReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: Text(
          'Are you sure you want to delete the report from ${_formatDate(report.testDate)}? '
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
              final viewModel = context.read<ReportViewModel>();
              final success = await viewModel.deleteReport(report.id!);

              if (success && mounted) {
                // Reload reports for the profile after deletion
                await viewModel.loadReportsForProfile(widget.profileId);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Report deleted'),
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                    ),
                  );
                }
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(viewModel.error ?? 'Failed to delete report'),
                    backgroundColor: Theme.of(context).colorScheme.error,
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
    return DateFormat('MMM dd, yyyy').format(date);
  }
}

class _ReportCard extends StatelessWidget {
  final BloodReport report;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ReportCard({
    required this.report,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PageTransitions.openContainer(
      closedChild: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () {}, // Placeholder, OpenContainer handles the action
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.description,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Report info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(report.testDate),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      if (report.labName != null)
                        Text(
                          report.labName!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        ),
                      const SizedBox(height: 4),
                      if (report.parameters.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  size: 12, color: Colors.amber.shade900),
                              const SizedBox(width: 4),
                              Text(
                                'Incomplete (0 parameters)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          '${report.parameters.length} parameters',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.8),
                                  ),
                        ),
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete,
                              size: 20,
                              color: Theme.of(context).colorScheme.error),
                          const SizedBox(width: 12),
                          Text('Delete',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      openBuilder: (context) => ReportDetailsScreen(report: report),
      onClosed: () {}, // No action needed on close
      closedColor: Theme.of(context).colorScheme.surface,
      openColor: Theme.of(context).colorScheme.surface,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
}
