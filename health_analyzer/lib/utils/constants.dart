/// Application Constants
class AppConstants {
  // App Info
  static const String appName = 'LabLens';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'health_analyzer.db';
  static const int databaseVersion = 2;

  // Table Names
  static const String tableProfiles = 'profiles';
  static const String tableReports = 'reports';
  static const String tableBloodParameters = 'blood_parameters';
  static const String tableAiChatSessions = 'ai_chat_sessions';
  static const String tableAiChatMessages = 'ai_chat_messages';

  // API Settings
  static const String geminiApiKeyStorage = 'gemini_api_key';
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;

  // Standard Blood Parameters (normalized names across panels)
  static const List<String> standardParameters = [
    // CBC
    'rbc_count',
    'wbc_count',
    'hemoglobin',
    'hematocrit',
    'platelet_count',
    'mcv',
    'mch',
    'mchc',
    'neutrophils',
    'lymphocytes',
    'monocytes',
    'eosinophils',
    'basophils',
    'neutrophil_percentage',
    'lymphocyte_percentage',
    'monocyte_percentage',
    'eosinophil_percentage',
    'basophil_percentage',
    // Blood Glucose
    'fasting_blood_sugar',
    'post_prandial_blood_sugar',
    'random_blood_sugar',
    'hba1c',
    // Lipid Profile
    'serum_cholesterol',
    'serum_hdl_cholesterol',
    'serum_ldl_cholesterol',
    'serum_vldl_cholesterol',
    'serum_triglycerides',
    // Kidney Function
    'serum_creatinine',
    'blood_urea_nitrogen',
    'uric_acid',
    // Liver Function
    'sgpt',
    'sgot',
    'total_bilirubin',
    'direct_bilirubin',
    'alkaline_phosphatase',
    // Thyroid
    'tsh',
    't3',
    't4',
  ];

  // Date Format
  static const String dateFormat = 'yyyy-MM-dd';
  static const String displayDateFormat = 'MMM dd, yyyy';
}

/// Standard units for blood parameters
class ParameterUnits {
  static const Map<String, String> units = {
    // CBC
    'rbc_count': 'million cells/μL',
    'wbc_count': 'cells/μL',
    'hemoglobin': 'g/dL',
    'hematocrit': '%',
    'platelet_count': 'thousand/μL',
    'mcv': 'fL',
    'mch': 'pg',
    'mchc': 'g/dL',
    'neutrophils': '%',
    'lymphocytes': '%',
    'monocytes': '%',
    'eosinophils': '%',
    'basophils': '%',
    'neutrophil_percentage': '%',
    'lymphocyte_percentage': '%',
    'monocyte_percentage': '%',
    'eosinophil_percentage': '%',
    'basophil_percentage': '%',
    // Blood Glucose
    'fasting_blood_sugar': 'mg/dL',
    'post_prandial_blood_sugar': 'mg/dL',
    'random_blood_sugar': 'mg/dL',
    'hba1c': '%',
    // Lipid Profile
    'serum_cholesterol': 'mg/dL',
    'serum_hdl_cholesterol': 'mg/dL',
    'serum_ldl_cholesterol': 'mg/dL',
    'serum_vldl_cholesterol': 'mg/dL',
    'serum_triglycerides': 'mg/dL',
    // Kidney Function
    'serum_creatinine': 'mg/dL',
    'blood_urea_nitrogen': 'mg/dL',
    'uric_acid': 'mg/dL',
    // Liver Function
    'sgpt': 'U/L',
    'sgot': 'U/L',
    'total_bilirubin': 'mg/dL',
    'direct_bilirubin': 'mg/dL',
    'alkaline_phosphatase': 'U/L',
    // Thyroid
    'tsh': 'μIU/mL',
    't3': 'ng/dL',
    't4': 'μg/dL',
  };

  static String getUnit(String parameter) {
    return units[parameter] ?? 'unit';
  }
}

/// Reference ranges for blood parameters (adult male/female average)
class ReferenceRanges {
  static const Map<String, Map<String, double>> ranges = {
    // CBC
    'rbc_count': {'min': 4.5, 'max': 5.9},
    'wbc_count': {'min': 4000, 'max': 11000},
    'hemoglobin': {'min': 13.5, 'max': 17.5},
    'hematocrit': {'min': 38.3, 'max': 48.6},
    'platelet_count': {'min': 150, 'max': 400},
    'mcv': {'min': 80, 'max': 100},
    'mch': {'min': 27, 'max': 33},
    'mchc': {'min': 32, 'max': 36},
    'neutrophils': {'min': 40, 'max': 70},
    'lymphocytes': {'min': 20, 'max': 40},
    'monocytes': {'min': 2, 'max': 8},
    'eosinophils': {'min': 1, 'max': 4},
    'basophils': {'min': 0.5, 'max': 1},
    'neutrophil_percentage': {'min': 40, 'max': 70},
    'lymphocyte_percentage': {'min': 20, 'max': 40},
    'monocyte_percentage': {'min': 2, 'max': 8},
    'eosinophil_percentage': {'min': 1, 'max': 4},
    'basophil_percentage': {'min': 0.5, 'max': 1},
    // Blood Glucose
    'fasting_blood_sugar': {'min': 70, 'max': 100},
    'post_prandial_blood_sugar': {'min': 70, 'max': 140},
    'random_blood_sugar': {'min': 70, 'max': 140},
    'hba1c': {'min': 4.0, 'max': 5.6},
    // Lipid Profile
    'serum_cholesterol': {'min': 125, 'max': 200},
    'serum_hdl_cholesterol': {'min': 40, 'max': 60},
    'serum_ldl_cholesterol': {'min': 0, 'max': 100},
    'serum_vldl_cholesterol': {'min': 2, 'max': 30},
    'serum_triglycerides': {'min': 0, 'max': 150},
    // Kidney Function
    'serum_creatinine': {'min': 0.6, 'max': 1.2},
    'blood_urea_nitrogen': {'min': 7, 'max': 20},
    'uric_acid': {'min': 3.5, 'max': 7.2},
    // Liver Function
    'sgpt': {'min': 7, 'max': 56},
    'sgot': {'min': 10, 'max': 40},
    'total_bilirubin': {'min': 0.2, 'max': 1.2},
    'direct_bilirubin': {'min': 0.0, 'max': 0.3},
    'alkaline_phosphatase': {'min': 44, 'max': 147},
    // Thyroid
    'tsh': {'min': 0.4, 'max': 4.0},
    't3': {'min': 80, 'max': 200},
    't4': {'min': 4.5, 'max': 12.0},
  };

  static Map<String, double>? getRange(String parameter) {
    return ranges[parameter];
  }
}
