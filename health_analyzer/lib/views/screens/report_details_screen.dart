import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../theme/app_theme.dart';
import '../../theme/theme_extensions.dart';
import '../../models/blood_report.dart';
import '../../models/parameter.dart';
import '../../utils/page_transitions.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/profile_avatar.dart';
import '../../services/gemini_service.dart';
import '../../services/database_helper.dart';
import '../../viewmodels/report_viewmodel.dart';
import 'parameter_trend_screen.dart';
import 'dart:io';
import 'dart:convert';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';

/// Report details screen with grouped parameters
class ReportDetailsScreen extends StatefulWidget {
  final BloodReport report;
  final String? profileName;

  const ReportDetailsScreen({
    super.key,
    required this.report,
    this.profileName,
  });

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  late BloodReport _currentReport;
  final Map<String, bool> _expandedGroups = {};
  final GeminiService _geminiService = GeminiService();

  bool _isReprocessing = false;
  bool _showAiInsights = false;
  bool _loadingAiInsights = false;
  Map<String, dynamic>? _aiInsights;
  String? _aiError;

  @override
  void initState() {
    super.initState();
    _currentReport = widget.report;
    _initGroups();
    _loadCachedAiInsights();
  }

  void _initGroups() {
    _expandedGroups.clear();
    _getParameterGroups().forEach((group, _) {
      _expandedGroups[group] = false;
    });
  }

  void _loadCachedAiInsights() {
    if (_currentReport.aiAnalysis != null) {
      try {
        _aiInsights = jsonDecode(_currentReport.aiAnalysis!);
      } catch (e) {
        debugPrint('Error parsing cached AI analysis: $e');
      }
    }
  }

  /// Load AI insights for the report
  Future<void> _loadAiInsights({bool forceRefresh = false}) async {
    // Check if we have cached insights and not forcing refresh
    if (_aiInsights != null && !forceRefresh) return;

    if (_loadingAiInsights) return;

    setState(() {
      _loadingAiInsights = true;
      _aiError = null;
    });

    try {
      // Prepare abnormal parameters data
      final abnormalParams = _currentReport.abnormalParameters.map((p) {
        return {
          'name': p.rawParameterName ?? p.parameterName,
          'value': p.parameterValue,
          'unit': p.unit ?? '',
          'ref_min': p.referenceRangeMin,
          'ref_max': p.referenceRangeMax,
          'status': p.status,
        };
      }).toList();

      // Prepare all parameters data
      final allParams = _currentReport.parameters.map((p) {
        return {
          'name': p.rawParameterName ?? p.parameterName,
          'value': p.parameterValue,
          'unit': p.unit ?? '',
        };
      }).toList();

      final insights = await _geminiService.generateHealthInsights(
        abnormalParameters: abnormalParams,
        allParameters: allParams,
      );

      // Cache the AI analysis in database
      if (_currentReport.id != null) {
        final aiAnalysisJson = jsonEncode(insights);
        await DatabaseHelper.instance.updateAiAnalysis(
          _currentReport.id!,
          aiAnalysisJson,
        );
      }

      if (!mounted) return;
      setState(() {
        _aiInsights = insights;
        _loadingAiInsights = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiError = e.toString();
        _loadingAiInsights = false;
      });
    }
  }

  /// Reprocess the current report with Gemini AI
  Future<void> _reprocessReport() async {
    if (_isReprocessing) return;

    File? fileToProcess;
    if (_currentReport.reportImagePath != null &&
        _currentReport.reportImagePath!.isNotEmpty) {
      final f = File(_currentReport.reportImagePath!);
      if (await f.exists()) {
        fileToProcess = f;
      }
    }

    if (fileToProcess == null) {
      // Pick file from device
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result == null ||
          result.files.isEmpty ||
          result.files.single.path == null) {
        return;
      }
      fileToProcess = File(result.files.single.path!);
    }

    setState(() {
      _isReprocessing = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Reprocessing blood report with Gemini AI...'),
            ],
          ),
          duration: Duration(seconds: 45),
        ),
      );
    }

    try {
      final viewModel = context.read<ReportViewModel>();
      final updatedReport = await viewModel.reprocessReport(
        reportId: _currentReport.id!,
        reportFile: fileToProcess,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (updatedReport != null) {
        setState(() {
          _currentReport = updatedReport;
          _aiInsights = null;
          _initGroups();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Successfully extracted ${_currentReport.parameters.length} parameters!',
            ),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.error_outline,
              color: AppTheme.errorColor, size: 36),
          title: const Text('Reprocessing Failed'),
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: Theme.of(ctx).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Dismiss'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _reprocessReport();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isReprocessing = false;
        });
      }
    }
  }

  Map<String, List<Parameter>> _getParameterGroups() {
    final Map<String, List<Parameter>> groups = {
      'Complete Blood Count (CBC)': [],
      'Lipid Profile': [],
      'Liver Function Test': [],
      'Kidney Function Test': [],
      'Thyroid Profile': [],
      'Blood Sugar': [],
      'Others': [],
    };

    for (final param in _currentReport.parameters) {
      final name = param.parameterName.toLowerCase();

      // CBC
      if (name.contains('rbc') ||
          name.contains('wbc') ||
          name.contains('hemoglobin') ||
          name.contains('hematocrit') ||
          name.contains('platelet') ||
          name.contains('mcv') ||
          name.contains('mch') ||
          name.contains('neutrophil') ||
          name.contains('lymphocyte') ||
          name.contains('monocyte') ||
          name.contains('eosinophil') ||
          name.contains('basophil')) {
        groups['Complete Blood Count (CBC)']!.add(param);
      }
      // Lipid Profile
      else if (name.contains('cholesterol') ||
          name.contains('triglyceride') ||
          name.contains('hdl') ||
          name.contains('ldl') ||
          name.contains('vldl')) {
        groups['Lipid Profile']!.add(param);
      }
      // Liver Function
      else if (name.contains('sgpt') ||
          name.contains('sgot') ||
          name.contains('alt') ||
          name.contains('ast') ||
          name.contains('bilirubin') ||
          name.contains('alp') ||
          name.contains('ggt') ||
          name.contains('protein') ||
          name.contains('albumin') ||
          name.contains('globulin')) {
        groups['Liver Function Test']!.add(param);
      }
      // Kidney Function
      else if (name.contains('creatinine') ||
          name.contains('urea') ||
          name.contains('bun') ||
          name.contains('uric') ||
          name.contains('egfr')) {
        groups['Kidney Function Test']!.add(param);
      }
      // Thyroid
      else if (name.contains('tsh') ||
          name.contains('t3') ||
          name.contains('t4') ||
          name.contains('thyroid')) {
        groups['Thyroid Profile']!.add(param);
      }
      // Blood Sugar
      else if (name.contains('glucose') ||
          name.contains('sugar') ||
          name.contains('hba1c') ||
          name.contains('fasting') ||
          name.contains('pp') ||
          name.contains('random')) {
        groups['Blood Sugar']!.add(param);
      }
      // Others
      else {
        groups['Others']!.add(param);
      }
    }

    // Remove empty groups
    groups.removeWhere((key, value) => value.isEmpty);

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _getParameterGroups();
    final abnormalCount = _currentReport.abnormalParameters.length;
    final normalCount = _currentReport.parameters.length - abnormalCount;
    final bool hasZeroParams = _currentReport.parameters.isEmpty;

    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDate(_currentReport.testDate)),
            if (_currentReport.labName != null)
              Text(
                _currentReport.labName!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showOptionsMenu();
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Summary Card or Zero-Parameters Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: hasZeroParams
                  ? _buildEmptyParametersCard()
                  : _buildSummaryCard(normalCount, abnormalCount),
            ),
          ),

          if (!hasZeroParams) ...[
            // Parameters Groups
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final groupName = groups.keys.elementAt(index);
                  final parameters = groups[groupName]!;
                  final isExpanded = _expandedGroups[groupName] ?? false;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing8,
                    ),
                    child: _buildParameterGroup(
                      groupName,
                      parameters,
                      isExpanded,
                    ),
                  );
                },
                childCount: groups.length,
              ),
            ),

            // AI Insights Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: _buildAiInsightsSection(),
              ),
            ),
          ],

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: AppTheme.spacing32),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyParametersCard() {
    final hasFilePath = _currentReport.reportImagePath != null &&
        _currentReport.reportImagePath!.isNotEmpty;
    final fileExists =
        hasFilePath && File(_currentReport.reportImagePath!).existsSync();
    final fileName =
        hasFilePath ? p.basename(_currentReport.reportImagePath!) : null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        side: BorderSide(
          color: Colors.amber.shade300,
          width: 1.5,
        ),
      ),
      color: Colors.amber.shade50.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header icon + badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber.shade900,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '0 Parameters Extracted',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Incomplete / Failed Extraction',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.amber.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            const Divider(),
            const SizedBox(height: AppTheme.spacing12),

            // Explanation
            Text(
              'This report was saved but contains no extracted blood parameters. '
              'This can happen when a scan times out, network drops, '
              'or the AI response was interrupted.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing16),

            // Source File Status Box
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    fileExists
                        ? (fileName != null &&
                                fileName.toLowerCase().endsWith('.pdf')
                            ? Icons.picture_as_pdf
                            : Icons.image)
                        : Icons.broken_image_outlined,
                    color: fileExists
                        ? context.primaryColor
                        : Theme.of(context).colorScheme.error,
                    size: 24,
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileExists
                              ? (fileName ?? 'Source File')
                              : (hasFilePath
                                  ? 'Source file missing on device'
                                  : 'No source file attached'),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fileExists
                              ? 'Original document is ready to reprocess'
                              : 'Select document to reprocess',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: fileExists
                                        ? AppTheme.successColor
                                        : Theme.of(context).colorScheme.error,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (fileExists)
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 20),
                      tooltip: 'View Document',
                      onPressed: _showReportImage,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),

            // Action Buttons
            FilledButton.icon(
              onPressed: _isReprocessing ? null : _reprocessReport,
              icon: _isReprocessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isReprocessing
                  ? 'Reprocessing...'
                  : (fileExists ? 'Reprocess Report' : 'Pick File & Reprocess')),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: context.primaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            OutlinedButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.errorColor, size: 18),
              label: const Text(
                'Delete Report',
                style: TextStyle(color: AppTheme.errorColor),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.errorColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int normalCount, int abnormalCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        child: Column(
          children: [
            // Profile info
            if (widget.profileName != null)
              Row(
                children: [
                  ProfileAvatar(
                    name: widget.profileName!,
                    size: 40,
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Text(
                    widget.profileName!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),

            if (widget.profileName != null)
              const Divider(height: AppTheme.spacing24),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    'Total',
                    '${_currentReport.parameters.length}',
                    Icons.analytics_outlined,
                    context.primaryColor,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Normal',
                    '$normalCount',
                    Icons.check_circle_outline,
                    AppTheme.successColor,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Abnormal',
                    '$abnormalCount',
                    Icons.warning_amber_outlined,
                    abnormalCount > 0
                        ? AppTheme.errorColor
                        : AppTheme.textTertiary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacing16),

            // Status indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing12,
              ),
              decoration: BoxDecoration(
                color: abnormalCount > 0
                    ? Theme.of(context).colorScheme.errorContainer
                    : Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    abnormalCount > 0 ? Icons.warning : Icons.check_circle,
                    color: abnormalCount > 0
                        ? Theme.of(context).colorScheme.onErrorContainer
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Text(
                    abnormalCount > 0
                        ? 'Some values are outside normal range'
                        : 'All values are within normal range',
                    style: AppTheme.titleSmall.copyWith(
                      color: abnormalCount > 0
                          ? Theme.of(context).colorScheme.onErrorContainer
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing12),

            // View AI Insights button
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showAiInsights = !_showAiInsights;
                });
              },
              icon:
                  Icon(_showAiInsights ? Icons.expand_less : Icons.expand_more),
              label: const Text('View AI Analysis'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          value,
          style: AppTheme.titleLarge.copyWith(color: color),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          label,
          style: AppTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _buildParameterGroup(
    String groupName,
    List<Parameter> parameters,
    bool isExpanded,
  ) {
    final abnormalInGroup = parameters.where((p) => !p.isNormal).length;

    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedGroups[groupName] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Text(
                          '${parameters.length} parameters${abnormalInGroup > 0 ? ', $abnormalInGroup abnormal' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (abnormalInGroup > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing8,
                        vertical: AppTheme.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        '$abnormalInGroup',
                        style: AppTheme.labelSmall.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: AppTheme.spacing12),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Column(
              children: parameters.map((param) {
                return _buildParameterCard(param);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildParameterCard(Parameter parameter) {
    return Builder(
      builder: (context) {
        final status = parameter.status;
        final colorScheme = Theme.of(context).colorScheme;

        Color bgColor;
        Color borderColor;
        Color textColor;
        StatusType badgeType;

        if (status == 'high') {
          // Error state - red tinted surface
          bgColor = Color.alphaBlend(
            AppTheme.errorColor.withValues(alpha: 0.12),
            colorScheme.surface,
          );
          borderColor = AppTheme.errorColor;
          textColor = colorScheme.onSurface;
          badgeType = StatusType.high;
        } else if (status == 'low') {
          // Warning state - orange/yellow tinted surface
          bgColor = Color.alphaBlend(
            AppTheme.warningColor.withValues(alpha: 0.12),
            colorScheme.surface,
          );
          borderColor = AppTheme.warningColor;
          textColor = colorScheme.onSurface;
          badgeType = StatusType.low;
        } else {
          // Success state - green tinted surface
          bgColor = Color.alphaBlend(
            AppTheme.successColor.withValues(alpha: 0.12),
            colorScheme.surface,
          );
          borderColor = AppTheme.successColor;
          textColor = colorScheme.onSurface;
          badgeType = StatusType.normal;
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(
            AppTheme.spacing16,
            0,
            AppTheme.spacing16,
            AppTheme.spacing12,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: borderColor.withValues(alpha: 0.3), width: 1),
          ),
          child: InkWell(
            onTap: () {
              // Navigate to parameter trend screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ParameterTrendScreen(
                    profileId: _currentReport.profileId,
                    profileName: widget.profileName ?? 'Profile',
                    initialParameter: parameter.parameterName,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatParameterName(parameter.rawParameterName ??
                              parameter.parameterName),
                          style: AppTheme.titleSmall.copyWith(color: textColor),
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Row(
                          children: [
                            Text(
                              '${parameter.parameterValue}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall!
                                  .copyWith(
                                    fontSize: 20,
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (parameter.unit != null) ...[
                              const SizedBox(width: AppTheme.spacing4),
                              Text(
                                parameter.unit!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: textColor.withValues(alpha: 0.8),
                                    ),
                              ),
                            ],
                          ],
                        ),
                        if (parameter.referenceRangeMin != null &&
                            parameter.referenceRangeMax != null) ...[
                          const SizedBox(height: AppTheme.spacing4),
                          Text(
                            'Range: ${parameter.referenceRangeMin} - ${parameter.referenceRangeMax}',
                            style:
                                Theme.of(context).textTheme.bodySmall!.copyWith(
                                      color: textColor.withValues(alpha: 0.7),
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(
                        label: status == 'high'
                            ? 'High'
                            : status == 'low'
                                ? 'Low'
                                : 'Normal',
                        type: badgeType,
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Icon(
                        status == 'high'
                            ? Icons.arrow_upward
                            : status == 'low'
                                ? Icons.arrow_downward
                                : Icons.check,
                        size: 20,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiInsightsSection() {
    if (!_showAiInsights) {
      return const SizedBox.shrink();
    }

    // Load AI insights when section is expanded
    if (_aiInsights == null && !_loadingAiInsights && _aiError == null) {
      _loadAiInsights();
    }

    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: Text(
                        'AI Health Analysis',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: colorScheme.primary,
                            ),
                      ),
                    ),
                    // Refresh button
                    if (_aiInsights != null)
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: () {
                          _loadAiInsights(forceRefresh: true);
                        },
                        tooltip: 'Regenerate insights',
                      ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacing16),
                const Divider(),
                const SizedBox(height: AppTheme.spacing16),

                // Loading state
                if (_loadingAiInsights)
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppTheme.spacing12),
                        Text(
                          'Analyzing your report...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )

                // Error state
                else if (_aiError != null)
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: colorScheme.error,
                          size: 48,
                        ),
                        const SizedBox(height: AppTheme.spacing12),
                        Text(
                          'Failed to generate AI insights',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Text(
                          _aiError!.contains('API key')
                              ? 'Please check your Gemini API key in settings'
                              : 'Please try again later',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacing16),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _aiError = null;
                            });
                            _loadAiInsights();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  )

                // AI insights content
                else if (_aiInsights != null)
                  _buildAiInsightsContent()

                // Initial state
                else
                  Center(
                    child: TextButton.icon(
                      onPressed: _loadAiInsights,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate AI Analysis'),
                    ),
                  ),

                // Disclaimer (always show when insights are loaded)
                if (_aiInsights != null || _loadingAiInsights) ...[
                  const SizedBox(height: AppTheme.spacing20),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing12),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Expanded(
                          child: Text(
                            'This is AI-generated information for educational purposes only. Always consult qualified healthcare professionals for medical advice.',
                            style:
                                Theme.of(context).textTheme.bodySmall!.copyWith(
                                      color: colorScheme.onTertiaryContainer,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiInsightsContent() {
    final insights = _aiInsights!;

    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Assessment
            Text(
              'Overall Assessment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              insights['overall_assessment'] ?? 'No assessment available',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            // Areas of Concern
            if (insights['concerns'] != null &&
                (insights['concerns'] as List).isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacing20),
              Text(
                'Areas of Concern',
                style: AppTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.spacing12),
              ...(insights['concerns'] as List).map((concern) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 18,
                            color: colorScheme.tertiary,
                          ),
                          const SizedBox(width: AppTheme.spacing8),
                          Expanded(
                            child: Text(
                              concern['parameter'] ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Padding(
                        padding: const EdgeInsets.only(left: 26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (concern['issue'] != null) ...[
                              Text(
                                concern['issue'],
                                style: AppTheme.bodySmall,
                              ),
                              const SizedBox(height: AppTheme.spacing4),
                            ],
                            if (concern['recommendation'] != null)
                              Text(
                                '💡 ${concern['recommendation']}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                      color: colorScheme.primary,
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Positive Notes
            if (insights['positive_notes'] != null &&
                (insights['positive_notes'] as List).isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacing20),
              Text(
                'Positive Observations',
                style: AppTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.spacing12),
              ...(insights['positive_notes'] as List).map((note) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Expanded(
                        child: Text(
                          note,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Next Steps
            if (insights['next_steps'] != null &&
                (insights['next_steps'] as List).isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacing20),
              Text(
                'Recommended Next Steps',
                style: AppTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.spacing12),
              ...(insights['next_steps'] as List).asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: context.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: AppTheme.labelSmall.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.refresh, color: AppTheme.primaryColor),
                title: const Text('Reprocess Report'),
                subtitle: const Text('Extract parameters with Gemini AI'),
                onTap: () {
                  Navigator.pop(context);
                  _reprocessReport();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('View Report Image'),
                onTap: () {
                  debugPrint('🖼️ View Report Image tapped from bottom sheet');
                  debugPrint(
                      '  Report Image Path: ${_currentReport.reportImagePath}');
                  Navigator.pop(context);
                  if (_currentReport.reportImagePath != null) {
                    _showReportImage();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No image attached to this report'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Report'),
                onTap: () {
                  Navigator.pop(context);
                  _shareReport();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.errorColor),
                title: const Text(
                  'Delete Report',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareReport() async {
    try {
      // Create a text summary of the report
      final StringBuffer summary = StringBuffer();

      summary.writeln('📊 Blood Test Report');
      summary.writeln('━━━━━━━━━━━━━━━━━━━');
      if (widget.profileName != null) {
        summary.writeln('Patient: ${widget.profileName}');
      }
      summary.writeln('Date: ${_formatDate(_currentReport.testDate)}');
      if (_currentReport.labName != null) {
        summary.writeln('Lab: ${_currentReport.labName}');
      }
      summary.writeln('');

      summary.writeln('Summary:');
      final abnormalCount = _currentReport.abnormalParameters.length;
      final normalCount = _currentReport.parameters.length - abnormalCount;
      summary.writeln('• Total Parameters: ${_currentReport.parameters.length}');
      summary.writeln('• Normal: $normalCount');
      summary.writeln('• Abnormal: $abnormalCount');
      summary.writeln('');

      // Add abnormal parameters if any
      if (abnormalCount > 0) {
        summary.writeln('⚠️ Abnormal Parameters:');
        summary.writeln('━━━━━━━━━━━━━━━━━━━');
        for (final param in _currentReport.abnormalParameters) {
          final name = _formatParameterName(
              param.rawParameterName ?? param.parameterName);
          summary.writeln('$name: ${param.parameterValue}${param.unit ?? ''}');
          if (param.referenceRangeMin != null &&
              param.referenceRangeMax != null) {
            summary.writeln(
                '  Range: ${param.referenceRangeMin} - ${param.referenceRangeMax}');
          }
          summary.writeln('  Status: ${param.status.toUpperCase()}');
          summary.writeln('');
        }
      }

      // Add all parameters grouped
      final groups = _getParameterGroups();
      summary.writeln('📋 Detailed Results:');
      summary.writeln('━━━━━━━━━━━━━━━━━━━');

      for (final entry in groups.entries) {
        summary.writeln('\n${entry.key}:');
        for (final param in entry.value) {
          final name = _formatParameterName(
              param.rawParameterName ?? param.parameterName);
          final status = param.isNormal ? '✓' : '⚠️';
          summary.writeln(
              '  $status $name: ${param.parameterValue}${param.unit ?? ''}');
        }
      }

      summary.writeln('\n━━━━━━━━━━━━━━━━━━━');
      summary.writeln('Generated by LabLens');
      summary.writeln('Health tracking made simple');

      // Share the text
      await Share.share(
        summary.toString(),
        subject: 'Blood Test Report - ${_formatDate(_currentReport.testDate)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share report: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Report'),
          content: const Text(
            'Are you sure you want to delete this report? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            // Material 3 FilledButton for destructive action
            FilledButton(
              onPressed: () async {
                debugPrint(
                    '🗑️ Delete button pressed for report ${_currentReport.id}');
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                final profileId = _currentReport.profileId;
                final reportId = _currentReport.id!;

                nav.pop(); // Close dialog

                final viewModel = context.read<ReportViewModel>();
                debugPrint('  Calling deleteReport...');
                final success = await viewModel.deleteReport(reportId);

                if (success) {
                  debugPrint('  ✅ Report deleted successfully');
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Report deleted successfully'),
                    ),
                  );
                  nav.pop(); // Go back to report list

                  debugPrint('  🔄 Reloading reports for profile $profileId');
                  await viewModel.loadReportsForProfile(profileId);
                } else {
                  debugPrint('  ❌ Failed to delete report: ${viewModel.error}');
                  messenger.showSnackBar(
                    SnackBar(
                      content:
                          Text(viewModel.error ?? 'Failed to delete report'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  /// Show the report image in a full-screen viewer
  void _showReportImage() {
    final imagePath = _currentReport.reportImagePath!;
    final isPDF = imagePath.toLowerCase().endsWith('.pdf');

    debugPrint('🖼️ Opening report image viewer');
    debugPrint('  Path: $imagePath');
    debugPrint('  Is PDF: $isPDF');
    debugPrint('  File exists: ${File(imagePath).existsSync()}');

    context.pushModal(
      _ReportImageViewer(
        imagePath: imagePath,
        isPDF: isPDF,
        reportDate: _currentReport.testDate,
      ),
    );
  }

  String _formatDate(DateTime date) {
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

  String _formatParameterName(String name) {
    // Convert snake_case to Title Case
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}

/// Full-screen image/PDF viewer widget
class _ReportImageViewer extends StatelessWidget {
  final String imagePath;
  final bool isPDF;
  final DateTime reportDate;

  const _ReportImageViewer({
    required this.imagePath,
    required this.isPDF,
    required this.reportDate,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_formatDate(reportDate)),
      ),
      body: FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.white, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Image file not found',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    imagePath,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          if (isPDF) {
            return SfPdfViewer.file(file);
          }

          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.file(
                file,
                fit: BoxFit.contain,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('❌ Error loading image: $error');
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.white, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
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
