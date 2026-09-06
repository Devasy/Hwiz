import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/data_export_import_service.dart';
import '../../services/database_helper.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/report_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_extensions.dart';
import '../../models/profile.dart';
import '../../models/blood_report.dart';

/// Screen for exporting and importing health data
class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  final _exportService = DataExportImportService();
  final _dbHelper = DatabaseHelper.instance;
  bool _isLoading = false;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
    final profileVM = context.watch<ProfileViewModel>();
    final reportVM = context.watch<ReportViewModel>();
    final currentProfile = profileVM.currentProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export & Import Data'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        children: [
          // Status message
          if (_statusMessage != null) ...[
            Card(
              color: context.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: Row(
                  children: [
                    Icon(
                      _isLoading ? Icons.hourglass_empty : Icons.check_circle,
                      color: context.onPrimaryContainer,
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: AppTheme.bodyMedium.copyWith(
                          color: context.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],

          // Loading indicator
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing24),
                child: CircularProgressIndicator(),
              ),
            ),

          // Export Section
          _buildSectionCard(
            title: 'Export Data',
            icon: Icons.file_upload,
            iconColor: context.primaryColor,
            children: [
              _buildActionTile(
                title: 'Export Current Profile',
                subtitle: currentProfile != null
                    ? 'Export ${currentProfile.name}\'s complete data'
                    : 'No profile selected',
                icon: Icons.person,
                onTap: currentProfile != null
                    ? () => _exportCurrentProfile(currentProfile, reportVM)
                    : null,
              ),
              const Divider(height: 1),
              _buildActionTile(
                title: 'Export Single Report (CSV)',
                subtitle: 'Choose a report to export as CSV',
                icon: Icons.table_chart,
                onTap: reportVM.reports.isNotEmpty
                    ? () => _exportSingleReportCsv(reportVM)
                    : null,
              ),
              const Divider(height: 1),
              _buildActionTile(
                title: 'Export All Reports (CSV)',
                subtitle: currentProfile != null
                    ? 'Export all ${reportVM.reports.length} reports'
                    : 'No profile selected',
                icon: Icons.table_view,
                onTap: currentProfile != null && reportVM.reports.isNotEmpty
                    ? () => _exportAllReportsCsv(currentProfile, reportVM)
                    : null,
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacing24),

          // Import Section
          _buildSectionCard(
            title: 'Import Data',
            icon: Icons.file_download,
            iconColor: context.successColor,
            children: [
              _buildActionTile(
                title: 'Import Complete Profile',
                subtitle: 'Import profile with all reports (JSON)',
                icon: Icons.person_add,
                onTap: () => _importCompleteProfile(profileVM, reportVM),
              ),
              const Divider(height: 1),
              _buildActionTile(
                title: 'Import Reports (CSV)',
                subtitle: currentProfile != null
                    ? 'Add reports to ${currentProfile.name}'
                    : 'Select a profile first',
                icon: Icons.add_chart,
                onTap: currentProfile != null
                    ? () => _importReportsCsv(currentProfile, reportVM)
                    : null,
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacing24),

          // Info Card
          Card(
            color: context.surfaceContainerLowest,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: context.onSurfaceColor.withValues(alpha: 0.6),
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Text(
                        'About Data Formats',
                        style: AppTheme.titleSmall.copyWith(
                          color: context.onSurfaceColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  _buildInfoItem(
                    'JSON',
                    'Complete data with profile info and all reports',
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  _buildInfoItem(
                    'CSV',
                    'Spreadsheet format for individual reports',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: AppTheme.spacing12),
                Text(
                  title,
                  style: AppTheme.titleLarge.copyWith(
                    color: context.onSurfaceColor,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: onTap != null
            ? context.primaryColor
            : context.onSurfaceColor.withValues(alpha: 0.3),
      ),
      title: Text(
        title,
        style: AppTheme.titleSmall.copyWith(
          color: onTap != null
              ? context.onSurfaceColor
              : context.onSurfaceColor.withValues(alpha: 0.5),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.bodySmall.copyWith(
          color: context.onSurfaceColor.withValues(alpha: 0.6),
        ),
      ),
      trailing: onTap != null
          ? Icon(Icons.arrow_forward_ios, size: 16, color: context.primaryColor)
          : null,
      enabled: onTap != null,
      onTap: _isLoading ? null : onTap,
    );
  }

  Widget _buildInfoItem(String label, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: AppTheme.bodyMedium.copyWith(
            color: context.onSurfaceColor.withValues(alpha: 0.6),
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: AppTheme.bodyMedium.copyWith(
                    color: context.onSurfaceColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: description,
                  style: AppTheme.bodyMedium.copyWith(
                    color: context.onSurfaceColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Export Methods
  Future<void> _exportCurrentProfile(
    Profile profile,
    ReportViewModel reportVM,
  ) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Preparing profile export...';
    });

    try {
      final filePath = await _exportService.exportProfileToJson(
        profile,
        reportVM.reports,
      );

      if (filePath != null) {
        await _exportService.shareFile(
          filePath,
          subject: '${profile.name} - Complete Health Data',
        );

        setState(() {
          _isLoading = false;
          _statusMessage = 'Profile exported successfully!';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Export failed: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportSingleReportCsv(ReportViewModel reportVM) async {
    // Show report picker
    final report = await _showReportPicker(reportVM.reports);
    if (report == null) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Exporting report...';
    });

    try {
      final filePath = await _exportService.exportReportToCsv(report);

      if (filePath != null) {
        await _exportService.shareFile(filePath);

        setState(() {
          _isLoading = false;
          _statusMessage = 'Report exported successfully!';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Export failed: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportAllReportsCsv(
    Profile profile,
    ReportViewModel reportVM,
  ) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Exporting all reports...';
    });

    try {
      final filePath = await _exportService.exportReportsToCsv(
        reportVM.reports,
        profile.name,
      );

      if (filePath != null) {
        await _exportService.shareFile(filePath);

        setState(() {
          _isLoading = false;
          _statusMessage = '${reportVM.reports.length} reports exported!';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Export failed: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  // Import Methods
  Future<void> _importCompleteProfile(
    ProfileViewModel profileVM,
    ReportViewModel reportVM,
  ) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Importing profile...';
    });

    try {
      final importData = await _exportService.importProfileFromJson();
      final profile = importData['profile'] as Profile;
      final reports = importData['reports'] as List<BloodReport>;

      // Add profile using createProfile method
      final success = await profileVM.createProfile(
        name: profile.name,
        dateOfBirth: profile.dateOfBirth,
        gender: profile.gender,
        relationship: profile.relationship,
        photoPath: profile.photoPath,
      );

      if (!success) {
        throw Exception('Failed to create profile');
      }

      // Get the created profile ID
      final createdProfile = profileVM.currentProfile;
      if (createdProfile == null) {
        throw Exception('Profile not found after creation');
      }

      // Add all reports using database helper
      for (final report in reports) {
        // Convert parameters to the format expected by saveBloodReport
        final parametersMap = <String, Map<String, dynamic>>{};
        for (final param in report.parameters) {
          parametersMap[param.parameterName] = {
            'value': param.parameterValue,
            'unit': param.unit,
            'ref_min': param.referenceRangeMin,
            'ref_max': param.referenceRangeMax,
            'raw_name': param.parameterName,
          };
        }

        await _dbHelper.saveBloodReport(
          profileId: createdProfile.id!,
          testDate: report.testDate,
          parameters: parametersMap,
          labName: report.labName,
        );
      }

      // Reload reports
      await reportVM.loadReportsForProfile(createdProfile.id!);

      setState(() {
        _isLoading = false;
        _statusMessage =
            'Imported ${profile.name} with ${reports.length} reports!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${profile.name}!'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Import failed: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<void> _importReportsCsv(
    Profile profile,
    ReportViewModel reportVM,
  ) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Importing reports...';
    });

    try {
      final reports = await _exportService.importReportsFromCsv(profile.id!);

      for (final report in reports) {
        // Convert parameters to the format expected by saveBloodReport
        final parametersMap = <String, Map<String, dynamic>>{};
        for (final param in report.parameters) {
          parametersMap[param.parameterName] = {
            'value': param.parameterValue,
            'unit': param.unit,
            'ref_min': param.referenceRangeMin,
            'ref_max': param.referenceRangeMax,
            'raw_name': param.parameterName,
          };
        }

        await _dbHelper.saveBloodReport(
          profileId: profile.id!,
          testDate: report.testDate,
          parameters: parametersMap,
          labName: report.labName,
        );
      }

      // Reload reports
      await reportVM.loadReportsForProfile(profile.id!);

      setState(() {
        _isLoading = false;
        _statusMessage = 'Imported ${reports.length} reports!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${reports.length} reports!'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Import failed: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<BloodReport?> _showReportPicker(List<BloodReport> reports) async {
    return showModalBottomSheet<BloodReport>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Report',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            ...reports.map((report) {
              return ListTile(
                leading: const Icon(Icons.description),
                title: Text(report.testDate.toString().split(' ')[0]),
                subtitle: report.labName != null ? Text(report.labName!) : null,
                trailing: Text('${report.parameters.length} params'),
                onTap: () => Navigator.pop(context, report),
              );
            }),
          ],
        ),
      ),
    );
  }
}
