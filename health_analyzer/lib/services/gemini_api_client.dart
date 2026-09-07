import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Ordered list of available Gemini models.
const kGeminiModels = [
  ('gemini-3.5-flash-lite', 'Gemini 3.5 Flash Lite (Recommended)'),
  ('gemini-3.5-flash',      'Gemini 3.5 Flash'),
  ('gemini-3.6-flash',      'Gemini 3.6 Flash'),
  ('gemini-3.7-flash',      'Gemini 3.7 Flash'),
  ('gemini-2.5-flash',      'Gemini 2.5 Flash'),
];

/// Default model is 3.5 Flash Lite for ultra-fast, high-precision responses.
const kDefaultGeminiModel = 'gemini-3.5-flash-lite';

/// Available thinking levels for Gemini 3.x models.
const kThinkingLevels = ['minimal', 'low', 'medium', 'high'];
const kDefaultThinkingLevel = 'minimal';

/// Returns thinking levels supported by [model].
List<String> supportedThinkingLevels(String model) {
  if (model.startsWith('gemini-2')) return const [];
  if (model == 'gemini-3.7-flash') return const ['low', 'medium', 'high'];
  return kThinkingLevels;
}

/// Clamps [level] to what [model] supports.
String clampThinkingLevel(String model, String level) {
  final supported = supportedThinkingLevels(model);
  if (supported.isEmpty || supported.contains(level)) return level;
  return supported.first;
}

/// Fallback model progression when quota limit is reached.
String? getFallbackModel(String currentModel) {
  switch (currentModel) {
    case 'gemini-3.7-flash':
      return 'gemini-3.6-flash';
    case 'gemini-3.6-flash':
      return 'gemini-3.5-flash';
    case 'gemini-3.5-flash':
      return 'gemini-3.5-flash-lite';
    case 'gemini-3.5-flash-lite':
      return 'gemini-2.5-flash';
    default:
      if (currentModel.startsWith('gemini-3')) {
        return 'gemini-3.5-flash-lite';
      }
      return null;
  }
}

/// Direct REST API Client for Google Gemini.
///
/// Bypasses SDK limitations to support Gemini >= 3.5 with thinkingConfig,
/// custom function calling, SSE streaming, and quota-limit automatic fallback.
class GeminiApiClient {
  static const String _apiBase =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static const int _kMaxRetries = 3;
  static const int _kMaxRetriesWithServerDelay = 4;

  static bool _isRetryableStatus(int code) =>
      code == 429 || (code >= 500 && code < 600);

  static Duration _retryBackoff(int attempt) =>
      Duration(milliseconds: 500 * (1 << attempt));

  static bool _isDailyQuotaExhausted(String body) {
    return body.contains('GenerateRequestsPerDay') ||
        body.contains('free_tier_requests') ||
        body.contains('quota_limit_exceeded');
  }

  static Duration? _extractRetryDelay(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        final errMap = decoded['error'] as Map;
        final details = errMap['details'];
        if (details is List) {
          for (final item in details) {
            if (item is Map && item['retryDelay'] is String) {
              final delayStr =
                  (item['retryDelay'] as String).replaceAll('s', '').trim();
              final seconds = double.tryParse(delayStr);
              if (seconds != null && seconds > 0) {
                final ms = (seconds * 1000).ceil() + 350;
                return Duration(milliseconds: ms.clamp(500, 45000));
              }
            }
          }
        }
        final message = errMap['message'];
        if (message is String) {
          final match = RegExp(r'retry in\s+([\d.]+)\s*s', caseSensitive: false)
              .firstMatch(message);
          if (match != null) {
            final seconds = double.tryParse(match.group(1)!);
            if (seconds != null && seconds > 0) {
              final ms = (seconds * 1000).ceil() + 350;
              return Duration(milliseconds: ms.clamp(500, 45000));
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static String _errorMessage(int code, String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        final msg = (decoded['error'] as Map)['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    } catch (_) {}
    return 'API request failed (HTTP $code).';
  }

  static Map<String, dynamic> _buildThinkingConfig(String model, String level) {
    if (model.startsWith('gemini-2')) {
      return {'thinkingBudget': 0};
    }
    final clamped = clampThinkingLevel(model, level);
    return {'thinkingLevel': clamped};
  }

  static const Duration _kRequestTimeout = Duration(seconds: 90);

  /// Generate content (non-streaming, JSON or text)
  static Future<Map<String, dynamic>> generateContent({
    required String apiKey,
    required String model,
    required List<Map<String, dynamic>> contents,
    String? systemInstruction,
    List<Map<String, dynamic>>? tools,
    bool jsonMode = false,
    String thinkingLevel = kDefaultThinkingLevel,
    double temperature = 0.2,
    int maxOutputTokens = 8192,
  }) async {
    String currentModel = model;
    String currentThinkingLevel = thinkingLevel;

    for (var attempt = 0;; attempt++) {
      // Rebuild body inside loop so fallback model gets correct thinkingConfig
      final body = {
        'contents': contents,
        if (systemInstruction != null && systemInstruction.isNotEmpty)
          'systemInstruction': {
            'parts': [
              {'text': systemInstruction}
            ]
          },
        if (tools != null && tools.isNotEmpty) 'tools': tools,
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxOutputTokens,
          'thinkingConfig': _buildThinkingConfig(
            currentModel,
            currentThinkingLevel,
          ),
          if (jsonMode) 'responseMimeType': 'application/json',
        },
      };

      // Key goes in header, NOT the URI, to avoid leaking it in error messages
      final uri = Uri.parse('$_apiBase/$currentModel:generateContent');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: jsonEncode(body),
          )
          .timeout(_kRequestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      // Check daily quota fallback
      if (_isDailyQuotaExhausted(response.body)) {
        final fallback = getFallbackModel(currentModel);
        if (fallback != null) {
          debugPrint('⚠️ Daily quota exhausted for $currentModel. Falling back to $fallback');
          currentModel = fallback;
          currentThinkingLevel = clampThinkingLevel(currentModel, currentThinkingLevel);
          continue;
        }
      }

      final customDelay = _extractRetryDelay(response.body);
      if (_isRetryableStatus(response.statusCode) &&
          (attempt < _kMaxRetries ||
              (customDelay != null && attempt < _kMaxRetriesWithServerDelay))) {
        final delay = customDelay ?? _retryBackoff(attempt);
        await Future.delayed(delay);
        continue;
      }

      throw Exception(_errorMessage(response.statusCode, response.body));
    }
  }

  /// Extracts combined non-thought text from response
  static String extractText(Map<String, dynamic> response) {
    final candidates = response['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) return '';
    final first = candidates.first as Map<String, dynamic>;
    final content = first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>? ?? [];

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map<String, dynamic> &&
          part.containsKey('text') &&
          part['thought'] != true) {
        buffer.write(part['text'] as String? ?? '');
      }
    }
    return buffer.toString();
  }

  /// Streams chat reply with multi-turn tool calling support
  static Stream<String> streamChatWithTools({
    required String apiKey,
    required String initialModel,
    required String userMessage,
    required String systemPrompt,
    required List<Map<String, dynamic>> history,
    List<Map<String, dynamic>>? tools,
    Future<Map<String, dynamic>> Function(String name, Map<String, dynamic> args)?
        onToolCall,
    int maxToolRounds = 5,
    String thinkingLevel = kDefaultThinkingLevel,
  }) async* {
    String currentModel = initialModel;
    String currentThinkingLevel = thinkingLevel;

    final contents = <Map<String, dynamic>>[
      ...history,
      {
        'role': 'user',
        'parts': [
          {'text': userMessage}
        ]
      },
    ];

    for (var round = 0; round < maxToolRounds; round++) {
      final rawModelParts = <Map<String, dynamic>>[];
      final calls = <Map<String, dynamic>>[];

      http.Client client = http.Client();
      http.StreamedResponse? streamed;

      try {
        for (var attempt = 0;; attempt++) {
          // Rebuild body inside retry loop so fallback model gets correct thinkingConfig
          final body = {
            'contents': contents,
            if (systemPrompt.isNotEmpty)
              'systemInstruction': {
                'parts': [
                  {'text': systemPrompt}
                ]
              },
            if (tools != null && tools.isNotEmpty) 'tools': tools,
            'generationConfig': {
              'temperature': 0.3,
              'thinkingConfig': _buildThinkingConfig(
                currentModel,
                currentThinkingLevel,
              ),
            },
          };

          // Key goes in header, NOT the URI
          final uri = Uri.parse(
            '$_apiBase/$currentModel:streamGenerateContent?alt=sse',
          );
          final req = http.Request('POST', uri)
            ..headers['Content-Type'] = 'application/json'
            ..headers['x-goog-api-key'] = apiKey
            ..body = jsonEncode(body);

          final resp = await client.send(req).timeout(_kRequestTimeout);
          if (resp.statusCode == 200) {
            streamed = resp;
            break;
          }

          final err = await resp.stream.bytesToString();
          if (_isDailyQuotaExhausted(err)) {
            final fallback = getFallbackModel(currentModel);
            if (fallback != null) {
              debugPrint('⚠️ Stream quota hit for $currentModel. Fallback to $fallback');
              currentModel = fallback;
              currentThinkingLevel = clampThinkingLevel(currentModel, currentThinkingLevel);
              client.close();
              client = http.Client();
              continue;
            }
          }

          final customDelay = _extractRetryDelay(err);
          if (_isRetryableStatus(resp.statusCode) &&
              (attempt < _kMaxRetries ||
                  (customDelay != null && attempt < _kMaxRetriesWithServerDelay))) {
            client.close();
            final delay = customDelay ?? _retryBackoff(attempt);
            await Future.delayed(delay);
            client = http.Client();
            continue;
          }

          throw Exception(_errorMessage(resp.statusCode, err));
        }

        // Process SSE stream
        void parseLine(String line) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('data:')) return;
          final jsonStr = trimmed.substring(5).trim();
          if (jsonStr.isEmpty || jsonStr == '[DONE]') return;
          try {
            final map = jsonDecode(jsonStr) as Map<String, dynamic>;
            final candidates = map['candidates'] as List<dynamic>? ?? [];
            for (final raw in candidates) {
              final c = raw as Map<String, dynamic>;
              final content = c['content'] as Map<String, dynamic>?;
              final parts = content?['parts'] as List<dynamic>? ?? [];
              for (final part in parts) {
                if (part is! Map<String, dynamic>) continue;
                rawModelParts.add(part);
                if (part.containsKey('functionCall')) {
                  calls.add(part['functionCall'] as Map<String, dynamic>);
                }
              }
            }
          } catch (_) {}
        }

        final lineBuf = StringBuffer();
        await for (final chunk in streamed!.stream.transform(utf8.decoder)) {
          lineBuf.write(chunk);
          final text = lineBuf.toString();
          final lines = text.split('\n');
          lineBuf
            ..clear()
            ..write(lines.last);

          for (var i = 0; i < lines.length - 1; i++) {
            final line = lines[i].trim();
            if (!line.startsWith('data:')) continue;
            final jsonStr = line.substring(5).trim();
            if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;

            try {
              final map = jsonDecode(jsonStr) as Map<String, dynamic>;
              final candidates = map['candidates'] as List<dynamic>? ?? [];
              for (final raw in candidates) {
                final c = raw as Map<String, dynamic>;
                final content = c['content'] as Map<String, dynamic>?;
                final parts = content?['parts'] as List<dynamic>? ?? [];
                for (final part in parts) {
                  if (part is! Map<String, dynamic>) continue;
                  rawModelParts.add(part);

                  if (part.containsKey('text') && part['thought'] != true) {
                    final t = part['text'] as String? ?? '';
                    if (t.isNotEmpty) yield t;
                  }

                  if (part.containsKey('functionCall')) {
                    calls.add(part['functionCall'] as Map<String, dynamic>);
                  }
                }
              }
            } catch (_) {}
          }
        }

        // Flush any remaining buffer content after stream ends
        final remaining = lineBuf.toString().trim();
        if (remaining.isNotEmpty) parseLine(remaining);

      } finally {
        // Always close the client, even if the stream threw
        client.close();
      }

      // If no function call requested, streaming finished
      if (calls.isEmpty || onToolCall == null) {
        return;
      }

      // Add model response with raw parts to contents
      contents.add({'role': 'model', 'parts': rawModelParts});

      // Execute function calls
      final responseParts = <Map<String, dynamic>>[];
      for (final call in calls) {
        final name = call['name'] as String? ?? '';
        final args = (call['args'] as Map<String, dynamic>? ?? {})
            .cast<String, dynamic>();

        try {
          final result = await onToolCall(name, args);
          responseParts.add({
            'functionResponse': {
              'name': name,
              'response': result,
            }
          });
        } catch (e) {
          responseParts.add({
            'functionResponse': {
              'name': name,
              'response': {'error': '$e'},
            }
          });
        }
      }

      contents.add({'role': 'user', 'parts': responseParts});
    }

    yield '\n\n_(Analysis completed after maximum tool rounds.)_';
  }

  /// Helper to build multimodal content with text and base64 file data
  static Map<String, dynamic> buildMultimodalUserTurn({
    required String text,
    required Uint8List fileBytes,
    required String mimeType,
  }) {
    return {
      'role': 'user',
      'parts': [
        {'text': text},
        {
          'inlineData': {
            'mimeType': mimeType,
            'data': base64Encode(fileBytes),
          }
        }
      ]
    };
  }
}
