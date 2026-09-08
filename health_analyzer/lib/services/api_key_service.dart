import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'dart:async';
import 'gemini_api_client.dart';

/// Service to manage Gemini API key storage, validation, and retrieval
class ApiKeyService {
  static const String _apiKeyStorageKey = 'gemini_api_key';
  final FlutterSecureStorage _secureStorage;

  ApiKeyService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Save API key to secure storage
  Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyStorageKey, value: apiKey);
  }

  /// Retrieve API key from secure storage
  Future<String?> getApiKey() async {
    return await _secureStorage.read(key: _apiKeyStorageKey);
  }

  /// Delete API key from secure storage
  Future<void> deleteApiKey() async {
    await _secureStorage.delete(key: _apiKeyStorageKey);
  }

  /// Check if API key exists in storage
  Future<bool> hasApiKey() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Validate API key by making a test request to Gemini API
  /// Returns a tuple: (isValid, errorMessage)
  Future<(bool, String?)> validateApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      return (false, 'API key cannot be empty');
    }

    try {
      // Test the API key with a simple request using Gemini 3.5 Flash Lite
      final response = await GeminiApiClient.generateContent(
        apiKey: apiKey,
        model: 'gemini-3.5-flash-lite',
        contents: [
          {
            'role': 'user',
            'parts': [
              {'text': 'Hello'}
            ]
          }
        ],
        maxOutputTokens: 10,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );

      final text = GeminiApiClient.extractText(response);
      if (text.isNotEmpty) {
        return (true, null);
      } else {
        return (false, 'Invalid response from API. Please check your key');
      }
    } on SocketException catch (e) {
      // Network connectivity issues
      if (e.osError?.errorCode == 7 ||
          e.message.contains('Failed host lookup')) {
        return (
          false,
          'Unable to reach Google AI servers. Please check:\n'
              '• Your internet connection is active\n'
              '• You\'re not behind a restrictive firewall\n'
              '• DNS resolution is working'
        );
      }
      return (
        false,
        'Network error: Unable to connect. Please check your internet connection'
      );
    } on TimeoutException catch (_) {
      return (
        false,
        'Connection timeout. Please check your internet connection and try again'
      );
    } catch (e) {
      final errorStr = e.toString();

      if (errorStr.contains('API key not valid') ||
          errorStr.contains('invalid_api_key') ||
          errorStr.contains('API_KEY_INVALID') ||
          errorStr.contains('400')) {
        return (false, 'Invalid API key. Please check your key and try again');
      } else if (errorStr.contains('quota') ||
          errorStr.contains('QUOTA') ||
          errorStr.contains('429')) {
        return (false, 'API key is valid but quota exceeded. Try again later');
      } else if (errorStr.contains('SocketException') ||
          errorStr.contains('Failed host lookup') ||
          errorStr.contains('ClientException')) {
        return (
          false,
          'Network connection error. Please check your internet connection and try again'
        );
      }

      return (
        false,
        'Validation error: Unable to verify API key ($errorStr)'
      );
    }
  }

  /// Validate and save API key in one operation
  Future<(bool, String?)> validateAndSaveApiKey(String apiKey) async {
    final (isValid, errorMessage) = await validateApiKey(apiKey);

    if (isValid) {
      await saveApiKey(apiKey);
      return (true, 'API key saved successfully');
    } else {
      return (false, errorMessage);
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
}
