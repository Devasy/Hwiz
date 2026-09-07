import 'dart:math';
import 'package:flutter/foundation.dart';
import 'parameter_alias_resolver.dart';
import 'reference_range_database.dart';

/// Extraction Validator - Validates blood report extraction results
/// Catches common parsing errors and data quality issues
class ExtractionValidator {
  /// Validation result with errors and warnings
  static ValidationResult validate(Map<String, dynamic> extractedData) {
    final List<String> errors = [];
    final List<String> warnings = [];
    final List<String> suggestions = [];

    // 1. Validate basic structure
    _validateStructure(extractedData, errors);

    if (errors.isNotEmpty) {
      return ValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
        suggestions: suggestions,
      );
    }

    final parameters =
        extractedData['parameters'] as Map<String, dynamic>? ?? {};

    // 2. Check for duplicate parameters
    _checkDuplicates(parameters, warnings);

    // 3. Check for missing critical reference ranges
    _checkMissingRanges(parameters, warnings, suggestions);

    // 4. Validate parameter values (detect obviously wrong values)
    _validateParameterValues(parameters, errors, warnings);

    // 5. Check for incorrect reference ranges
    _validateReferenceRanges(parameters, errors, warnings);

    // 6. Check for unit inconsistencies
    _checkUnitConsistency(parameters, warnings);

    // 7. Validate date format
    _validateDate(extractedData, errors);

    // 8. Check for empty or suspicious lab name
    _validateLabName(extractedData, warnings);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      suggestions: suggestions,
    );
  }

  /// Validate basic JSON structure
  static void _validateStructure(
    Map<String, dynamic> data,
    List<String> errors,
  ) {
    if (!data.containsKey('parameters')) {
      errors.add('Missing "parameters" field in extracted data');
    }

    if (data['parameters'] is! Map) {
      errors.add('"parameters" must be a Map object');
    }

    final params = data['parameters'] as Map?;
    if (params == null || params.isEmpty) {
      errors.add('No parameters extracted from the report');
    }
  }

  /// Check for duplicate parameters
  static void _checkDuplicates(
    Map<String, dynamic> parameters,
    List<String> warnings,
  ) {
    final Map<String, List<String>> canonicalGroups = {};

    for (var key in parameters.keys) {
      final canonical = ParameterAliasResolver.resolveToCanonical(key);

      if (!canonicalGroups.containsKey(canonical)) {
        canonicalGroups[canonical] = [];
      }
      canonicalGroups[canonical]!.add(key);
    }

    // Report duplicates
    for (var entry in canonicalGroups.entries) {
      if (entry.value.length > 1) {
        warnings.add(
          'Found duplicate parameter: ${entry.key} appears as ${entry.value.join(', ')}',
        );
      }
    }
  }

  /// Check for missing reference ranges on critical parameters
  static void _checkMissingRanges(
    Map<String, dynamic> parameters,
    List<String> warnings,
    List<String> suggestions,
  ) {
    final criticalParameters = [
      'hemoglobin',
      'wbc_count',
      'rbc_count',
      'platelet_count',
      'fasting_blood_sugar',
      'hba1c',
      'serum_creatinine',
      'neutrophil_percentage',
      'lymphocyte_percentage',
    ];

    final missingRanges = <String>[];

    for (var key in parameters.keys) {
      final canonical = ParameterAliasResolver.resolveToCanonical(key);
      final param = parameters[key];

      if (param is Map &&
          criticalParameters.contains(canonical) &&
          (param['ref_min'] == null || param['ref_max'] == null)) {
        missingRanges.add(canonical);

        // Check if we have it in our database
        if (ReferenceRangeDatabase.hasRange(canonical)) {
          suggestions.add(
            'Reference range for $canonical can be filled from medical database',
          );
        }
      }
    }

    if (missingRanges.isNotEmpty) {
      warnings.add(
        'Missing reference ranges for critical parameters: ${missingRanges.join(', ')}',
      );
    }
  }

  /// Validate parameter values are within reasonable medical ranges
  static void _validateParameterValues(
    Map<String, dynamic> parameters,
    List<String> errors,
    List<String> warnings,
  ) {
    // Define reasonable ranges for common parameters (to catch OCR errors)
    final Map<String, Map<String, double>> reasonableRanges = {
      'hemoglobin': {'min': 0.0, 'max': 25.0}, // g/dL
      'wbc_count': {'min': 0.0, 'max': 500000.0}, // cells/μL
      'rbc_count': {'min': 0.0, 'max': 10.0}, // million cells/μL
      'platelet_count': {'min': 0.0, 'max': 2000000.0}, // cells/μL
      'fasting_blood_sugar': {'min': 0.0, 'max': 600.0}, // mg/dL
      'hba1c': {'min': 0.0, 'max': 20.0}, // %
      'serum_cholesterol': {'min': 0.0, 'max': 500.0}, // mg/dL
      'serum_triglycerides': {'min': 0.0, 'max': 2000.0}, // mg/dL
      'neutrophil_percentage': {'min': 0.0, 'max': 100.0}, // %
      'lymphocyte_percentage': {'min': 0.0, 'max': 100.0}, // %
      'monocyte_percentage': {'min': 0.0, 'max': 100.0}, // %
      'eosinophil_percentage': {'min': 0.0, 'max': 100.0}, // %
      'basophil_percentage': {'min': 0.0, 'max': 100.0}, // %
    };

    for (var key in parameters.keys) {
      final canonical = ParameterAliasResolver.resolveToCanonical(key);
      final param = parameters[key];

      if (param is Map && param['value'] is num) {
        final value = (param['value'] as num).toDouble();
        final range = reasonableRanges[canonical];

        if (range != null) {
          if (value < range['min']! || value > range['max']!) {
            errors.add(
              'Suspicious value for $canonical: $value ${param['unit'] ?? ''} (expected range: ${range['min']}-${range['max']})',
            );
          }
        }

        // Check for obviously wrong zero values
        if (value == 0.0 &&
            ['hemoglobin', 'wbc_count', 'rbc_count'].contains(canonical)) {
          errors.add(
            'Invalid zero value for critical parameter: $canonical',
          );
        }
      }
    }
  }

  /// Validate reference ranges are reasonable
  static void _validateReferenceRanges(
    Map<String, dynamic> parameters,
    List<String> errors,
    List<String> warnings,
  ) {
    for (var key in parameters.keys) {
      final canonical = ParameterAliasResolver.resolveToCanonical(key);
      final param = parameters[key];

      if (param is Map) {
        final refMin = param['ref_min'];
        final refMax = param['ref_max'];

        if (refMin != null && refMax != null) {
          final refMinNum = refMin as num;
          final refMaxNum = refMax as num;

          // Allow 0-0 range for certain cell types that can be absent
          final allowZeroRange = [
            'blast_cells_percentage',
            'pro_myelocyte_percentage',
            'myelocyte_percentage',
            'meta_myelocyte_percentage',
            'band_cells_percentage',
            'basophil_percentage',
          ].contains(canonical);

          // Check if min > max (definitely wrong)
          // Or min == max (unless both are 0 and it's an allowed parameter)
          if (refMinNum > refMaxNum ||
              (refMinNum == refMaxNum && !(allowZeroRange && refMinNum == 0))) {
            errors.add(
              'Invalid reference range for $canonical: min ($refMin) >= max ($refMax)',
            );
          }

          // Check against known ranges
          final dbRange =
              ReferenceRangeDatabase.getRangeForGender(canonical, null);
          final refMinD = refMinNum.toDouble();
          final refMaxD = refMaxNum.toDouble();

          if (dbRange['min'] != null && dbRange['max'] != null) {
            final dbMin = dbRange['min']!;
            final dbMax = dbRange['max']!;

            // If extracted range differs significantly from database, warn
            if ((refMinD - dbMin).abs() / dbMin > 0.5 ||
                (refMaxD - dbMax).abs() / dbMax > 0.5) {
              warnings.add(
                'Reference range for $canonical ($refMinD-$refMaxD) differs significantly from standard range ($dbMin-$dbMax)',
              );
            }
          }

          // Special case: Check for platelet count error (seen in dataset)
          if (canonical == 'platelet_count') {
            // Platelet ref range should be in thousands
            if (refMinD < 100 || refMaxD < 100) {
              errors.add(
                'Incorrect reference range for platelet_count: $refMin-$refMax. Expected range like 150000-450000',
              );
            }
          }
        }
      }
    }
  }

  /// Check for unit inconsistencies
  static void _checkUnitConsistency(
    Map<String, dynamic> parameters,
    List<String> warnings,
  ) {
    // Expected units for common parameters
    final Map<String, List<String>> expectedUnits = {
      'hemoglobin': ['g/dL', 'g/dl', 'gm%', 'Gms%'],
      'wbc_count': ['cells/μL', '/μL', '/cmm', '/c.mm', '10^9/L', '10^3/uL'],
      'platelet_count': ['cells/μL', '/μL', '/cmm', '10^9/L', '10^3/uL'],
      'fasting_blood_sugar': ['mg/dL', 'mg/dl'],
      'hba1c': ['%'],
      'serum_cholesterol': ['mg/dL', 'mg/dl', 'mg%'],
      'serum_triglycerides': ['mg/dL', 'mg/dl', 'mg%'],
    };

    for (var key in parameters.keys) {
      final canonical = ParameterAliasResolver.resolveToCanonical(key);
      final param = parameters[key];

      if (param is Map && param['unit'] != null) {
        final unit = param['unit'].toString().trim();
        final expected = expectedUnits[canonical];

        if (expected != null && unit.isNotEmpty) {
          // Normalize unit for comparison
          final normalizedUnit = unit.toLowerCase().replaceAll(' ', '');
          final normalizedExpected =
              expected.map((u) => u.toLowerCase().replaceAll(' ', '')).toList();

          if (!normalizedExpected.any((u) =>
              normalizedUnit.contains(u) || u.contains(normalizedUnit))) {
            warnings.add(
              'Unexpected unit for $canonical: "$unit" (expected one of: ${expected.join(', ')})',
            );
          }
        }
      }
    }
  }

  /// Validate date format
  static void _validateDate(Map<String, dynamic> data, List<String> errors) {
    final testDate = data['test_date'];

    if (testDate == null || testDate.toString().isEmpty) {
      errors.add('Missing test date');
      return;
    }

    // Try to parse the date
    try {
      final date = DateTime.parse(testDate.toString());

      // Check if date is in reasonable range (not too old, not in future)
      final now = DateTime.now();
      final hundredYearsAgo = now.subtract(const Duration(days: 365 * 100));

      if (date.isAfter(now)) {
        errors.add('Test date is in the future: $testDate');
      } else if (date.isBefore(hundredYearsAgo)) {
        errors.add('Test date is too old: $testDate');
      }
    } catch (e) {
      errors.add('Invalid date format: $testDate (expected YYYY-MM-DD)');
    }
  }

  /// Validate lab name
  static void _validateLabName(
      Map<String, dynamic> data, List<String> warnings) {
    final labName = data['lab_name'];

    if (labName == null || labName.toString().trim().isEmpty) {
      warnings.add('Lab name not extracted');
    } else if (labName.toString().toLowerCase().contains('unknown')) {
      warnings.add('Lab name could not be determined');
    }
  }

  /// Calculate confidence score for extraction (0-100)
  static int calculateConfidenceScore(Map<String, dynamic> extractedData) {
    int score = 100;

    final result = validate(extractedData);

    // Deduct points for errors (major issues)
    score -= result.errors.length * 15;

    // Deduct points for warnings (minor issues)
    score -= result.warnings.length * 5;

    final parameters = extractedData['parameters'] as Map? ?? {};

    // Bonus for having reference ranges
    int paramsWithRanges = 0;
    for (var param in parameters.values) {
      if (param is Map &&
          param['ref_min'] != null &&
          param['ref_max'] != null) {
        paramsWithRanges++;
      }
    }

    if (parameters.isNotEmpty) {
      final rangePercentage = paramsWithRanges / parameters.length;
      score += (rangePercentage * 10).toInt();
    }

    // Bonus for having lab name
    if (extractedData['lab_name'] != null &&
        !extractedData['lab_name'].toString().contains('Unknown')) {
      score += 5;
    }

    // Bonus for having valid date
    try {
      DateTime.parse(extractedData['test_date'].toString());
      score += 5;
    } catch (e) {
      // Date invalid, no bonus
    }

    return max(0, min(100, score));
  }
}

/// Validation result class
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final List<String> suggestions;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.suggestions,
  });

  bool get hasIssues => errors.isNotEmpty || warnings.isNotEmpty;

  String get summary {
    if (isValid && !hasIssues) {
      return 'Extraction successful with no issues';
    }

    final parts = <String>[];
    if (errors.isNotEmpty) {
      parts.add('${errors.length} error(s)');
    }
    if (warnings.isNotEmpty) {
      parts.add('${warnings.length} warning(s)');
    }

    return parts.join(', ');
  }

  void printReport() {
    debugPrint('=== Extraction Validation Report ===');
    debugPrint('Status: ${isValid ? "VALID" : "INVALID"}');

    if (errors.isNotEmpty) {
      debugPrint('\n❌ ERRORS:');
      for (var error in errors) {
        debugPrint('  - $error');
      }
    }

    if (warnings.isNotEmpty) {
      debugPrint('\n⚠️  WARNINGS:');
      for (var warning in warnings) {
        debugPrint('  - $warning');
      }
    }

    if (suggestions.isNotEmpty) {
      debugPrint('\n💡 SUGGESTIONS:');
      for (var suggestion in suggestions) {
        debugPrint('  - $suggestion');
      }
    }

    debugPrint('===================================\n');
  }
}
