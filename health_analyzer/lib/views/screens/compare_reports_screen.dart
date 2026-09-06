import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/blood_report.dart';
import '../../models/parameter.dart';
import '../../viewmodels/report_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_extensions.dart';
import 'package:intl/intl.dart';

/// Screen to compare two blood reports side by side
class CompareReportsScreen extends StatefulWidget {
  final int profileId;
  final String profileName;

  const CompareReportsScreen({
    super.key,
    required this.profileId,
    required this.profileName,
  });

  @override
  State<CompareReportsScreen> createState() => _CompareReportsScreenState();
}

class _CompareReportsScreenState extends State<CompareReportsScreen> {
  BloodReport? _report1;
  BloodReport? _report2;
  List<BloodReport> _availableReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final reportVM = context.read<ReportViewModel>();
    await reportVM.loadReportsForProfile(widget.profileId);

    setState(() {
      _availableReports = reportVM.reports;
      _isLoading = false;

      // Auto-select first two reports if available
      if (_availableReports.length >= 2) {
        _report1 = _availableReports[0];
        _report2 = _availableReports[1];
      } else if (_availableReports.length == 1) {
        _report1 = _availableReports[0];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Reports'),
        actions: [
          // Export comparison button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _canCompare ? _exportComparison : null,
            tooltip: 'Export Comparison',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availableReports.length < 2
              ? _buildInsufficientReportsView()
              : _buildComparisonView(),
    );
  }

  Widget _buildInsufficientReportsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.compare_arrows,
              size: 80,
              color: context.onSurfaceColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppTheme.spacing24),
            Text(
              'Need More Reports',
              style: AppTheme.headingMedium.copyWith(
                color: context.onSurfaceColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              'You need at least 2 reports to compare.\nCurrent reports: ${_availableReports.length}',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(
                color: context.onSurfaceColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppTheme.spacing32),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonView() {
    return Column(
      children: [
        // Report selection cards
        _buildReportSelectionRow(),

        const SizedBox(height: AppTheme.spacing16),

        // Comparison table
        Expanded(
          child: _canCompare
              ? _buildComparisonTable()
              : _buildSelectReportsPrompt(),
        ),
      ],
    );
  }

  Widget _buildReportSelectionRow() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      color: context.surfaceContainerLowest,
      child: Row(
        children: [
          Expanded(
            child: _buildReportSelector(
              title: 'Report 1',
              selectedReport: _report1,
              onSelect: (report) => setState(() => _report1 = report),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
            child: Icon(
              Icons.compare_arrows,
              color: context.primaryColor,
              size: 32,
            ),
          ),
          Expanded(
            child: _buildReportSelector(
              title: 'Report 2',
              selectedReport: _report2,
              onSelect: (report) => setState(() => _report2 = report),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSelector({
    required String title,
    required BloodReport? selectedReport,
    required Function(BloodReport) onSelect,
  }) {
    return Card(
      child: InkWell(
        onTap: () => _showReportPicker(title, selectedReport, onSelect),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.labelSmall.copyWith(
                  color: context.onSurfaceColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              if (selectedReport != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(selectedReport.testDate),
                      style: AppTheme.titleSmall.copyWith(
                        color: context.onSurfaceColor,
                      ),
                    ),
                    if (selectedReport.labName != null)
                      Text(
                        selectedReport.labName!,
                        style: AppTheme.bodySmall.copyWith(
                          color: context.onSurfaceColor.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                )
              else
                Text(
                  'Select Report',
                  style: AppTheme.bodyMedium.copyWith(
                    color: context.primaryColor,
                  ),
                ),
              const SizedBox(height: AppTheme.spacing4),
              Row(
                children: [
                  const Spacer(),
                  Icon(
                    Icons.arrow_drop_down,
                    color: context.primaryColor,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportPicker(
    String title,
    BloodReport? currentSelection,
    Function(BloodReport) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select $title',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            ..._availableReports.map((report) {
              final isSelected = report.id == currentSelection?.id;
              return ListTile(
                selected: isSelected,
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.description,
                  color: isSelected ? context.primaryColor : null,
                ),
                title: Text(_formatDate(report.testDate)),
                subtitle: report.labName != null ? Text(report.labName!) : null,
                trailing: Text('${report.parameters.length} params'),
                onTap: () {
                  onSelect(report);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectReportsPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app,
              size: 64,
              color: context.onSurfaceColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'Select Two Reports',
              style: AppTheme.titleLarge.copyWith(
                color: context.onSurfaceColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Tap on the cards above to select reports for comparison',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(
                color: context.onSurfaceColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    // Get all unique parameter names from both reports
    final allParamNames = <String>{};
    allParamNames.addAll(_report1!.parameters.map((p) => p.parameterName));
    allParamNames.addAll(_report2!.parameters.map((p) => p.parameterName));

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: [
        // Summary card
        _buildSummaryCard(),
        const SizedBox(height: AppTheme.spacing16),

        // Parameters comparison
        Card(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                decoration: BoxDecoration(
                  color: context.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Parameter',
                        style: AppTheme.titleSmall.copyWith(
                          color: context.onPrimaryContainer,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Report 1',
                        textAlign: TextAlign.center,
                        style: AppTheme.labelMedium.copyWith(
                          color: context.onPrimaryContainer,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Report 2',
                        textAlign: TextAlign.center,
                        style: AppTheme.labelMedium.copyWith(
                          color: context.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40), // For trend icon
                  ],
                ),
              ),

              // Parameters
              ...allParamNames.map((paramName) {
                return _buildParameterRow(paramName);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final report1AbnormalCount = _report1!.abnormalParameters.length;
    final report2AbnormalCount = _report2!.abnormalParameters.length;
    final commonParams = _getCommonParameters().length;

    return Card(
      color: context.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: context.onPrimaryContainer,
                ),
                const SizedBox(width: AppTheme.spacing8),
                Text(
                  'Comparison Summary',
                  style: AppTheme.titleMedium.copyWith(
                    color: context.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryStat(
                    'Common Parameters',
                    '$commonParams',
                    Icons.done_all,
                  ),
                ),
                Expanded(
                  child: _buildSummaryStat(
                    'Report 1 Abnormal',
                    '$report1AbnormalCount',
                    Icons.warning,
                  ),
                ),
                Expanded(
                  child: _buildSummaryStat(
                    'Report 2 Abnormal',
                    '$report2AbnormalCount',
                    Icons.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: context.onPrimaryContainer,
          size: 24,
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          value,
          style: AppTheme.headingSmall.copyWith(
            color: context.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.bodySmall.copyWith(
            color: context.onPrimaryContainer.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildParameterRow(String paramName) {
    final param1 = _report1!.getParameter(paramName);
    final param2 = _report2!.getParameter(paramName);

    // Calculate trend
    String? trend;
    IconData? trendIcon;
    Color? trendColor;

    if (param1 != null && param2 != null) {
      final diff = param2.parameterValue - param1.parameterValue;
      if (diff > 0) {
        trend = 'up';
        trendIcon = Icons.trending_up;
        trendColor = Colors.red;
      } else if (diff < 0) {
        trend = 'down';
        trendIcon = Icons.trending_down;
        trendColor = Colors.blue;
      } else {
        trend = 'same';
        trendIcon = Icons.trending_flat;
        trendColor = Colors.grey;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.outlineVariantColor.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Parameter name
          Expanded(
            flex: 2,
            child: Text(
              _formatParameterName(paramName),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.onSurfaceColor,
                  ),
            ),
          ),

          // Report 1 value
          Expanded(
            child: _buildValueCell(param1),
          ),

          // Report 2 value
          Expanded(
            child: _buildValueCell(param2),
          ),

          // Trend icon
          SizedBox(
            width: 40,
            child: trend != null
                ? Icon(
                    trendIcon,
                    color: trendColor,
                    size: 20,
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCell(Parameter? param) {
    if (param == null) {
      return Text(
        'N/A',
        textAlign: TextAlign.center,
        style: AppTheme.bodySmall.copyWith(
          color: context.onSurfaceColor.withValues(alpha: 0.3),
        ),
      );
    }

    Color statusColor;
    switch (param.status) {
      case 'high':
        statusColor = Colors.red;
        break;
      case 'low':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = context.successColor;
    }

    return Column(
      children: [
        Text(
          param.parameterValue.toStringAsFixed(1),
          textAlign: TextAlign.center,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
        if (param.unit != null)
          Text(
            param.unit!,
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall.copyWith(
              color: context.onSurfaceColor.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }

  List<String> _getCommonParameters() {
    if (_report1 == null || _report2 == null) return [];

    final params1 = _report1!.parameters.map((p) => p.parameterName).toSet();
    final params2 = _report2!.parameters.map((p) => p.parameterName).toSet();

    return params1.intersection(params2).toList();
  }

  bool get _canCompare => _report1 != null && _report2 != null;

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatParameterName(String name) {
    return name
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _exportComparison() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature coming soon!'),
      ),
    );
  }
}
