import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/blood_report.dart';
import '../models/parameter.dart';
import '../services/database_helper.dart';
import '../services/gemini_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

/// ViewModel for managing blood reports
/// Handles scanning, extraction, and CRUD operations
class ReportViewModel extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final GeminiService _geminiService = GeminiService();
  final ImagePicker _imagePicker = ImagePicker();

  List<BloodReport> _reports = [];
  BloodReport? _selectedReport;
  bool _isLoading = false;
  bool _isScanning = false;
  String? _error;
  double? _scanProgress;

  // Getters
  List<BloodReport> get reports => _reports;
  BloodReport? get selectedReport => _selectedReport;
  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  String? get error => _error;
  double? get scanProgress => _scanProgress;
  bool get hasReports => _reports.isNotEmpty;

  /// Load all reports for a specific profile
  Future<void> loadReportsForProfile(int profileId) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('📊 Loading reports for profile $profileId...');
      // Use DatabaseHelper method which loads parameters too
      _reports = await _databaseHelper.getReportsByProfile(profileId);
      debugPrint('✅ Loaded ${_reports.length} reports');
      for (var report in _reports) {
        debugPrint(
            '  Report ID: ${report.id}, Date: ${report.testDate}, Parameters: ${report.parameters.length}');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading reports: $e');
      _setError('Failed to load reports: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Load all reports (for dashboard)
  Future<void> loadAllReports() async {
    _setLoading(true);
    _clearError();

    try {
      // Use DatabaseHelper method which loads parameters too
      _reports = await _databaseHelper.getAllReports();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load reports: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Scan report from camera
  Future<bool> scanFromCamera(int profileId) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo == null) {
        return false; // User cancelled
      }

      return await _processImage(File(photo.path), profileId);
    } catch (e) {
      _setError('Failed to capture image: ${e.toString()}');
      return false;
    }
  }

  /// Scan report from gallery
  Future<bool> scanFromGallery(int profileId) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) {
        return false; // User cancelled
      }

      return await _processImage(File(image.path), profileId);
    } catch (e) {
      _setError('Failed to pick image: ${e.toString()}');
      return false;
    }
  }

  /// Scan report from PDF file
  Future<bool> scanFromPDF(int profileId) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return false; // User cancelled
      }

      if (result.files.length == 1) {
        final file = File(result.files.first.path!);
        return await _processPDF(file, profileId);
      } else {
        final files = result.paths.map((path) => File(path!)).toList();
        return await _processPdfList(files, profileId);
      }
    } catch (e) {
      _setError('Failed to pick PDF: ${e.toString()}');
      return false;
    }
  }

  /// Process image file with Gemini AI
  Future<bool> _processImage(File imageFile, int profileId) async {
    _setScanning(true);
    _setScanProgress(0.0);
    _clearError();

    try {
      // Step 1: Initialize (10%)
      _setScanProgress(0.1);
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 2: Extract data using Gemini AI (70%)
      _setScanProgress(0.3);

      try {
        final extractedData = await _geminiService.extractBloodReportData(
          imageFile,
        );

        _setScanProgress(0.7);

        // Step 3: Save to database (90%)
        final success = await _saveExtractedData(
          extractedData,
          profileId,
          imageFile.path,
        );

        _setScanProgress(1.0);

        if (success) {
          await loadReportsForProfile(profileId);
        }

        return success;
      } on FormatException catch (_) {
        _setError(
            'The AI response was incomplete. This can happen with complex reports. Try taking a clearer photo or try a different section of the report.');
        return false;
      } catch (e) {
        _setError('Error extracting data: ${e.toString()}');
        return false;
      }
    } catch (e) {
      _setError('Error processing image: ${e.toString()}');
      return false;
    } finally {
      _setScanning(false);
      _setScanProgress(null);
    }
  }

  /// Process PDF file with Gemini AI
  Future<bool> _processPDF(File pdfFile, int profileId) async {
    _setScanning(true);
    _setScanProgress(0.0);
    _clearError();

    try {
      // Step 1: Initialize (10%)
      _setScanProgress(0.1);
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 2: Extract data using Gemini AI (70%)
      _setScanProgress(0.3);

      try {
        final extractedData = await _geminiService.extractBloodReportData(
          pdfFile,
        );

        _setScanProgress(0.7);

        // Step 3: Save to database (90%)
        final success = await _saveExtractedData(
          extractedData,
          profileId,
          pdfFile.path,
        );

        _setScanProgress(1.0);

        if (success) {
          await loadReportsForProfile(profileId);
        }

        return success;
      } on FormatException catch (_) {
        _setError(
            'The AI response was incomplete. Please try again with a clearer PDF or image instead.');
        return false;
      } catch (e) {
        _setError('Error extracting data: ${e.toString()}');
        return false;
      }
    } catch (e) {
      _setError('Error processing PDF: ${e.toString()}');
      return false;
    } finally {
      _setScanning(false);
      _setScanProgress(null);
    }
  }

  /// Process a list of PDF files in parallel
  Future<bool> _processPdfList(List<File> pdfFiles, int profileId) async {
    _setScanning(true);
    _clearError();
    _setScanProgress(0.0);

    try {
      final totalFiles = pdfFiles.length;
      int processedCount = 0;

      final processingFutures = pdfFiles.map((file) {
        return _processSinglePdf(file, profileId).then((success) {
          processedCount++;
          _setScanProgress(processedCount / totalFiles);
          return success;
        });
      }).toList();

      final results = await Future.wait(processingFutures);
      final successfulCount = results.where((success) => success).length;

      if (successfulCount > 0) {
        await loadReportsForProfile(profileId);
      }

      return successfulCount == totalFiles;
    } catch (e) {
      _setError('An error occurred during batch processing: ${e.toString()}');
      return false;
    } finally {
      _setScanning(false);
      _setScanProgress(null);
    }
  }

  /// Process a single PDF file and save its data
  Future<bool> _processSinglePdf(File pdfFile, int profileId) async {
    try {
      final extractedData = await _geminiService.extractBloodReportData(pdfFile);
      return await _saveExtractedData(extractedData, profileId, pdfFile.path);
    } catch (e) {
      debugPrint('Failed to process ${pdfFile.path}: $e');
      return false;
    }
  }

  /// Save extracted data to database
  Future<bool> _saveExtractedData(
    Map<String, dynamic> data,
    int profileId,
    String filePath,
  ) async {
    try {
      final db = await _databaseHelper.database;

      // Parse report date (handle both 'test_date' and 'reportDate')
      DateTime reportDate;
      try {
        final dateStr = data['test_date'] ?? data['reportDate'];
        if (dateStr != null) {
          reportDate = DateTime.parse(dateStr);
        } else {
          reportDate = DateTime.now();
        }
      } catch (e) {
        reportDate = DateTime.now(); // Fallback to current date
      }

      // Create blood report (handle both 'lab_name' and 'labName')
      final report = BloodReport(
        profileId: profileId,
        testDate: reportDate,
        labName: data['lab_name'] ?? data['labName'] ?? 'Unknown Lab',
        reportImagePath: filePath,
        createdAt: DateTime.now(),
      );

      // Insert report
      final reportId = await db.insert('reports', report.toMap());

      // Insert blood parameters
      // Handle both Map and List formats
      final parametersData = data['parameters'];

      if (parametersData != null) {
        // If parameters is a Map (new format from Gemini)
        if (parametersData is Map<String, dynamic>) {
          for (var entry in parametersData.entries) {
            final paramName = entry.key;
            final paramData = entry.value as Map<String, dynamic>;

            try {
              // Skip parameters with null values
              if (paramData['value'] == null) continue;

              final parameter = Parameter(
                reportId: reportId,
                parameterName: paramName,
                parameterValue: (paramData['value'] as num).toDouble(),
                unit: paramData['unit'] ?? '',
                referenceRangeMin: paramData['ref_min'] != null
                    ? (paramData['ref_min'] as num).toDouble()
                    : null,
                referenceRangeMax: paramData['ref_max'] != null
                    ? (paramData['ref_max'] as num).toDouble()
                    : null,
                rawParameterName: paramData['raw_name'] ?? paramName,
              );

              await db.insert('blood_parameters', parameter.toMap());
            } catch (e) {
              // Skip parameters that fail to parse
              debugPrint('❌ Error parsing parameter $paramName: $e');
            }
          }
        }
        // If parameters is a List (legacy format)
        else if (parametersData is List<dynamic>) {
          for (var param in parametersData) {
            try {
              final parameter = Parameter(
                reportId: reportId,
                parameterName: param['normalizedName'] ?? param['name'],
                parameterValue: (param['value'] as num).toDouble(),
                unit: param['unit'],
                referenceRangeMin: param['referenceMin'] != null
                    ? (param['referenceMin'] as num).toDouble()
                    : null,
                referenceRangeMax: param['referenceMax'] != null
                    ? (param['referenceMax'] as num).toDouble()
                    : null,
                rawParameterName: param['name'],
              );

              await db.insert('blood_parameters', parameter.toMap());
            } catch (e) {
              // Skip parameters that fail to parse
              debugPrint('❌ Error parsing parameter: $e');
            }
          }
        }
      }

      debugPrint('✅ Report saved successfully with ID: $reportId');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving extracted data: $e');
      _setError('Failed to save report: ${e.toString()}');
      return false;
    }
  }

  /// Delete a report and its parameters
  Future<bool> deleteReport(int reportId) async {
    _setLoading(true);
    _clearError();

    try {
      final db = await _databaseHelper.database;

      // Delete parameters first
      await db.delete(
        'blood_parameters',
        where: 'report_id = ?',
        whereArgs: [reportId],
      );

      // Delete report
      await db.delete(
        'reports',
        where: 'id = ?',
        whereArgs: [reportId],
      );

      _reports.removeWhere((r) => r.id == reportId);

      if (_selectedReport?.id == reportId) {
        _selectedReport = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete report: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get parameters for a specific report
  Future<List<Parameter>> getParametersForReport(int reportId) async {
    try {
      return await _databaseHelper.getParametersByReport(reportId);
    } catch (e) {
      return [];
    }
  }

  /// Get report statistics for a profile
  Future<ReportStatistics> getReportStatistics(int profileId) async {
    try {
      final db = await _databaseHelper.database;

      // Count total reports
      final reportCountResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM reports WHERE profile_id = ?',
        [profileId],
      );
      final totalReports = reportCountResult.first['count'] as int? ?? 0;

      // Count abnormal parameters (parameters outside their reference ranges)
      final abnormalCountResult = await db.rawQuery(
        '''
        SELECT COUNT(*) as count 
        FROM blood_parameters bp
        INNER JOIN reports r ON bp.report_id = r.id
        WHERE r.profile_id = ? 
          AND bp.reference_range_min IS NOT NULL 
          AND bp.reference_range_max IS NOT NULL
          AND (bp.parameter_value < bp.reference_range_min 
               OR bp.parameter_value > bp.reference_range_max)
        ''',
        [profileId],
      );
      final abnormalCount = abnormalCountResult.first['count'] as int? ?? 0;

      // Get date range
      final dateRangeResult = await db.rawQuery(
        '''
        SELECT MIN(test_date) as first, MAX(test_date) as last
        FROM reports
        WHERE profile_id = ?
        ''',
        [profileId],
      );

      DateTime? firstReportDate;
      DateTime? lastReportDate;

      if (dateRangeResult.isNotEmpty) {
        final first = dateRangeResult.first['first'];
        final last = dateRangeResult.first['last'];

        if (first != null) firstReportDate = DateTime.parse(first as String);
        if (last != null) lastReportDate = DateTime.parse(last as String);
      }

      return ReportStatistics(
        totalReports: totalReports,
        abnormalParameters: abnormalCount,
        firstReportDate: firstReportDate,
        lastReportDate: lastReportDate,
      );
    } catch (e) {
      return ReportStatistics(
        totalReports: 0,
        abnormalParameters: 0,
        firstReportDate: null,
        lastReportDate: null,
      );
    }
  }

  /// Select a report for viewing
  void selectReport(BloodReport report) {
    _selectedReport = report;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setScanning(bool value) {
    _isScanning = value;
    notifyListeners();
  }

  void _setScanProgress(double? value) {
    _scanProgress = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}

/// Statistics for reports
class ReportStatistics {
  final int totalReports;
  final int abnormalParameters;
  final DateTime? firstReportDate;
  final DateTime? lastReportDate;

  ReportStatistics({
    required this.totalReports,
    required this.abnormalParameters,
    required this.firstReportDate,
    required this.lastReportDate,
  });
}
