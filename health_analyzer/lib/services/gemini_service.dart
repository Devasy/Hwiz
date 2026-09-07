import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/constants.dart';
import 'loinc_mapper.dart';
import 'model_info_service.dart';

/// Gemini Service - Handles OCR and data extraction from blood reports
class GeminiService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  GenerativeModel? _model;

  /// Initialize Gemini model with API key
  Future<void> initialize() async {
    final apiKey = await _secureStorage.read(
      key: AppConstants.geminiApiKeyStorage,
    );
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API key not found. Please set it in settings.');
    }

    // Get selected model from storage, validate against active models, default to gemini-2.5-flash
    final storedModel = await _secureStorage.read(
      key: 'selected_gemini_model',
    );
    final selectedModel = ModelInfoService().getSanitizedModel(storedModel);
    if (storedModel != null && storedModel != selectedModel) {
      await _secureStorage.write(
        key: 'selected_gemini_model',
        value: selectedModel,
      );
    }

    _model = GenerativeModel(model: selectedModel, apiKey: apiKey);
  }

  /// Set API key in secure storage
  Future<void> setApiKey(String apiKey) async {
    await _secureStorage.write(
      key: AppConstants.geminiApiKeyStorage,
      value: apiKey,
    );
    await initialize();
  }

  /// Extract blood report data from image or PDF
  Future<Map<String, dynamic>> extractBloodReportData(File file) async {
    if (_model == null) {
      await initialize();
    }

    final bytes = await file.readAsBytes();
    final mimeType = _getMimeType(file.path);

    final prompt = _buildExtractionPrompt();

    final content = [
      Content.multi([TextPart(prompt), DataPart(mimeType, bytes)]),
    ];

    try {
      final response = await _model!.generateContent(
        content,
        generationConfig: GenerationConfig(
          temperature: 0.1, // Low temperature for consistent output
          maxOutputTokens: 8192, // Increased token limit for large reports
        ),
      );

      final extractedText = response.text;
      if (extractedText == null || extractedText.isEmpty) {
        throw Exception('No data extracted from the report');
      }

      debugPrint(
          '🔍 Raw Gemini Response (length: ${extractedText.length} chars):');
      debugPrint(extractedText);

      // Check if response was likely truncated
      if (response.candidates.isNotEmpty) {
        final finishReason = response.candidates.first.finishReason;
        if (finishReason == FinishReason.maxTokens) {
          debugPrint(
              '⚠️ WARNING: Response truncated due to max token limit. Report may have too many parameters.');
          throw Exception(
              'Report is too large to process in one request. This report contains many parameters. Please try:\n'
              '1. Scanning only the essential pages\n'
              '2. Breaking the report into smaller sections\n'
              '3. Using a higher-tier Gemini model with larger token limits');
        }
      }

      // Parse JSON from response with better error handling
      final jsonData = _parseJsonFromResponse(extractedText);

      // Normalize parameter names
      final normalizedData = _normalizeParameters(jsonData);

      return normalizedData;
    } on FormatException catch (e) {
      debugPrint('❌ JSON Parse Error: $e');
      throw Exception(
          'Failed to parse data from report. The AI response was incomplete or malformed.\n'
          'This usually happens when:\n'
          '- The report has too many parameters (token limit exceeded)\n'
          '- The image quality is poor\n'
          '- The report format is complex\n\n'
          'Please try:\n'
          '1. Scanning fewer pages at once\n'
          '2. Using a clearer/higher quality image\n'
          '3. Upgrading to gemini-1.5-pro model (higher token limit)');
    } catch (e) {
      debugPrint('❌ Extraction Error: $e');
      throw Exception('Failed to extract data from report: ${e.toString()}');
    }
  }

  /// Build the prompt for blood report extraction
  String _buildExtractionPrompt() {
    return '''
You are an expert medical document analyzer. Extract all blood test parameters from this blood report image/PDF.

CRITICAL INSTRUCTIONS:
1. Return ONLY valid JSON, no other text or markdown
2. **KEEP OUTPUT COMPACT** - Use minimal whitespace in JSON
3. Normalize ALL parameter names to lowercase with underscores
4. Extract ALL visible parameters with their values, units, and reference ranges
5. Handle multi-page reports by merging duplicate parameters (don't add _page2 suffix)
6. For duplicate parameters with different values, keep the one with more complete data

REQUIRED FIELDS FOR EACH PARAMETER:
- value: numeric value only (no units, no text)
- unit: the unit of measurement exactly as shown
- ref_min: minimum reference range (MUST extract if visible)
- ref_max: maximum reference range (MUST extract if visible)
- raw_name: the exact parameter name as written in the report (SHORT version)

TOP-LEVEL FIELDS:
- test_date: in YYYY-MM-DD format (look for "Date", "Test Date", "Collection Date")
- lab_name: laboratory name (look for lab logo, header, or footer)

PARAMETER NAME NORMALIZATION (REAL EXAMPLES FROM LABS):
Complete Blood Count (CBC):
- "RBC", "RBC Count", "Red Blood Cells", "Erythrocytes" → "rbc_count"
- "WBC", "WBC Count", "Total WBC", "TC", "TLC" → "wbc_count"
- "Hemoglobin", "Hb", "HGB", "Haemoglobin" → "hemoglobin"
- "Hematocrit", "HCT", "PCV", "Packed Cell Volume" → "hematocrit"
- "Platelets", "PLT", "Platelet Count" → "platelet_count"
- "MCV", "Mean Corpuscular Volume" → "mcv"
- "MCH", "Mean Corpuscular Hemoglobin" → "mch"
- "MCHC", "Mean Corpuscular Hgb Concentration" → "mchc"
- "RDW", "Red Cell Distribution Width" → "rdw"
- "MPV", "Mean Platelet Volume" → "mpv"

Differential Count (ALWAYS use _percentage suffix):
- "Neutrophils", "Neutrophil %", "Polymorphs", "PMN", "Neut" → "neutrophil_percentage"
- "Lymphocytes", "Lymphocyte %", "Lymph" → "lymphocyte_percentage"
- "Monocytes", "Monocyte %", "Mono" → "monocyte_percentage"
- "Eosinophils", "Eosinophil %", "Eos" → "eosinophil_percentage"
- "Basophils", "Basophil %", "Baso" → "basophil_percentage"
- "Band Cells", "Bands" → "band_cells_percentage"
- "Blast Cells", "Blasts" → "blast_cells_percentage"
- "Myelocytes" → "myelocyte_percentage"
- "Metamyelocytes", "Meta Myelocytes" → "meta_myelocyte_percentage"
- "Promyelocytes", "Pro Myelocytes" → "pro_myelocyte_percentage"

Blood Glucose:
- "FBS", "Fasting Blood Sugar", "Fasting Glucose" → "fasting_blood_sugar"
- "PPBS", "PP Blood Sugar", "Post Prandial" → "post_prandial_blood_sugar"
- "RBS", "Random Blood Sugar" → "random_blood_sugar"
- "HbA1c", "A1C", "Glycated Hemoglobin", "Glycosylated Hb" → "hba1c"
- "Mean Blood Glucose", "MBG", "Estimated Average Glucose", "EAG" → "mean_blood_glucose"

Kidney Function:
- "Creatinine", "Serum Creatinine", "Cr" → "serum_creatinine"
- "Calcium", "Serum Calcium", "Ca" → "serum_calcium"
- "Uric Acid" → "uric_acid"
- "BUN", "Blood Urea Nitrogen" → "blood_urea_nitrogen"

Lipid Profile:
- "Total Cholesterol", "Cholesterol", "Serum Cholesterol" → "serum_cholesterol"
- "HDL", "HDL Cholesterol", "High Density Lipoprotein" → "serum_hdl_cholesterol"
- "LDL", "LDL Cholesterol", "Low Density Lipoprotein" → "serum_ldl_cholesterol"
- "VLDL", "VLDL Cholesterol" → "serum_vldl_cholesterol"
- "Triglycerides", "TG" → "serum_triglycerides"
- "TC/HDL Ratio", "Chol/HDL Ratio", "Total Chol/HDL" → "chol_hdl_ratio"
- "LDL/HDL Ratio" → "ldl_hdl_ratio"

Liver Function:
- "SGPT", "ALT", "Alanine Aminotransferase" → "sgpt"
- "SGOT", "AST", "Aspartate Aminotransferase" → "sgot"
- "ALP", "Alkaline Phosphatase" → "alkaline_phosphatase"
- "Total Bilirubin" → "total_bilirubin"
- "Direct Bilirubin" → "direct_bilirubin"

Thyroid:
- "TSH", "Thyroid Stimulating Hormone" → "tsh"
- "T3", "Triiodothyronine", "T3 Total" → "t3"
- "T4", "Thyroxine", "T4 Total" → "t4"

Urine Analysis:
- "Pus Cells", "WBC Pus Cells" → "urine_pus_cells"
- "RBC", "Red Blood Cells" (in urine) → "urine_rbc"
- "Epithelial Cells" → "urine_epithelial_cells"
- "Specific Gravity" → "urine_specific_gravity"

REFERENCE RANGE EXTRACTION TIPS:
- Look for columns labeled: "Reference Range", "Normal Range", "Ref Range", "Biological Range"
- Format can be: "4.5-5.9", "4.5 - 5.9", "4.5 to 5.9", "4.5~5.9"
- May be gender-specific: "M: 13.5-17.5, F: 12.0-15.5" → use male ranges
- May be on same line or separate column
- If ranges appear split across pages, use the one with the parameter value

MULTI-PAGE REPORT HANDLING:
- If you see the same parameter twice (e.g., on different pages), use the value with reference ranges
- DO NOT add "_page2" or "_page_2" suffix
- Merge duplicate readings intelligently

JSON OUTPUT FORMAT:
{
  "test_date": "YYYY-MM-DD",
  "lab_name": "Laboratory Name",
  "parameters": {
    "rbc_count": {
      "value": 5.2,
      "unit": "million cells/μL",
      "ref_min": 4.5,
      "ref_max": 5.9,
      "raw_name": "RBC Count"
    },
    "neutrophil_percentage": {
      "value": 65.0,
      "unit": "%",
      "ref_min": 40.0,
      "ref_max": 70.0,
      "raw_name": "Neutrophils"
    },
    "fasting_blood_sugar": {
      "value": 95.0,
      "unit": "mg/dL",
      "ref_min": 70.0,
      "ref_max": 100.0,
      "raw_name": "FBS"
    }
  }
}

EXTRACT EVERY SINGLE PARAMETER YOU SEE. Return ONLY the JSON, no markdown, no explanation.
''';
  }

  /// Parse JSON from Gemini response
  Map<String, dynamic> _parseJsonFromResponse(String response) {
    debugPrint('📝 Parsing JSON from response (length: ${response.length})');

    // Remove markdown code blocks if present
    String cleaned =
        response.replaceAll('```json', '').replaceAll('```', '').trim();

    // Remove any text before the first {
    final firstBrace = cleaned.indexOf('{');
    if (firstBrace > 0) {
      cleaned = cleaned.substring(firstBrace);
    }

    // Remove any text after the last }
    final lastBrace = cleaned.lastIndexOf('}');
    if (lastBrace > 0 && lastBrace < cleaned.length - 1) {
      cleaned = cleaned.substring(0, lastBrace + 1);
    }

    debugPrint(
        '🧹 Cleaned JSON (first 200 chars): ${cleaned.substring(0, cleaned.length < 200 ? cleaned.length : 200)}');

    try {
      final decoded = json.decode(cleaned);
      debugPrint('✅ Successfully parsed JSON');
      return decoded;
    } on FormatException catch (e) {
      debugPrint('❌ JSON Parse Error: $e');
      debugPrint('📄 Problematic JSON:\n$cleaned');

      // Try to find and extract complete JSON object
      final jsonMatch =
          RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}').firstMatch(cleaned);
      if (jsonMatch != null) {
        try {
          debugPrint('🔄 Trying to parse extracted JSON...');
          return json.decode(jsonMatch.group(0)!);
        } catch (e2) {
          debugPrint('❌ Extracted JSON also failed: $e2');
        }
      }

      throw FormatException(
          'Could not parse JSON from AI response. Response may be incomplete.');
    }
  }

  /// Normalize parameter names using LOINC mapper
  Map<String, dynamic> _normalizeParameters(Map<String, dynamic> data) {
    try {
      debugPrint('🔄 Normalizing parameters...');
      final parameters = data['parameters'] as Map<String, dynamic>? ?? {};
      final normalizedParams = <String, dynamic>{};

      parameters.forEach((key, value) {
        try {
          debugPrint('  Processing parameter: $key');
          final normalizedKey = LOINCMapper.normalize(key);
          debugPrint('    Normalized to: $normalizedKey');
          normalizedParams[normalizedKey] = value;

          // Ensure raw_name is preserved
          if (value is Map && !value.containsKey('raw_name')) {
            value['raw_name'] = key;
          }
        } catch (e) {
          debugPrint('    ❌ Error normalizing $key: $e');
          // Skip this parameter if normalization fails
        }
      });

      debugPrint(
          '✅ Normalization complete. ${normalizedParams.length} parameters processed.');

      return {
        'test_date': data['test_date'],
        'lab_name': data['lab_name'],
        'parameters': normalizedParams,
      };
    } catch (e) {
      debugPrint('❌ Error in _normalizeParameters: $e');
      rethrow;
    }
  }

  /// Get MIME type from file path
  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'image/jpeg';
    }
  }

  /// Test API key validity
  Future<bool> testApiKey(String apiKey) async {
    try {
      final testModel = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: apiKey,
      );

      final response = await testModel.generateContent([Content.text('Hello')]);

      return response.text != null;
    } catch (e) {
      return false;
    }
  }

  /// Extract data with retry logic
  Future<Map<String, dynamic>> extractWithRetry(
    File file, {
    int maxAttempts = AppConstants.maxRetryAttempts,
  }) async {
    int attempt = 0;
    Exception? lastException;

    while (attempt < maxAttempts) {
      attempt++;
      try {
        return await extractBloodReportData(file);
      } catch (e) {
        lastException = e as Exception;
        if (attempt < maxAttempts) {
          // Exponential backoff
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }

    throw lastException ?? Exception('Failed after $maxAttempts attempts');
  }

  /// Generate health insights for blood report
  Future<Map<String, dynamic>> generateHealthInsights({
    required List<Map<String, dynamic>> abnormalParameters,
    required List<Map<String, dynamic>> allParameters,
    String? age,
    String? gender,
  }) async {
    if (_model == null) {
      await initialize();
    }

    final prompt = _buildHealthInsightsPrompt(
      abnormalParameters: abnormalParameters,
      allParameters: allParameters,
      age: age,
      gender: gender,
    );

    try {
      final response = await _model!.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          temperature: 0.3,
          maxOutputTokens: 2048,
        ),
      );

      final analysisText = response.text;
      if (analysisText == null || analysisText.isEmpty) {
        throw Exception('No analysis generated');
      }

      debugPrint('🔍 AI Health Insights Response:');
      debugPrint(analysisText);

      return _parseHealthInsightsResponse(analysisText);
    } catch (e) {
      debugPrint('❌ Health Insights Error: $e');
      throw Exception('Failed to generate health insights: ${e.toString()}');
    }
  }

  /// Build prompt for health insights generation
  String _buildHealthInsightsPrompt({
    required List<Map<String, dynamic>> abnormalParameters,
    required List<Map<String, dynamic>> allParameters,
    String? age,
    String? gender,
  }) {
    final abnormalList = abnormalParameters.map((p) {
      return '- ${p['name']}: ${p['value']} ${p['unit']} (Normal: ${p['ref_min']}-${p['ref_max']}) - Status: ${p['status']}';
    }).join('\n');

    final normalList = allParameters
        .where((p) => !abnormalParameters.any((a) => a['name'] == p['name']))
        .take(5)
        .map((p) => '- ${p['name']}: ${p['value']} ${p['unit']}')
        .join('\n');

    return '''
You are a medical AI assistant analyzing blood test results. Provide clear, helpful health insights.

${age != null ? 'Patient Age: $age years' : ''}
${gender != null ? 'Gender: $gender' : ''}

ABNORMAL PARAMETERS:
$abnormalList

${normalList.isNotEmpty ? 'NORMAL PARAMETERS (sample):\n$normalList' : ''}

Provide a health analysis in JSON format with these sections:

{
  "overall_assessment": "Brief 2-3 sentence summary of overall health status",
  "concerns": [
    {
      "parameter": "Parameter name",
      "issue": "What the abnormal value indicates",
      "recommendation": "Specific actionable advice"
    }
  ],
  "positive_notes": [
    "Brief positive observations about normal values"
  ],
  "next_steps": [
    "Actionable recommendations (e.g., dietary changes, follow-up tests)"
  ]
}

IMPORTANT:
- Be clear and concise
- Focus on actionable advice
- Use simple, non-technical language
- Avoid alarming language
- Include dietary and lifestyle suggestions
- Limit concerns to top 3-4 most important
- Return ONLY valid JSON, no other text

Generate the analysis now:
''';
  }

  /// Parse health insights response
  Map<String, dynamic> _parseHealthInsightsResponse(String response) {
    // Remove markdown code blocks if present
    String cleaned =
        response.replaceAll('```json', '').replaceAll('```', '').trim();

    // Remove any text before the first {
    final firstBrace = cleaned.indexOf('{');
    if (firstBrace > 0) {
      cleaned = cleaned.substring(firstBrace);
    }

    // Remove any text after the last }
    final lastBrace = cleaned.lastIndexOf('}');
    if (lastBrace > 0 && lastBrace < cleaned.length - 1) {
      cleaned = cleaned.substring(0, lastBrace + 1);
    }

    try {
      return json.decode(cleaned);
    } catch (e) {
      debugPrint('❌ Failed to parse health insights JSON: $e');
      // Return fallback structure
      return {
        'overall_assessment':
            'Unable to generate detailed analysis. Please consult your healthcare provider.',
        'concerns': [],
        'positive_notes': [],
        'next_steps': [
          'Consult with your healthcare provider for interpretation'
        ],
      };
    }
  }

  /// Generate trend analysis for a specific parameter
  Future<String> generateTrendAnalysis({
    required String parameterName,
    required List<Map<String, dynamic>> historicalData,
    String? currentStatus,
  }) async {
    if (_model == null) {
      await initialize();
    }

    final prompt = _buildTrendAnalysisPrompt(
      parameterName: parameterName,
      historicalData: historicalData,
      currentStatus: currentStatus,
    );

    try {
      final response = await _model!.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          temperature: 0.3,
          maxOutputTokens: 1024,
        ),
      );

      final analysisText = response.text;
      if (analysisText == null || analysisText.isEmpty) {
        throw Exception('No trend analysis generated');
      }

      debugPrint('🔍 AI Trend Analysis Response:');
      debugPrint(analysisText);

      return analysisText.trim();
    } catch (e) {
      debugPrint('❌ Trend Analysis Error: $e');
      throw Exception('Failed to generate trend analysis: ${e.toString()}');
    }
  }

  /// Build prompt for trend analysis
  String _buildTrendAnalysisPrompt({
    required String parameterName,
    required List<Map<String, dynamic>> historicalData,
    String? currentStatus,
  }) {
    final dataPoints = historicalData.map((d) {
      return '${d['date']}: ${d['value']} ${d['unit'] ?? ''}';
    }).join('\n');

    return '''
You are a medical AI assistant analyzing trends in blood test parameters.

PARAMETER: $parameterName
${currentStatus != null ? 'CURRENT STATUS: $currentStatus' : ''}

HISTORICAL DATA (chronological):
$dataPoints

Analyze this trend and provide:
1. Pattern observation (improving, declining, stable, fluctuating)
2. Possible reasons for the trend
3. Specific recommendations (diet, lifestyle, when to retest)
4. What to watch for

Keep the response:
- Clear and actionable (200-300 words)
- In simple language
- Focused on practical advice
- Non-alarming but informative

Do NOT use JSON format. Write as clear paragraphs with bullet points where helpful.

Provide the analysis now:
''';
  }
}
