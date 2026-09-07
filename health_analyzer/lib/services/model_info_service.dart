import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service to manage Gemini model information
///
/// This service provides information about available Gemini models.
/// Models are dynamically fetched from Google's API.
class ModelInfoService {
  /// Fetch available models dynamically from Gemini API
  Future<List<ModelOption>> fetchAvailableModels(String apiKey) async {
    developer.log('Fetching available Gemini models from API...');

    // Models whose names contain these strings are audio/video-only and cannot
    // process PDFs or images — exclude them from the model picker.
    const _audioOnlyPatterns = [
      'transcribe', 'tts', '-live', 'native-audio',
      'lyria', 'veo', 'robotics',
    ];

    try {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models?pageSize=200');

      final response = await http.get(
        url,
        headers: {'x-goog-api-key': apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['models'] as List;

        developer.log('Fetched ${models.length} models from API');

        final availableModels = <ModelOption>[];

        for (final model in models) {
          final name = model['name'] as String;
          final displayName = model['displayName'] as String? ?? name;
          final description =
              model['description'] as String? ?? 'No description';
          final supportedMethods =
              (model['supportedGenerationMethods'] as List?)?.cast<String>() ??
                  [];
          final inputTokenLimit = model['inputTokenLimit'] as int? ?? 0;
          final outputTokenLimit = model['outputTokenLimit'] as int? ?? 0;

          final modelId = name.replaceFirst('models/', '');

          // Skip models that only support bidiGenerateContent (live/audio only)
          final onlyBidi = supportedMethods.length == 1 &&
              supportedMethods.contains('bidiGenerateContent');

          // Skip known audio/video-only model families
          final isAudioOnly = _audioOnlyPatterns
              .any((p) => modelId.toLowerCase().contains(p));

          if (supportedMethods.contains('generateContent') &&
              !onlyBidi &&
              !isAudioOnly) {
            final info = _createModelInfo(modelId, displayName, description,
                inputTokenLimit, outputTokenLimit);
            availableModels.add(ModelOption(id: modelId, info: info));
          }
        }

        developer.log('Models supporting PDF/image generateContent: ${availableModels.length}');

        // Sort: recommended first, then by version descending
        availableModels.sort((a, b) {
          if (a.info.recommended && !b.info.recommended) return -1;
          if (!a.info.recommended && b.info.recommended) return 1;
          return b.id.compareTo(a.id);
        });

        return availableModels;
      } else {
        developer.log('API Error: ${response.statusCode}');
        throw Exception('Failed to fetch models: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Falling back to static model list: $e');
      return getAllAvailableModels();
    }
  }

  /// Create model info from API data
  ModelDisplayInfo _createModelInfo(
    String modelId,
    String displayName,
    String description,
    int inputTokenLimit,
    int outputTokenLimit,
  ) {
    // Check if we have custom info for known models
    final knownInfo = getModelDisplayInfo()[modelId];
    if (knownInfo != null) {
      return knownInfo;
    }

    // Create info for unknown models
    return ModelDisplayInfo(
      name: displayName,
      description: description,
      recommended: _isRecommended(modelId),
      speed: _estimateSpeed(modelId),
      quality: _estimateQuality(modelId),
      inputTokenLimit: inputTokenLimit,
      outputTokenLimit: outputTokenLimit,
    );
  }

  bool _isRecommended(String modelId) {
    return modelId.contains('3.5-flash-lite') ||
        modelId.contains('3.5-flash') ||
        modelId.contains('2.5-flash');
  }

  String _estimateSpeed(String modelId) {
    if (modelId.contains('flash-lite') || modelId.contains('8b')) return 'Fastest';
    if (modelId.contains('flash')) return 'Very Fast';
    if (modelId.contains('pro')) return 'Fast';
    return 'Medium';
  }

  String _estimateQuality(String modelId) {
    if (modelId.contains('3.7') || modelId.contains('3.6') || modelId.contains('pro')) return 'Best';
    if (modelId.contains('3.5') || modelId.contains('2.5')) return 'Excellent';
    return 'Good';
  }

  /// Get all available Gemini models (static fallback)
  List<ModelOption> getAllAvailableModels() {
    final displayInfo = getModelDisplayInfo();
    return displayInfo.entries.map((entry) {
      return ModelOption(id: entry.key, info: entry.value);
    }).toList();
  }

  /// Get model display information for all current Gemini models
  Map<String, ModelDisplayInfo> getModelDisplayInfo() {
    return {
      // Gemini 3.5 Models (Recommended)
      'gemini-3.5-flash-lite': ModelDisplayInfo(
        name: 'Gemini 3.5 Flash Lite',
        description:
            '⚡ Recommended default: Ultra-fast, cost-effective multimodal model with next-gen reasoning and fast OCR extraction.',
        recommended: true,
        speed: 'Fastest',
        quality: 'Excellent',
        inputTokenLimit: 1048576,
        outputTokenLimit: 65536,
      ),

      'gemini-3.5-flash': ModelDisplayInfo(
        name: 'Gemini 3.5 Flash',
        description:
            '🚀 Balanced flagship multimodal model with strong reasoning and comprehensive extraction capabilities.',
        recommended: true,
        speed: 'Very Fast',
        quality: 'Best',
        inputTokenLimit: 1048576,
        outputTokenLimit: 65536,
      ),

      'gemini-3.6-flash': ModelDisplayInfo(
        name: 'Gemini 3.6 Flash',
        description:
            '🧠 Advanced reasoning model for complex multipage laboratory reports and trend analysis.',
        recommended: false,
        speed: 'Fast',
        quality: 'Best',
        inputTokenLimit: 1048576,
        outputTokenLimit: 65536,
      ),

      'gemini-3.7-flash': ModelDisplayInfo(
        name: 'Gemini 3.7 Flash',
        description:
            '🎯 State-of-the-art thorough reasoning model with dynamic thinking capability.',
        recommended: false,
        speed: 'Fast',
        quality: 'Best',
        inputTokenLimit: 1048576,
        outputTokenLimit: 65536,
      ),

      // Gemini 2.5 Models (Fallback)
      'gemini-2.5-flash': ModelDisplayInfo(
        name: 'Gemini 2.5 Flash',
        description:
            '🛡️ Reliable production workhorse fallback for medical records and report extraction.',
        recommended: true,
        speed: 'Very Fast',
        quality: 'Excellent',
        inputTokenLimit: 1048576,
        outputTokenLimit: 65536,
      ),
    };
  }

  /// Get recommended models specifically for OCR/Vision tasks
  List<String> getRecommendedModelsForOCR() {
    return [
      'gemini-3.5-flash-lite',
      'gemini-3.5-flash',
      'gemini-2.5-flash',
    ];
  }

  /// Get the default model
  String getDefaultModel() {
    return 'gemini-3.5-flash-lite';
  }

  /// Check if a model ID is valid and active
  bool isValidModel(String? modelId) {
    return modelId != null && (getModelDisplayInfo().containsKey(modelId) || modelId.startsWith('gemini-'));
  }

  /// Sanitize model ID — validates against the static known-model map.
  /// Falls back to the default if the ID is null, empty, or not in the map.
  /// This prevents retired or audio-only model IDs from reaching GeminiApiClient.
  String getSanitizedModel(String? modelId) {
    if (modelId != null && modelId.isNotEmpty &&
        getModelDisplayInfo().containsKey(modelId)) {
      return modelId;
    }
    return getDefaultModel();
  }

  /// Get information about model updates
  String getModelUpdateInfo() {
    return '''
Model List Last Updated: September 2026

Active Production Models (PDF/image capable):
- Gemini 3.5 Flash Lite - Fastest, recommended default for extraction
- Gemini 3.5 Flash     - Slightly higher extraction accuracy (~6% more params)
- Gemini 3.6/3.7 Flash - Advanced reasoning for complex multi-page reports
- Gemini 2.5 Flash     - Reliable fallback production workhorse

Note: gemini-3.5-transcribe is audio/speech-to-text only and cannot
process PDFs or images. It is excluded from the model picker.

For the latest model information, visit:
https://ai.google.dev/gemini-api/docs/models/gemini
    ''';
  }
}

/// Model option with ID and display info
class ModelOption {
  final String id;
  final ModelDisplayInfo info;

  ModelOption({required this.id, required this.info});
}

/// Display information for a model
class ModelDisplayInfo {
  final String name;
  final String description;
  final bool recommended;
  final String speed;
  final String quality;
  final int inputTokenLimit;
  final int outputTokenLimit;

  ModelDisplayInfo({
    required this.name,
    required this.description,
    required this.recommended,
    required this.speed,
    required this.quality,
    required this.inputTokenLimit,
    required this.outputTokenLimit,
  });
}
