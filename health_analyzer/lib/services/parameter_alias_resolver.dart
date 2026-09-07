import '../models/parameter.dart';
import 'loinc_mapper.dart';
import 'reference_range_database.dart';

/// Parameter Alias Resolver - Handles duplicate parameters and aliases
/// Merges parameters from multi-page reports and resolves naming conflicts
class ParameterAliasResolver {
  /// Resolve parameter name to canonical form
  /// Handles _page2 suffixes, _percentage variations, etc.
  static String resolveToCanonical(String parameterName) {
    // First normalize using LOINC mapper
    String normalized = LOINCMapper.normalize(parameterName);

    // Remove common suffixes that indicate duplicates
    normalized = normalized
        .replaceAll('_page2', '')
        .replaceAll('_page_2', '')
        .replaceAll(' page2', '')
        .replaceAll(' page 2', '');

    // Normalize again after suffix removal
    normalized = LOINCMapper.normalize(normalized);

    return normalized;
  }

  /// Merge duplicate parameters from the same report
  /// Prioritizes values with reference ranges and higher confidence
  static List<Parameter> mergeDuplicates(List<Parameter> parameters) {
    if (parameters.isEmpty) return [];

    // Group parameters by canonical name
    final Map<String, List<Parameter>> grouped = {};

    for (var param in parameters) {
      final canonical = resolveToCanonical(param.parameterName);
      if (!grouped.containsKey(canonical)) {
        grouped[canonical] = [];
      }
      grouped[canonical]!.add(param);
    }

    // Merge each group
    final List<Parameter> merged = [];

    for (var entry in grouped.entries) {
      final canonicalName = entry.key;
      final duplicates = entry.value;

      if (duplicates.length == 1) {
        // No duplicates, use as-is with canonical name
        merged.add(Parameter(
          id: duplicates[0].id,
          reportId: duplicates[0].reportId,
          parameterName: canonicalName,
          parameterValue: duplicates[0].parameterValue,
          unit: duplicates[0].unit,
          referenceRangeMin: duplicates[0].referenceRangeMin,
          referenceRangeMax: duplicates[0].referenceRangeMax,
          rawParameterName: duplicates[0].rawParameterName,
        ));
      } else {
        // Multiple duplicates - merge intelligently
        final mergedParam = _mergeDuplicateParameters(
          canonicalName,
          duplicates,
        );
        merged.add(mergedParam);
      }
    }

    return merged;
  }

  /// Merge multiple parameter instances into one
  static Parameter _mergeDuplicateParameters(
    String canonicalName,
    List<Parameter> duplicates,
  ) {
    // Sort by priority:
    // 1. Parameters with reference ranges
    // 2. Parameters with original (non-page2) names
    // 3. Higher parameter values (in case of different readings)

    duplicates.sort((a, b) {
      // Priority 1: Has reference ranges
      final aHasRanges =
          (a.referenceRangeMin != null && a.referenceRangeMax != null);
      final bHasRanges =
          (b.referenceRangeMin != null && b.referenceRangeMax != null);

      if (aHasRanges && !bHasRanges) return -1;
      if (!aHasRanges && bHasRanges) return 1;

      // Priority 2: Original name (no _page2)
      final aIsOriginal = !a.parameterName.contains('page2');
      final bIsOriginal = !b.parameterName.contains('page2');

      if (aIsOriginal && !bIsOriginal) return -1;
      if (!aIsOriginal && bIsOriginal) return 1;

      // Priority 3: Non-zero values preferred
      if (a.parameterValue != 0 && b.parameterValue == 0) return -1;
      if (a.parameterValue == 0 && b.parameterValue != 0) return 1;

      return 0;
    });

    final best = duplicates.first;

    // Use the best parameter but try to fill in missing ranges from others
    double? finalMin = best.referenceRangeMin;
    double? finalMax = best.referenceRangeMax;

    // If best doesn't have ranges, try to get from others
    if (finalMin == null || finalMax == null) {
      for (var dup in duplicates) {
        if (dup.referenceRangeMin != null && dup.referenceRangeMax != null) {
          finalMin ??= dup.referenceRangeMin;
          finalMax ??= dup.referenceRangeMax;
          break;
        }
      }
    }

    // If still no ranges, try to get from reference database
    if (finalMin == null || finalMax == null) {
      final rangeData = ReferenceRangeDatabase.getRangeForGender(
        canonicalName,
        null,
      );
      finalMin ??= rangeData['min'];
      finalMax ??= rangeData['max'];
    }

    // Calculate average value if values are close (within 10%)
    double finalValue = best.parameterValue;
    if (duplicates.length > 1) {
      final values = duplicates.map((p) => p.parameterValue).toList();
      final minValue = values.reduce((a, b) => a < b ? a : b);
      final maxValue = values.reduce((a, b) => a > b ? a : b);

      // If values are within 10% of each other, use average
      if (minValue > 0 && (maxValue - minValue) / minValue < 0.1) {
        finalValue = values.reduce((a, b) => a + b) / values.length;
      }
    }

    return Parameter(
      id: best.id,
      reportId: best.reportId,
      parameterName: canonicalName,
      parameterValue: finalValue,
      unit: best.unit,
      referenceRangeMin: finalMin,
      referenceRangeMax: finalMax,
      rawParameterName: best.rawParameterName,
    );
  }

  /// Detect potential duplicate parameters in a report
  /// Returns groups of parameters that might be duplicates
  static Map<String, List<String>> detectDuplicates(
      List<Parameter> parameters) {
    final Map<String, List<String>> duplicateGroups = {};

    for (var param in parameters) {
      final canonical = resolveToCanonical(param.parameterName);

      if (!duplicateGroups.containsKey(canonical)) {
        duplicateGroups[canonical] = [];
      }
      duplicateGroups[canonical]!.add(param.parameterName);
    }

    // Filter to only groups with actual duplicates
    duplicateGroups.removeWhere((key, value) => value.length <= 1);

    return duplicateGroups;
  }

  /// Fix common parameter naming issues
  static String fixCommonIssues(String parameterName) {
    String fixed = parameterName;

    // Fix typos
    fixed = fixed.replaceAll('chole_hdl', 'chol_hdl'); // Common typo
    fixed = fixed.replaceAll('triglyceride_', 'triglycerides_');

    // Standardize separators
    fixed = fixed.replaceAll('-', '_');
    fixed = fixed.replaceAll(' ', '_');

    // Remove multiple underscores
    fixed = fixed.replaceAll(RegExp(r'_{2,}'), '_');

    // Trim underscores from ends
    fixed = fixed.replaceAll(RegExp(r'^_+|_+$'), '');

    return fixed;
  }

  /// Check if two parameter names are likely aliases of each other
  static bool areAliases(String name1, String name2) {
    final canonical1 = resolveToCanonical(name1);
    final canonical2 = resolveToCanonical(name2);

    return canonical1 == canonical2;
  }

  /// Get all known aliases for a parameter
  static List<String> getAliases(String parameterName) {
    final canonical = resolveToCanonical(parameterName);

    // Get variations from LOINC mapper
    final aliases = LOINCMapper.getVariations(canonical);

    // Add page variations
    final pageVariations = [
      '${canonical}_page2',
      '${canonical}_page_2',
      '$canonical page2',
      '$canonical page 2',
    ];

    // Add percentage variations
    final percentageVariations = [
      '${canonical}_percentage',
      '${canonical}_percent',
      '${canonical}_%',
      canonical.replaceAll('_percentage', ''),
      canonical.replaceAll('_percent', ''),
    ];

    return <String>{
      ...aliases,
      ...pageVariations,
      ...percentageVariations,
    }.toList();
  }

  /// Validate that merged parameters don't have contradictory values
  static List<String> validateMerge(
      Parameter merged, List<Parameter> originals) {
    final List<String> warnings = [];

    // Check if values vary significantly
    final values = originals.map((p) => p.parameterValue).toList();
    if (values.isNotEmpty) {
      final minValue = values.reduce((a, b) => a < b ? a : b);
      final maxValue = values.reduce((a, b) => a > b ? a : b);

      if (minValue > 0 && (maxValue - minValue) / minValue > 0.2) {
        warnings.add(
          'Values vary by more than 20%: ${values.join(', ')} for ${merged.parameterName}',
        );
      }
    }

    // Check if units differ
    final units = originals.map((p) => p.unit).toSet().toList();
    if (units.length > 1) {
      warnings.add(
        'Different units found for ${merged.parameterName}: ${units.join(', ')}',
      );
    }

    // Check if reference ranges differ significantly
    final rangesMin = originals
        .where((p) => p.referenceRangeMin != null)
        .map((p) => p.referenceRangeMin!)
        .toList();

    if (rangesMin.length > 1) {
      final minRange = rangesMin.reduce((a, b) => a < b ? a : b);
      final maxRange = rangesMin.reduce((a, b) => a > b ? a : b);

      if (minRange > 0 && (maxRange - minRange) / minRange > 0.1) {
        warnings.add(
          'Reference ranges differ for ${merged.parameterName}',
        );
      }
    }

    return warnings;
  }

  /// Get canonical name with reference range from database if available
  static Map<String, dynamic> getCanonicalWithRanges(
    String parameterName,
    double value,
    String? unit, {
    double? existingMin,
    double? existingMax,
    String? gender,
  }) {
    final canonical = resolveToCanonical(parameterName);

    // Try to get ranges from database if not provided
    double? finalMin = existingMin;
    double? finalMax = existingMax;

    if (finalMin == null || finalMax == null) {
      final rangeData = ReferenceRangeDatabase.getRangeForGender(
        canonical,
        gender,
      );
      finalMin ??= rangeData['min'];
      finalMax ??= rangeData['max'];
    }

    // Get standard unit from database
    final standardRange = ReferenceRangeDatabase.getRange(canonical);
    final standardUnit = standardRange?.unit ?? unit;

    return {
      'canonical_name': canonical,
      'value': value,
      'unit': standardUnit ?? unit,
      'reference_min': finalMin,
      'reference_max': finalMax,
      'has_database_ranges': ReferenceRangeDatabase.hasRange(canonical),
    };
  }
}
