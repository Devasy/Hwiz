import 'dart:io';
import 'package:flutter/material.dart';

import '../services/batch_processing_service.dart';
import '../services/database_helper.dart';
import '../models/blood_report.dart';

/// Dialog for batch processing multiple blood reports with progress tracking
///
/// Features:
/// - Real-time progress bar
/// - Current file being processed
/// - Success/failure count
/// - Cancellation support
/// - Detailed results summary
///
/// Usage:
/// ```dart
/// final result = await showDialog<BatchProcessingResult>(
///   context: context,
///   barrierDismissible: false,
///   builder: (context) => BatchProcessingDialog(
///     files: selectedFiles,
///     profileId: currentProfile.id,
///     gender: currentProfile.gender,
///   ),
/// );
///
/// if (result != null) {
///   // Handle result
///   print('Successful: ${result.successCount}/${result.totalProcessed}');
/// }
/// ```
class BatchProcessingDialog extends StatefulWidget {
  final List<File> files;
  final int profileId;
  final String? gender;
  final int maxParallel;
  final int maxRetries;

  const BatchProcessingDialog({
    super.key,
    required this.files,
    required this.profileId,
    this.gender,
    this.maxParallel = 4,
    this.maxRetries = 2,
  });

  @override
  State<BatchProcessingDialog> createState() => _BatchProcessingDialogState();
}

class _BatchProcessingDialogState extends State<BatchProcessingDialog> {
  final BatchProcessingService _batchService = BatchProcessingService();

  int _processed = 0;
  int _successful = 0;
  int _failed = 0;
  String? _currentFile;
  bool _isProcessing = true;
  bool _isCancelling = false;
  BatchProcessingResult? _result;

  @override
  void initState() {
    super.initState();
    _startBatchProcessing();
  }

  Future<void> _startBatchProcessing() async {
    try {
      final result = await _batchService.processReports(
        files: widget.files,
        profileId: widget.profileId,
        gender: widget.gender,
        maxParallel: widget.maxParallel,
        maxRetries: widget.maxRetries,
        onProgress: (processed, total, currentFile) {
          if (mounted) {
            setState(() {
              _processed = processed;
              _currentFile = currentFile;
            });
          }
        },
        onReportProcessed: (file, report, error) {
          if (mounted) {
            setState(() {
              if (error == null) {
                _successful++;
              } else {
                _failed++;
              }
            });
          }

          // Save successful reports to database
          if (report != null) {
            _saveReportToDatabase(report);
          }
        },
      );

      if (mounted) {
        setState(() {
          _result = result;
          _isProcessing = false;
        });

        // Only auto-close if all reports succeeded with zero failures
        if (result.failureCount == 0) {
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted && !_isCancelling) {
            Navigator.of(context).pop(result);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Batch processing error: $e')),
        );
      }
    }
  }

  Future<void> _retryFailedFiles() async {
    if (_result == null || _result!.failed.isEmpty) return;

    final failedFiles = _result!.failed.map((f) => f.file).toList();
    final previousSuccessful = List<BatchReportResult>.from(_result!.successful);

    setState(() {
      _isProcessing = true;
      _isCancelling = false;
      _processed = 0;
      _successful = 0;
      _failed = 0;
      _currentFile = null;
    });

    try {
      final retryResult = await _batchService.processReports(
        files: failedFiles,
        profileId: widget.profileId,
        gender: widget.gender,
        maxParallel: widget.maxParallel,
        maxRetries: widget.maxRetries + 1,
        onProgress: (processed, total, currentFile) {
          if (mounted) {
            setState(() {
              _processed = processed;
              _currentFile = currentFile;
            });
          }
        },
        onReportProcessed: (file, report, error) {
          if (mounted) {
            setState(() {
              if (error == null) {
                _successful++;
              } else {
                _failed++;
              }
            });
          }

          if (report != null) {
            _saveReportToDatabase(report);
          }
        },
      );

      if (mounted) {
        final mergedSuccessful = [...previousSuccessful, ...retryResult.successful];
        final mergedResult = BatchProcessingResult(
          totalProcessed: widget.files.length,
          successful: mergedSuccessful,
          failed: retryResult.failed,
          startTime: _result!.startTime,
          endTime: DateTime.now(),
          cancelled: retryResult.cancelled,
        );

        setState(() {
          _result = mergedResult;
          _isProcessing = false;
        });

        if (mergedResult.failureCount == 0) {
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted && !_isCancelling) {
            Navigator.of(context).pop(mergedResult);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Retry error: $e')),
        );
      }
    }
  }

  Future<void> _saveReportToDatabase(BloodReport report) async {
    try {
      final db = await DatabaseHelper.instance.database;

      debugPrint('💾 Saving report to database...');
      debugPrint('   Profile ID: ${report.profileId}');
      debugPrint('   Test Date: ${report.testDate}');
      debugPrint('   Parameters: ${report.parameters.length}');

      // Insert report
      final reportId = await db.insert('reports', report.toMap());

      // Insert parameters
      int paramCount = 0;
      for (final param in report.parameters) {
        final paramMap = param.toMap();
        paramMap['report_id'] = reportId;
        await db.insert('blood_parameters', paramMap);
        paramCount++;
      }

      debugPrint('✅ Report saved successfully!');
      debugPrint('   Report ID: $reportId');
      debugPrint('   Parameters saved: $paramCount');
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving report: $e');
      debugPrint('   Stack trace: $stackTrace');
    }
  }

  void _cancelProcessing() {
    setState(() {
      _isCancelling = true;
    });
    _batchService.cancel();
  }

  @override
  void dispose() {
    _batchService.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.files.length;
    final progress = total > 0 ? _processed / total : 0.0;

    return PopScope(
      canPop: false, // Always prevent back button dismissal
      onPopInvokedWithResult: (didPop, result) {
        // Only allow programmatic close with result
        if (!didPop && !_isProcessing && _result != null) {
          Navigator.of(context).pop(_result);
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Row(
                children: [
                  Icon(
                    _isProcessing
                        ? Icons.hourglass_top
                        : _result?.successRate == 1.0
                            ? Icons.check_circle
                            : Icons.info,
                    color: _isProcessing
                        ? theme.colorScheme.primary
                        : _result?.successRate == 1.0
                            ? Colors.green
                            : Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _isProcessing
                          ? 'Processing Reports...'
                          : 'Processing Complete',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_isProcessing && !_isCancelling)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _cancelProcessing,
                      tooltip: 'Cancel',
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Progress bar
              if (_isProcessing) ...[
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
              ],

              // Status information
              if (_isProcessing) ...[
                _buildStatusRow(
                  icon: Icons.pending,
                  label: 'Progress',
                  value: '$_processed / $total reports',
                  color: theme.colorScheme.primary,
                ),
                if (_currentFile != null) ...[
                  const SizedBox(height: 8),
                  _buildStatusRow(
                    icon: Icons.description,
                    label: 'Processing',
                    value: _currentFile!,
                    color: theme.colorScheme.secondary,
                  ),
                ],
                const SizedBox(height: 8),
                _buildStatusRow(
                  icon: Icons.check_circle,
                  label: 'Successful',
                  value: '$_successful',
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                _buildStatusRow(
                  icon: Icons.error,
                  label: 'Failed',
                  value: '$_failed',
                  color: Colors.red,
                ),
                if (_isCancelling) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            theme.colorScheme.error,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Cancelling...',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],

              // Results summary
              if (!_isProcessing && _result != null) ...[
                _buildResultCard(context, _result!),
                const SizedBox(height: 24),

                // Action buttons
                if (_result!.failed.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(_result),
                          child: const Text('Dismiss'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.refresh),
                          onPressed: _retryFailedFiles,
                          label: Text('Retry (${_result!.failed.length})'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(_result),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(BuildContext context, BatchProcessingResult result) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success/Failure counts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                icon: Icons.check_circle,
                label: 'Successful',
                value: '${result.successCount}',
                color: Colors.green,
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              _buildStatColumn(
                icon: Icons.error,
                label: 'Failed',
                value: '${result.failureCount}',
                color: Colors.red,
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              _buildStatColumn(
                icon: Icons.timer,
                label: 'Duration',
                value: '${result.duration.inSeconds}s',
                color: theme.colorScheme.primary,
              ),
            ],
          ),

          if (result.hasWarnings) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.warning,
                  size: 20,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  '${result.allWarnings.length} warnings detected',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],

          if (result.failed.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              'Failed Reports:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...result.failed.take(3).map((failure) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.close, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          failure.fileName,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
            if (result.failed.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${result.failed.length - 3} more',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

/// Helper function to show batch processing dialog
Future<BatchProcessingResult?> showBatchProcessingDialog({
  required BuildContext context,
  required List<File> files,
  required int profileId,
  String? gender,
  int maxParallel = 4,
  int maxRetries = 2,
}) async {
  return showDialog<BatchProcessingResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => BatchProcessingDialog(
      files: files,
      profileId: profileId,
      gender: gender,
      maxParallel: maxParallel,
      maxRetries: maxRetries,
    ),
  );
}
