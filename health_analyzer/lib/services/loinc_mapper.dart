import 'package:fuzzywuzzy/fuzzywuzzy.dart';

/// LOINC Mapper - Normalizes parameter names to standard format
/// Handles variations in parameter naming across different labs
/// Enhanced with 200+ mappings based on real-world blood report analysis
class LOINCMapper {
  // Comprehensive mapping of parameter variations to standard names
  static final Map<String, String> _parameterMap = {
    // ===== BASIC HEMATOLOGY =====

    // RBC Count variations
    'rbc': 'rbc_count',
    'rbc count': 'rbc_count',
    'rbc_count': 'rbc_count',
    'rbccount': 'rbc_count',
    'red blood cells': 'rbc_count',
    'red blood cell count': 'rbc_count',
    'erythrocytes': 'rbc_count',
    'erythrocyte count': 'rbc_count',
    'total rbc': 'rbc_count',

    // WBC Count variations
    'wbc': 'wbc_count',
    'wbc count': 'wbc_count',
    'wbc_count': 'wbc_count',
    'wbccount': 'wbc_count',
    'white blood cells': 'wbc_count',
    'white blood cell count': 'wbc_count',
    'leukocytes': 'wbc_count',
    'leukocyte count': 'wbc_count',
    'total wbc': 'wbc_count',
    'tc': 'wbc_count',
    'tlc': 'wbc_count',
    'total leukocyte count': 'wbc_count',

    // Hemoglobin variations
    'hb': 'hemoglobin',
    'hgb': 'hemoglobin',
    'hemoglobin': 'hemoglobin',
    'haemoglobin': 'hemoglobin',
    'hgb concentration': 'hemoglobin',
    'hb concentration': 'hemoglobin',

    // Hematocrit variations
    'hct': 'hematocrit',
    'hematocrit': 'hematocrit',
    'haematocrit': 'hematocrit',
    'packed cell volume': 'hematocrit',
    'pcv': 'hematocrit',

    // Platelet variations
    'plt': 'platelet_count',
    'platelet': 'platelet_count',
    'platelets': 'platelet_count',
    'platelet count': 'platelet_count',
    'platelet_count': 'platelet_count',
    'platelet count page2': 'platelet_count',
    'platelet_count_page2': 'platelet_count',
    'thrombocytes': 'platelet_count',
    'thrombocyte count': 'platelet_count',

    // MCV, MCH, MCHC
    'mcv': 'mcv',
    'mean corpuscular volume': 'mcv',
    'mean cell volume': 'mcv',
    'mch': 'mch',
    'mean corpuscular hemoglobin': 'mch',
    'mean cell hemoglobin': 'mch',
    'mchc': 'mchc',
    'mean corpuscular hemoglobin concentration': 'mchc',
    'mean cell hemoglobin concentration': 'mchc',

    // RDW and MPV
    'rdw': 'rdw',
    'red cell distribution width': 'rdw',
    'rdw cv': 'rdw',
    'rdw sd': 'rdw',
    'mpv': 'mpv',
    'mean platelet volume': 'mpv',
    'pct': 'plateletcrit',
    'plateletcrit': 'plateletcrit',
    'pdw': 'pdw',
    'platelet distribution width': 'pdw',
    'p_lcr': 'p_lcr',
    'plcr': 'p_lcr',
    'platelet large cell ratio': 'p_lcr',

    // ===== DIFFERENTIAL COUNT =====

    // Neutrophils variations
    'neutrophils': 'neutrophil_percentage',
    'neutrophil': 'neutrophil_percentage',
    'neutrophil count': 'neutrophil_percentage',
    'neutrophil %': 'neutrophil_percentage',
    'neutrophil percentage': 'neutrophil_percentage',
    'neutrophil_percentage': 'neutrophil_percentage',
    'neut': 'neutrophil_percentage',
    'polymorphs': 'neutrophil_percentage',
    'pmn': 'neutrophil_percentage',
    'segmented neutrophils': 'neutrophil_percentage',
    'segs': 'neutrophil_percentage',

    // Lymphocytes variations
    'lymphocytes': 'lymphocyte_percentage',
    'lymphocyte': 'lymphocyte_percentage',
    'lymphocyte count': 'lymphocyte_percentage',
    'lymphocyte %': 'lymphocyte_percentage',
    'lymphocyte percentage': 'lymphocyte_percentage',
    'lymphocyte_percentage': 'lymphocyte_percentage',
    'lymphocyte_percent': 'lymphocyte_percentage',
    'lymphocyte percentage page2': 'lymphocyte_percentage',
    'lymphocyte_percentage_page2': 'lymphocyte_percentage',
    'lymphocyte count page2': 'lymphocyte_percentage',
    'lymphocyte_count_page2': 'lymphocyte_percentage',
    'lymph': 'lymphocyte_percentage',

    // Monocytes variations
    'monocytes': 'monocyte_percentage',
    'monocyte': 'monocyte_percentage',
    'monocyte count': 'monocyte_percentage',
    'monocyte %': 'monocyte_percentage',
    'monocyte percentage': 'monocyte_percentage',
    'monocyte_percentage': 'monocyte_percentage',
    'monocyte percentage page2': 'monocyte_percentage',
    'monocyte_percentage_page2': 'monocyte_percentage',
    'monocyte absolute page2': 'monocyte_percentage',
    'monocyte_absolute_page2': 'monocyte_percentage',
    'mono': 'monocyte_percentage',

    // Eosinophils variations
    'eosinophils': 'eosinophil_percentage',
    'eosinophil': 'eosinophil_percentage',
    'eosinophil count': 'eosinophil_percentage',
    'eosinophil %': 'eosinophil_percentage',
    'eosinophil percentage': 'eosinophil_percentage',
    'eosinophil_percentage': 'eosinophil_percentage',
    'eos': 'eosinophil_percentage',

    // Basophils variations
    'basophils': 'basophil_percentage',
    'basophil': 'basophil_percentage',
    'basophil count': 'basophil_percentage',
    'basophil %': 'basophil_percentage',
    'basophil percentage': 'basophil_percentage',
    'basophil_percentage': 'basophil_percentage',
    'baso': 'basophil_percentage',

    // Immature cells
    'band cells': 'band_cells_percentage',
    'band_cells': 'band_cells_percentage',
    'band cells percentage': 'band_cells_percentage',
    'band_cells_percentage': 'band_cells_percentage',
    'bands': 'band_cells_percentage',

    'blast cells': 'blast_cells_percentage',
    'blast_cells': 'blast_cells_percentage',
    'blast cells percentage': 'blast_cells_percentage',
    'blast_cells_percentage': 'blast_cells_percentage',
    'blasts': 'blast_cells_percentage',

    'myelocyte': 'myelocyte_percentage',
    'myelocytes': 'myelocyte_percentage',
    'myelocyte percentage': 'myelocyte_percentage',
    'myelocyte_percentage': 'myelocyte_percentage',

    'meta myelocyte': 'meta_myelocyte_percentage',
    'meta_myelocyte': 'meta_myelocyte_percentage',
    'metamyelocyte': 'meta_myelocyte_percentage',
    'meta myelocyte percentage': 'meta_myelocyte_percentage',
    'meta_myelocyte_percentage': 'meta_myelocyte_percentage',

    'pro myelocyte': 'pro_myelocyte_percentage',
    'pro_myelocyte': 'pro_myelocyte_percentage',
    'promyelocyte': 'pro_myelocyte_percentage',
    'pro myelocyte percentage': 'pro_myelocyte_percentage',
    'pro_myelocyte_percentage': 'pro_myelocyte_percentage',

    // Granulocytes
    'granulocytes': 'granulocyte_percentage',
    'granulocyte': 'granulocyte_percentage',
    'granulocyte percentage': 'granulocyte_percentage',
    'granulocyte_percentage': 'granulocyte_percentage',
    'granulocyte percent': 'granulocyte_percentage',
    'granulocyte percentage page2': 'granulocyte_percentage',
    'granulocyte_percentage_page2': 'granulocyte_percentage',
    'granulocyte count': 'granulocyte_percentage',
    'granulocyte_count': 'granulocyte_percentage',
    'granulocyte count page2': 'granulocyte_percentage',
    'granulocyte_count_page2': 'granulocyte_percentage',
    'granulocyte absolute page2': 'granulocyte_percentage',
    'granulocyte_absolute_page2': 'granulocyte_percentage',

    // Mid cells
    'mid': 'mid_percentage',
    'mid cells': 'mid_percentage',
    'mid percentage': 'mid_percentage',
    'mid_percentage': 'mid_percentage',
    'mid count': 'mid_percentage',
    'mid_count': 'mid_percentage',
    'mid count page2': 'mid_percentage',
    'mid_count_page2': 'mid_percentage',
    'mid percentage page2': 'mid_percentage',
    'mid_percentage_page2': 'mid_percentage',
    'mid percent': 'mid_percentage',
    'mid_percent': 'mid_percentage',

    // LCR / LPCR
    'lcr': 'lcr',
    'lpcr': 'lcr',
    'large cell ratio': 'lcr',

    // ===== BLOOD CHEMISTRY =====

    // Glucose
    'fasting blood sugar': 'fasting_blood_sugar',
    'fasting_blood_sugar': 'fasting_blood_sugar',
    'fasting blood glucose': 'fasting_blood_sugar',
    'fasting_blood_glucose': 'fasting_blood_sugar',
    'fbs': 'fasting_blood_sugar',
    'fbg': 'fasting_blood_sugar',
    'fasting glucose': 'fasting_blood_sugar',

    'post prandial blood sugar': 'post_prandial_blood_sugar',
    'post_prandial_blood_sugar': 'post_prandial_blood_sugar',
    'ppbs': 'post_prandial_blood_sugar',
    'pp blood sugar': 'post_prandial_blood_sugar',
    'post prandial glucose': 'post_prandial_blood_sugar',

    'random blood sugar': 'random_blood_sugar',
    'random_blood_sugar': 'random_blood_sugar',
    'rbs': 'random_blood_sugar',
    'random glucose': 'random_blood_sugar',

    // HbA1c variations
    'hba1c': 'hba1c',
    'hba1c level': 'hba1c',
    'hba1c_level': 'hba1c',
    'blood glycosylated hb hba1c level': 'hba1c',
    'blood_glycosylated_hb_hba1c_level': 'hba1c',
    'blood glycosylated hba1c level': 'hba1c',
    'blood_glycosylated_hba1c_level': 'hba1c',
    'hba1c glycated haemoglobin': 'hba1c',
    'hba1c_glycated_haemoglobin': 'hba1c',
    'glycated hemoglobin': 'hba1c',
    'glycated haemoglobin': 'hba1c',
    'glycosylated hemoglobin': 'hba1c',
    'hemoglobin a1c': 'hba1c',
    'a1c': 'hba1c',

    // Mean Blood Glucose
    'mean blood glucose mbg from hba1c level': 'mean_blood_glucose',
    'mean_blood_glucose_mbg_from_hba1c_level': 'mean_blood_glucose',
    'mean blood glucose mbg': 'mean_blood_glucose',
    'mean_blood_glucose_mbg': 'mean_blood_glucose',
    'estimated average glucose': 'mean_blood_glucose',
    'estimated_average_glucose': 'mean_blood_glucose',
    'eag': 'mean_blood_glucose',
    'mbg': 'mean_blood_glucose',

    // Creatinine
    'serum creatinine': 'serum_creatinine',
    'serum_creatinine': 'serum_creatinine',
    'creatinine serum': 'serum_creatinine',
    'creatinine_serum': 'serum_creatinine',
    'creatinine': 'serum_creatinine',
    'cr': 'serum_creatinine',

    // Calcium
    'serum calcium': 'serum_calcium',
    'serum_calcium': 'serum_calcium',
    'calcium': 'serum_calcium',
    'ca': 'serum_calcium',
    'total calcium': 'serum_calcium',

    // ===== LIPID PROFILE =====

    // Total Cholesterol
    'serum cholesterol': 'serum_cholesterol',
    'serum_cholesterol': 'serum_cholesterol',
    'total cholesterol': 'serum_cholesterol',
    'total_cholesterol': 'serum_cholesterol',
    'cholesterol': 'serum_cholesterol',
    'chol': 'serum_cholesterol',

    // HDL Cholesterol
    'serum hdl cholesterol': 'serum_hdl_cholesterol',
    'serum_hdl_cholesterol': 'serum_hdl_cholesterol',
    'serum hdl cholesterol direct': 'serum_hdl_cholesterol',
    'serum_hdl_cholesterol_direct': 'serum_hdl_cholesterol',
    'hdl cholesterol': 'serum_hdl_cholesterol',
    'hdl_cholesterol': 'serum_hdl_cholesterol',
    'hdl': 'serum_hdl_cholesterol',
    'high density lipoprotein': 'serum_hdl_cholesterol',

    // LDL Cholesterol
    'serum ldl cholesterol': 'serum_ldl_cholesterol',
    'serum_ldl_cholesterol': 'serum_ldl_cholesterol',
    'ldl cholesterol': 'serum_ldl_cholesterol',
    'ldl_cholesterol': 'serum_ldl_cholesterol',
    'ldl': 'serum_ldl_cholesterol',
    'low density lipoprotein': 'serum_ldl_cholesterol',

    // VLDL Cholesterol
    'serum vldl cholesterol': 'serum_vldl_cholesterol',
    'serum_vldl_cholesterol': 'serum_vldl_cholesterol',
    'vldl cholesterol': 'serum_vldl_cholesterol',
    'vldl_cholesterol': 'serum_vldl_cholesterol',
    'vldl': 'serum_vldl_cholesterol',
    'very low density lipoprotein': 'serum_vldl_cholesterol',

    // Triglycerides
    'serum triglycerides': 'serum_triglycerides',
    'serum_triglycerides': 'serum_triglycerides',
    'serum triglyceride': 'serum_triglycerides',
    'serum_triglyceride': 'serum_triglycerides',
    'triglycerides': 'serum_triglycerides',
    'triglyceride': 'serum_triglycerides',
    'tg': 'serum_triglycerides',

    // Cholesterol Ratios
    'chol hdl ratio': 'chol_hdl_ratio',
    'chol_hdl_ratio': 'chol_hdl_ratio',
    'chole hdl ratio': 'chol_hdl_ratio', // Typo variation
    'chole_hdl_ratio': 'chol_hdl_ratio',
    'cholesterol hdl ratio': 'chol_hdl_ratio',
    'cholesterol_hdl_ratio': 'chol_hdl_ratio',
    'tc hdl ratio': 'chol_hdl_ratio',
    'total cholesterol hdl ratio': 'chol_hdl_ratio',

    'ldl hdl ratio': 'ldl_hdl_ratio',
    'ldl_hdl_ratio': 'ldl_hdl_ratio',
    'ldl hdl cholesterol ratio': 'ldl_hdl_ratio',
    'ldl_hdl_cholesterol_ratio': 'ldl_hdl_ratio',

    // ===== LIVER FUNCTION =====

    'sgpt alt estimation': 'sgpt',
    'sgpt_alt_estimation': 'sgpt',
    'sgpt alt': 'sgpt',
    'sgpt_alt': 'sgpt',
    'sgpt': 'sgpt',
    'alt': 'sgpt',
    'alanine aminotransferase': 'sgpt',
    'alanine transaminase': 'sgpt',

    'sgot': 'sgot',
    'ast': 'sgot',
    'aspartate aminotransferase': 'sgot',
    'aspartate transaminase': 'sgot',

    'alkaline phosphatase': 'alkaline_phosphatase',
    'alp': 'alkaline_phosphatase',

    'total bilirubin': 'total_bilirubin',
    'bilirubin total': 'total_bilirubin',

    'direct bilirubin': 'direct_bilirubin',
    'bilirubin direct': 'direct_bilirubin',

    'indirect bilirubin': 'indirect_bilirubin',
    'bilirubin indirect': 'indirect_bilirubin',

    // ===== THYROID FUNCTION =====

    'serum tsh': 'tsh',
    'serum_tsh': 'tsh',
    'tsh ultrasensitive': 'tsh',
    'tsh_ultrasensitive': 'tsh',
    'tsh': 'tsh',
    'thyroid stimulating hormone': 'tsh',

    'serum t3': 't3',
    'serum_t3': 't3',
    't3 total': 't3',
    't3_total': 't3',
    't3': 't3',
    'triiodothyronine': 't3',

    'serum t4': 't4',
    'serum_t4': 't4',
    't4 total': 't4',
    't4_total': 't4',
    't4': 't4',
    'thyroxine': 't4',

    // ===== URINE ANALYSIS =====

    'urine quantity': 'urine_quantity',
    'urine_quantity': 'urine_quantity',
    'urine physical examination quantity': 'urine_quantity',
    'urine_physical_examination_quantity': 'urine_quantity',

    'urine specific gravity': 'urine_specific_gravity',
    'urine_specific_gravity': 'urine_specific_gravity',
    'specific gravity': 'urine_specific_gravity',

    'epithelial cells': 'urine_epithelial_cells',
    'urine epithelial cells': 'urine_epithelial_cells',
    'urine_epithelial_cells': 'urine_epithelial_cells',

    'wbc pus cells': 'urine_pus_cells',
    'wbc_pus_cells': 'urine_pus_cells',
    'pus cells': 'urine_pus_cells',
    'urine pus cells': 'urine_pus_cells',
    'urine_pus_cells': 'urine_pus_cells',

    'red blood cells urine': 'urine_rbc',
    'red_blood_cells_urine': 'urine_rbc',
    'urine red blood cells': 'urine_rbc',
    'urine_red_blood_cells': 'urine_rbc',
    'urine rbc': 'urine_rbc',
    'urine_rbc': 'urine_rbc',

    // ===== OTHERS =====

    'esr': 'esr',
    'erythrocyte sedimentation rate': 'esr',
    'sed rate': 'esr',

    'vitamin b12 level': 'vitamin_b12',
    'vitamin_b12_level': 'vitamin_b12',
    'vitamin b12': 'vitamin_b12',
    'vitamin_b12': 'vitamin_b12',
    'b12': 'vitamin_b12',

    'vitamin d': 'vitamin_d',
    'vitamin_d': 'vitamin_d',
    '25 oh vitamin d': 'vitamin_d',
    '25_oh_vitamin_d': 'vitamin_d',

    'rheumatoid factor igm': 'rheumatoid_factor',
    'rheumatoid_factor_igm': 'rheumatoid_factor',
    'rheumatoid factor': 'rheumatoid_factor',
    'rheumatoid_factor': 'rheumatoid_factor',
    'rf': 'rheumatoid_factor',
  };

  /// Normalize a parameter name to standard format
  static String normalize(String rawName) {
    // Clean the input
    String cleaned = rawName
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();

    // Direct lookup
    if (_parameterMap.containsKey(cleaned)) {
      return _parameterMap[cleaned]!;
    }

    // Try without spaces
    String noSpaces = cleaned.replaceAll(' ', '_');
    if (_parameterMap.containsKey(noSpaces)) {
      return _parameterMap[noSpaces]!;
    }

    // Fuzzy matching fallback
    return _fuzzyMatch(cleaned);
  }

  /// Fuzzy match parameter name to standard names
  static String _fuzzyMatch(String input) {
    try {
      final List<String> knownParameters =
          _parameterMap.values.toSet().toList();

      // Use fuzzy matching with 85% similarity threshold
      final result = extractOne(
        query: input,
        choices: knownParameters,
        cutoff: 85,
      );

      // If match found with high confidence, return it
      if (result.score >= 85) {
        return result.choice;
      }

      // If no good match, return cleaned input
      // This allows new parameters to be stored as-is
      return input.replaceAll(' ', '_');
    } catch (e) {
      // If fuzzy matching fails, return cleaned input
      return input.replaceAll(' ', '_');
    }
  }

  /// Get all standard parameter names
  static List<String> getAllStandardNames() {
    return _parameterMap.values.toSet().toList()..sort();
  }

  /// Get all variations for a standard name
  static List<String> getVariations(String standardName) {
    return _parameterMap.entries
        .where((entry) => entry.value == standardName)
        .map((entry) => entry.key)
        .toList();
  }

  /// Add a custom mapping (useful for learning from user corrections)
  static void addMapping(String rawName, String standardName) {
    String cleaned = rawName
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    _parameterMap[cleaned] = standardName;
  }

  /// Get friendly display name for a parameter
  static String getDisplayName(String standardName) {
    final Map<String, String> displayNames = {
      'rbc_count': 'RBC Count',
      'wbc_count': 'WBC Count',
      'hemoglobin': 'Hemoglobin',
      'hematocrit': 'Hematocrit',
      'platelet_count': 'Platelet Count',
      'mcv': 'MCV',
      'mch': 'MCH',
      'mchc': 'MCHC',
      'neutrophils': 'Neutrophils',
      'lymphocytes': 'Lymphocytes',
      'monocytes': 'Monocytes',
      'eosinophils': 'Eosinophils',
      'basophils': 'Basophils',
      'esr': 'ESR',
      'rdw': 'RDW',
      'mpv': 'MPV',
    };

    return displayNames[standardName] ??
        standardName
            .split('_')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
  }
}
