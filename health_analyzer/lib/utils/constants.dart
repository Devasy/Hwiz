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

  // Standard Blood Parameters (normalized names)
  static const List<String> standardParameters = [
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
  ];

  // Date Format
  static const String dateFormat = 'yyyy-MM-dd';
  static const String displayDateFormat = 'MMM dd, yyyy';
}

/// Standard units for blood parameters
class ParameterUnits {
  static const Map<String, String> units = {
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
  };

  static String getUnit(String parameter) {
    return units[parameter] ?? 'unit';
  }
}

/// Reference ranges for blood parameters (adult male/female average)
class ReferenceRanges {
  static const Map<String, Map<String, double>> ranges = {
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
  };

  static Map<String, double>? getRange(String parameter) {
    return ranges[parameter];
  }
}
