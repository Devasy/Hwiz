/// Reference Range Database - Provides standard reference ranges for blood parameters
/// Based on clinical standards and real-world lab report analysis
/// Supports age and gender-specific ranges
library;

class ReferenceRange {
  final double? minMale;
  final double? maxMale;
  final double? minFemale;
  final double? maxFemale;
  final double? minGeneral;
  final double? maxGeneral;
  final String unit;
  final bool isAgeDependent;
  final bool isGenderDependent;
  final Map<String, double>? ageRanges; // Age-specific adjustments
  final Map<String, double>? criticalLevels; // Pre-diabetic, diabetic, etc.

  const ReferenceRange({
    this.minMale,
    this.maxMale,
    this.minFemale,
    this.maxFemale,
    this.minGeneral,
    this.maxGeneral,
    required this.unit,
    this.isAgeDependent = false,
    this.isGenderDependent = false,
    this.ageRanges,
    this.criticalLevels,
  });

  /// Get min range for specific gender
  double? getMin({String? gender}) {
    if (!isGenderDependent || gender == null) return minGeneral;
    if (gender.toLowerCase() == 'male') return minMale;
    if (gender.toLowerCase() == 'female') return minFemale;
    return minGeneral;
  }

  /// Get max range for specific gender
  double? getMax({String? gender}) {
    if (!isGenderDependent || gender == null) return maxGeneral;
    if (gender.toLowerCase() == 'male') return maxMale;
    if (gender.toLowerCase() == 'female') return maxFemale;
    return maxGeneral;
  }

  /// Check if value is in critical range
  String? getCriticalStatus(double value) {
    if (criticalLevels == null) return null;

    for (var entry in criticalLevels!.entries) {
      if (value >= entry.value) {
        return entry.key;
      }
    }
    return null;
  }
}

class ReferenceRangeDatabase {
  // Comprehensive reference range database
  static final Map<String, ReferenceRange> ranges = {
    // ===== COMPLETE BLOOD COUNT (CBC) =====

    'rbc_count': ReferenceRange(
      minMale: 4.5,
      maxMale: 5.9,
      minFemale: 4.0,
      maxFemale: 5.2,
      unit: 'million cells/μL',
      isGenderDependent: true,
    ),

    'wbc_count': const ReferenceRange(
      minGeneral: 4000,
      maxGeneral: 11000,
      unit: 'cells/μL',
    ),

    'hemoglobin': ReferenceRange(
      minMale: 13.5,
      maxMale: 17.5,
      minFemale: 12.0,
      maxFemale: 15.5,
      unit: 'g/dL',
      isGenderDependent: true,
    ),

    'hematocrit': ReferenceRange(
      minMale: 38.3,
      maxMale: 48.6,
      minFemale: 35.5,
      maxFemale: 44.9,
      unit: '%',
      isGenderDependent: true,
    ),

    'platelet_count': const ReferenceRange(
      minGeneral: 150000,
      maxGeneral: 450000,
      unit: 'cells/μL',
    ),

    'mcv': const ReferenceRange(
      minGeneral: 80.0,
      maxGeneral: 100.0,
      unit: 'fL',
    ),

    'mch': const ReferenceRange(
      minGeneral: 27.0,
      maxGeneral: 32.0,
      unit: 'pg',
    ),

    'mchc': const ReferenceRange(
      minGeneral: 32.0,
      maxGeneral: 36.0,
      unit: 'g/dL',
    ),

    'rdw': const ReferenceRange(
      minGeneral: 11.5,
      maxGeneral: 14.5,
      unit: '%',
    ),

    'mpv': const ReferenceRange(
      minGeneral: 7.4,
      maxGeneral: 10.4,
      unit: 'fL',
    ),

    'pdw': const ReferenceRange(
      minGeneral: 10.0,
      maxGeneral: 17.0,
      unit: '%',
    ),

    'plateletcrit': const ReferenceRange(
      minGeneral: 0.1,
      maxGeneral: 0.5,
      unit: '%',
    ),

    'p_lcr': const ReferenceRange(
      minGeneral: 13.0,
      maxGeneral: 43.0,
      unit: '%',
    ),

    // ===== DIFFERENTIAL COUNT =====

    'neutrophil_percentage': const ReferenceRange(
      minGeneral: 40.0,
      maxGeneral: 70.0,
      unit: '%',
    ),

    'lymphocyte_percentage': const ReferenceRange(
      minGeneral: 20.0,
      maxGeneral: 40.0,
      unit: '%',
    ),

    'monocyte_percentage': const ReferenceRange(
      minGeneral: 2.0,
      maxGeneral: 8.0,
      unit: '%',
    ),

    'eosinophil_percentage': const ReferenceRange(
      minGeneral: 1.0,
      maxGeneral: 4.0,
      unit: '%',
    ),

    'basophil_percentage': const ReferenceRange(
      minGeneral: 0.0,
      maxGeneral: 1.0,
      unit: '%',
    ),

    'band_cells_percentage': const ReferenceRange(
      minGeneral: 0.0,
      maxGeneral: 5.0,
      unit: '%',
    ),

    'blast_cells_percentage': const ReferenceRange(
      minGeneral: 0.0,
      maxGeneral: 0.0,
      unit: '%',
    ),

    'myelocyte_percentage': const ReferenceRange(
      minGeneral: 0.0,
      maxGeneral: 0.0,
      unit: '%',
    ),

    'meta_myelocyte_percentage': const ReferenceRange(
      minGeneral: 0.0,
      maxGeneral: 0.0,
      unit: '%',
    ),

    'pro_myelocyte_percentage': const ReferenceRange(
      minGeneral: 0.0,
      maxGeneral: 0.0,
      unit: '%',
    ),

    // ===== BLOOD GLUCOSE =====

    'fasting_blood_sugar': ReferenceRange(
      minGeneral: 70.0,
      maxGeneral: 100.0,
      unit: 'mg/dL',
      criticalLevels: {
        'prediabetic': 100.0,
        'diabetic': 126.0,
      },
    ),

    'post_prandial_blood_sugar': ReferenceRange(
      minGeneral: 70.0,
      maxGeneral: 140.0,
      unit: 'mg/dL',
      criticalLevels: {
        'prediabetic': 140.0,
        'diabetic': 200.0,
      },
    ),

    'random_blood_sugar': ReferenceRange(
      minGeneral: 70.0,
      maxGeneral: 140.0,
      unit: 'mg/dL',
      criticalLevels: {
        'diabetic': 200.0,
      },
    ),

    'hba1c': ReferenceRange(
      minGeneral: 4.0,
      maxGeneral: 5.6,
      unit: '%',
      criticalLevels: {
        'prediabetic': 5.7,
        'diabetic': 6.5,
      },
    ),

    'mean_blood_glucose': const ReferenceRange(
      minGeneral: 68.0,
      maxGeneral: 126.0,
      unit: 'mg/dL',
    ),

    // ===== KIDNEY FUNCTION =====

    'serum_creatinine': ReferenceRange(
      minMale: 0.7,
      maxMale: 1.3,
      minFemale: 0.6,
      maxFemale: 1.1,
      unit: 'mg/dL',
      isGenderDependent: true,
    ),

    'blood_urea_nitrogen': const ReferenceRange(
      minGeneral: 7.0,
      maxGeneral: 20.0,
      unit: 'mg/dL',
    ),

    'uric_acid': ReferenceRange(
      minMale: 3.5,
      maxMale: 7.2,
      minFemale: 2.6,
      maxFemale: 6.0,
      unit: 'mg/dL',
      isGenderDependent: true,
    ),

    // ===== LIPID PROFILE =====

    'serum_cholesterol': ReferenceRange(
      minGeneral: 0.0,
      maxGeneral: 200.0,
      unit: 'mg/dL',
      criticalLevels: {
        'borderline_high': 200.0,
        'high': 240.0,
      },
    ),

    'serum_hdl_cholesterol': ReferenceRange(
      minGeneral: 40.0,
      maxGeneral: 80.0,
      unit: 'mg/dL',
      criticalLevels: {
        'low_risk': 60.0, // Protective against heart disease
      },
    ),

    'serum_ldl_cholesterol': ReferenceRange(
      minGeneral: 0.0,
      maxGeneral: 100.0,
      unit: 'mg/dL',
      criticalLevels: {
        'near_optimal': 100.0,
        'borderline_high': 130.0,
        'high': 160.0,
        'very_high': 190.0,
      },
    ),

    'serum_vldl_cholesterol': const ReferenceRange(
      minGeneral: 2.0,
      maxGeneral: 30.0,
      unit: 'mg/dL',
    ),

    'serum_triglycerides': ReferenceRange(
      minGeneral: 0.0,
      maxGeneral: 150.0,
      unit: 'mg/dL',
      criticalLevels: {
        'borderline_high': 150.0,
        'high': 200.0,
        'very_high': 500.0,
      },
    ),

    'chol_hdl_ratio': ReferenceRange(
      minGeneral: 0.0,
      maxGeneral: 5.0,
      unit: '',
      criticalLevels: {
        'optimal': 3.5,
        'high_risk': 5.0,
      },
    ),

    'ldl_hdl_ratio': ReferenceRange(
      minGeneral: 0.0,
      maxGeneral: 3.5,
      unit: '',
      criticalLevels: {
        'optimal': 2.0,
        'borderline': 3.0,
        'high_risk': 4.0,
      },
    ),

    // ===== LIVER FUNCTION =====

    'sgpt': ReferenceRange(
      minGeneral: 0.0,
      maxGeneral: 40.0,
      unit: 'U/L',
      isGenderDependent: true,
      minMale: 0.0,
      maxMale: 41.0,
      minFemale: 0.0,
      maxFemale: 33.0,
    ),

    'sgot': ReferenceRange(
      minGeneral: 0.0,
      maxGeneral: 40.0,
      unit: 'U/L',
      isGenderDependent: true,
      minMale: 0.0,
      maxMale: 40.0,
      minFemale: 0.0,
      maxFemale: 32.0,
    ),

    'alkaline_phosphatase': const ReferenceRange(
      minGeneral: 44.0,
      maxGeneral: 147.0,
      unit: 'U/L',
      isAgeDependent: true,
    ),

    'total_bilirubin': const ReferenceRange(
      minGeneral: 0.1,
      maxGeneral: 1.2,
      unit: 'mg/dL',
    ),

    'direct_bilirubin': const ReferenceRange(
      minGeneral: 0.0,
      maxGeneral: 0.3,
      unit: 'mg/dL',
    ),

    'indirect_bilirubin': const ReferenceRange(
      minGeneral: 0.1,
      maxGeneral: 0.9,
      unit: 'mg/dL',
    ),

    'total_protein': const ReferenceRange(
      minGeneral: 6.0,
      maxGeneral: 8.3,
      unit: 'g/dL',
    ),

    'albumin': const ReferenceRange(
      minGeneral: 3.5,
      maxGeneral: 5.5,
      unit: 'g/dL',
    ),

    'globulin': const ReferenceRange(
      minGeneral: 2.0,
      maxGeneral: 3.5,
      unit: 'g/dL',
    ),

    // ===== THYROID FUNCTION =====

    'tsh': ReferenceRange(
      minGeneral: 0.4,
      maxGeneral: 4.0,
      unit: 'μIU/mL',
      criticalLevels: {
        'subclinical_hypo': 4.5,
        'hypothyroid': 10.0,
      },
    ),

    't3': const ReferenceRange(
      minGeneral: 80.0,
      maxGeneral: 200.0,
      unit: 'ng/dL',
    ),

    't4': const ReferenceRange(
      minGeneral: 5.0,
      maxGeneral: 12.0,
      unit: 'μg/dL',
    ),

    // ===== ELECTROLYTES =====

    'serum_calcium': const ReferenceRange(
      minGeneral: 8.5,
      maxGeneral: 10.5,
      unit: 'mg/dL',
    ),

    'serum_sodium': const ReferenceRange(
      minGeneral: 136.0,
      maxGeneral: 145.0,
      unit: 'mEq/L',
    ),

    'serum_potassium': const ReferenceRange(
      minGeneral: 3.5,
      maxGeneral: 5.0,
      unit: 'mEq/L',
    ),

    'serum_chloride': const ReferenceRange(
      minGeneral: 96.0,
      maxGeneral: 106.0,
      unit: 'mEq/L',
    ),

    'serum_magnesium': const ReferenceRange(
      minGeneral: 1.7,
      maxGeneral: 2.2,
      unit: 'mg/dL',
    ),

    // ===== VITAMINS =====

    'vitamin_d': ReferenceRange(
      minGeneral: 30.0,
      maxGeneral: 100.0,
      unit: 'ng/mL',
      criticalLevels: {
        'insufficient': 20.0,
        'deficient': 12.0,
      },
    ),

    'vitamin_b12': ReferenceRange(
      minGeneral: 200.0,
      maxGeneral: 900.0,
      unit: 'pg/mL',
      criticalLevels: {
        'low': 200.0,
        'deficient': 150.0,
      },
    ),

    // ===== OTHER TESTS =====

    'esr': ReferenceRange(
      minMale: 0.0,
      maxMale: 15.0,
      minFemale: 0.0,
      maxFemale: 20.0,
      unit: 'mm/hr',
      isGenderDependent: true,
    ),

    'rheumatoid_factor': const ReferenceRange(
      minGeneral: 0.0,
      maxGeneral: 14.0,
      unit: 'IU/mL',
    ),

    'c_reactive_protein': ReferenceRange(
      minGeneral: 0.0,
      maxGeneral: 3.0,
      unit: 'mg/L',
      criticalLevels: {
        'low_risk': 1.0,
        'moderate_risk': 3.0,
        'high_risk': 10.0,
      },
    ),

    // ===== URINE ANALYSIS =====

    'urine_specific_gravity': const ReferenceRange(
      minGeneral: 1.005,
      maxGeneral: 1.030,
      unit: '',
    ),

    'urine_pus_cells': const ReferenceRange(
      minGeneral: 0.0,
      maxGeneral: 5.0,
      unit: '/HPF',
    ),

    'urine_rbc': const ReferenceRange(
      minGeneral: 0.0,
      maxGeneral: 2.0,
      unit: '/HPF',
    ),

    'urine_epithelial_cells': const ReferenceRange(
      minGeneral: 0.0,
      maxGeneral: 5.0,
      unit: '/HPF',
    ),
  };

  /// Get reference range for a parameter
  static ReferenceRange? getRange(String parameterName) {
    return ranges[parameterName.toLowerCase()];
  }

  /// Get reference range with gender consideration
  static Map<String, double?> getRangeForGender(
    String parameterName,
    String? gender,
  ) {
    final range = getRange(parameterName);
    if (range == null) return {'min': null, 'max': null};

    return {
      'min': range.getMin(gender: gender),
      'max': range.getMax(gender: gender),
    };
  }

  /// Check if parameter exists in database
  static bool hasRange(String parameterName) {
    return ranges.containsKey(parameterName.toLowerCase());
  }

  /// Get all parameter names that have reference ranges
  static List<String> getAllParameters() {
    return ranges.keys.toList()..sort();
  }

  /// Get status of a value (normal, low, high, critical)
  static String getStatus(
    String parameterName,
    double value, {
    String? gender,
    double? providedMin,
    double? providedMax,
  }) {
    // Use provided ranges if available
    if (providedMin != null && providedMax != null) {
      if (value < providedMin) return 'low';
      if (value > providedMax) return 'high';
      return 'normal';
    }

    // Use database ranges
    final rangeData = getRangeForGender(parameterName, gender);
    final min = rangeData['min'];
    final max = rangeData['max'];

    if (min == null || max == null) return 'unknown';

    if (value < min) return 'low';
    if (value > max) return 'high';

    // Check for critical ranges
    final range = getRange(parameterName);
    final criticalStatus = range?.getCriticalStatus(value);
    if (criticalStatus != null) return criticalStatus;

    return 'normal';
  }

  /// Get health interpretation for a parameter value
  static String getInterpretation(
    String parameterName,
    double value, {
    String? gender,
  }) {
    final status = getStatus(parameterName, value, gender: gender);

    final interpretations = {
      // Blood glucose
      'fasting_blood_sugar': {
        'normal': 'Blood sugar is within normal range',
        'prediabetic':
            'Elevated glucose - prediabetic range. Lifestyle changes recommended',
        'diabetic':
            'High glucose - diabetic range. Medical consultation needed',
        'low': 'Low blood sugar - hypoglycemia. Check with doctor',
      },
      'hba1c': {
        'normal': 'Excellent long-term glucose control',
        'prediabetic': 'Prediabetic range - implement lifestyle changes',
        'diabetic': 'Diabetic range - medical management required',
      },
      // Lipids
      'serum_cholesterol': {
        'normal': 'Cholesterol within healthy range',
        'borderline_high':
            'Borderline high cholesterol - dietary changes recommended',
        'high': 'High cholesterol - medical evaluation needed',
      },
      'serum_ldl_cholesterol': {
        'normal': 'LDL cholesterol optimal',
        'borderline_high': 'LDL slightly elevated - watch diet',
        'high': 'High LDL - increased heart disease risk',
        'very_high': 'Very high LDL - immediate action required',
      },
    };

    final paramInterpretations = interpretations[parameterName];
    if (paramInterpretations == null) {
      return status == 'normal'
          ? 'Value within normal range'
          : 'Value outside normal range';
    }

    return paramInterpretations[status] ?? 'Value outside normal range';
  }
}
