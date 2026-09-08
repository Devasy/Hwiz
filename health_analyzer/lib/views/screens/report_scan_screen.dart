import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_extensions.dart';
import '../../models/profile.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/report_viewmodel.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/batch_processing_dialog.dart';
import '../widgets/profile_switcher_sheet.dart';

/// Screen for scanning/uploading reports
class ReportScanScreen extends StatefulWidget {
  const ReportScanScreen({super.key});

  @override
  State<ReportScanScreen> createState() => _ReportScanScreenState();
}

class _ReportScanScreenState extends State<ReportScanScreen> {
  bool _isProcessing = false;
  double? _processingProgress;

  Future<void> _handleCamera() async {
    final profileVM = context.read<ProfileViewModel>();
    final profile = profileVM.currentProfile;

    if (profile == null) {
      _showError('Please select a profile first');
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingProgress = null;
    });

    try {
      final reportViewModel = context.read<ReportViewModel>();
      final success = await reportViewModel.scanFromCamera(profile.id!);

      if (success && mounted) {
        Navigator.of(context).pop();
        _showSuccess('Report scanned successfully!');
      } else if (mounted && reportViewModel.error != null) {
        _showError(reportViewModel.error!);
      }
    } catch (e) {
      _showError('Failed to capture image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processBatchFiles(List<File> files, Profile profile) async {
    if (files.isEmpty) return;

    try {
      final batchResult = await showBatchProcessingDialog(
        context: context,
        files: files,
        profileId: profile.id!,
        gender: profile.gender,
      );

      debugPrint(
          '📊 Batch processing result: ${batchResult != null ? "Received" : "NULL!"}');

      if (batchResult != null && mounted) {
        debugPrint('🔄 Reloading reports for profile ${profile.id}...');
        final reportViewModel = context.read<ReportViewModel>();
        await reportViewModel.loadReportsForProfile(profile.id!);
        debugPrint('✅ Reports reloaded successfully');

        if (batchResult.successCount > 0 && batchResult.failureCount == 0) {
          if (mounted) {
            Navigator.of(context).pop();
            _showSuccess(
              '${batchResult.successCount}/${batchResult.totalProcessed} '
              'report${batchResult.successCount > 1 ? 's' : ''} processed successfully!',
            );
          }
        } else if (batchResult.failureCount > 0) {
          if (mounted) {
            _showFailureDetails(batchResult, profile);
          }
        }
      } else if (batchResult == null && mounted) {
        final reportViewModel = context.read<ReportViewModel>();
        await reportViewModel.loadReportsForProfile(profile.id!);
        if (mounted) {
          _showSuccess('Reports may have been saved. Please check your report list.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to process batch: $e');
      }
    }
  }

  Future<void> _handleGallery() async {
    final profileVM = context.read<ProfileViewModel>();
    final profile = profileVM.currentProfile;

    if (profile == null) {
      _showError('Please select a profile first');
      return;
    }

    try {
      final reportViewModel = context.read<ReportViewModel>();
      final files = await reportViewModel.pickMultiplePhotos();

      if (files.isEmpty) {
        return; // User cancelled
      }

      if (files.length > 1) {
        // Multiple photos selected -> route to batch processing
        await _processBatchFiles(files, profile);
      } else {
        // Single photo
        setState(() {
          _isProcessing = true;
          _processingProgress = null;
        });

        final success = await reportViewModel.processImageFile(files.first, profile.id!);

        if (success && mounted) {
          Navigator.of(context).pop();
          _showSuccess('Report scanned successfully!');
        } else if (mounted && reportViewModel.error != null) {
          _showError(
            reportViewModel.error!,
            onRetry: _handleGallery,
          );
        }
      }
    } catch (e) {
      _showError('Failed to pick/process image: $e', onRetry: _handleGallery);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handlePdf({bool allowMultiple = true}) async {
    final profileVM = context.read<ProfileViewModel>();
    final profile = profileVM.currentProfile;

    if (profile == null) {
      _showError('Please select a profile first');
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: allowMultiple,
        dialogTitle: allowMultiple ? 'Select PDF Report(s)' : 'Select PDF Report',
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      final files = result.files
          .where((f) => f.path != null)
          .map((f) => File(f.path!))
          .toList();

      if (files.isEmpty) {
        _showError('No valid PDF files selected');
        return;
      }

      if (files.length > 1) {
        await _processBatchFiles(files, profile);
      } else {
        // Single PDF
        setState(() {
          _isProcessing = true;
          _processingProgress = null;
        });

        final reportViewModel = context.read<ReportViewModel>();
        final success = await reportViewModel.processPdfFile(files.first, profile.id!);

        if (success && mounted) {
          Navigator.of(context).pop();
          _showSuccess('Report scanned successfully!');
        } else if (mounted && reportViewModel.error != null) {
          _showError(
            reportViewModel.error!,
            onRetry: () => _handlePdf(allowMultiple: allowMultiple),
          );
        }
      }
    } catch (e) {
      _showError('Failed to process PDF: $e', onRetry: () => _handlePdf(allowMultiple: allowMultiple));
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleBatchUpload() async {
    final profileVM = context.read<ProfileViewModel>();
    final profile = profileVM.currentProfile;

    if (profile == null) {
      _showError('Please select a profile first');
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        dialogTitle: 'Select Multiple Reports',
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      final files = result.files
          .where((f) => f.path != null)
          .map((f) => File(f.path!))
          .toList();

      if (files.isEmpty) {
        _showError('No valid files selected');
        return;
      }

      await _processBatchFiles(files, profile);
    } catch (e) {
      if (mounted) {
        _showError('Failed to process batch: $e');
      }
    }
  }

  void _showFailureDetails(dynamic batchResult, Profile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 12),
            const Text('Some Reports Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${batchResult.failureCount} report${batchResult.failureCount > 1 ? 's' : ''} could not be processed:',
            ),
            const SizedBox(height: 12),
            ...batchResult.failed.take(5).map((failure) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.close, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          failure.fileName,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),
            if (batchResult.failed.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${batchResult.failed.length - 5} more',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'You can retry processing the failed reports now.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Dismiss'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Navigator.of(context).pop();
              final failedFiles = (batchResult.failed as List)
                  .map((f) => f.file as File)
                  .toList();
              _processBatchFiles(failedFiles, profile);
            },
            label: Text('Retry (${batchResult.failureCount})'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showError(String message, {VoidCallback? onRetry}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: onRetry != null
              ? SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.amberAccent,
                  onPressed: onRetry,
                )
              : null,
          duration: onRetry != null
              ? const Duration(seconds: 6)
              : const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        title: const Text('Scan Report'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isProcessing
          ? LoadingIndicator(
              message: 'Analyzing report...',
              showProgress: _processingProgress != null,
              progress: _processingProgress,
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile indicator
                    Consumer<ProfileViewModel>(
                      builder: (context, profileVM, child) {
                        final profile = profileVM.currentProfile;

                        if (profile == null) {
                          return const SizedBox.shrink();
                        }

                        return Container(
                          padding: const EdgeInsets.all(AppTheme.spacing16),
                          decoration: BoxDecoration(
                            color: AppTheme.infoLight,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: AppTheme.infoColor,
                              ),
                              const SizedBox(width: AppTheme.spacing12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Scanning for:',
                                      style: AppTheme.labelSmall.copyWith(
                                        color: AppTheme.infoColor,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spacing4),
                                    Text(
                                      profile.name,
                                      style: AppTheme.titleMedium.copyWith(
                                        color: AppTheme.infoColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => const ProfileSwitcherSheet(),
                                  );
                                },
                                child: const Text('Change'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppTheme.spacing40),

                    // Title
                    Text(
                      'Choose scan method',
                      style: AppTheme.headingMedium,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppTheme.spacing8),

                    Text(
                      'Select how you\'d like to upload your report',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppTheme.spacing40),

                    // Scan options
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildScanOption(
                            icon: Icons.camera_alt,
                            label: 'Take Photo',
                            description: 'Capture report with camera',
                            onTap: _handleCamera,
                          ),
                          const SizedBox(height: AppTheme.spacing16),
                          _buildScanOption(
                            icon: Icons.photo_library,
                            label: 'Photos / Gallery',
                            description: 'Select single or multiple photos',
                            onTap: _handleGallery,
                          ),
                          const SizedBox(height: AppTheme.spacing16),
                          _buildScanOption(
                            icon: Icons.picture_as_pdf,
                            label: 'Single PDF',
                            description: 'Select a single PDF document',
                            onTap: () => _handlePdf(allowMultiple: false),
                          ),
                          const SizedBox(height: AppTheme.spacing24),
                          // Batch upload option with highlight
                          _buildBatchOption(
                            icon: Icons.upload_file,
                            label: 'Multiple PDFs / Batch',
                            description: 'Process multiple reports at once',
                            badge: 'BATCH',
                            onTap: _handleBatchUpload,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildScanOption({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: context.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: context.primaryColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      description,
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatchOption({
    required IconData icon,
    required String label,
    required String description,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      color: context.primaryContainer.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: context.primaryColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: context.primaryColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: context.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            label,
                            style: AppTheme.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        description,
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: context.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
