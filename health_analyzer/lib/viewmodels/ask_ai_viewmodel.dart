import 'package:flutter/foundation.dart';
import '../services/ask_ai_service.dart';

class AskAiChatMessage {
  final String role; // 'user' or 'model'
  final String text;
  final String? executedQuery;
  final DateTime timestamp;

  AskAiChatMessage({
    required this.role,
    required this.text,
    this.executedQuery,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toApiContent() {
    return {
      'role': role,
      'parts': [
        {'text': text}
      ]
    };
  }
}

class AskAiViewModel extends ChangeNotifier {
  final AskAiService _askAiService = AskAiService();

  final List<AskAiChatMessage> _messages = [];
  bool _isLoading = false;
  String _streamingText = '';
  String? _activeToolQuery;

  List<AskAiChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String get streamingText => _streamingText;
  String? get activeToolQuery => _activeToolQuery;

  static const List<String> suggestions = [
    'Summarize my latest blood report',
    'Are any parameters abnormal across my tests?',
    'Show my Cholesterol and Lipid profile trend',
    'How has my Fasting Blood Sugar changed over time?',
    'Compare my last two reports for any changes',
  ];

  Future<void> sendMessage(
    String text, {
    String? activeProfileName,
    int? activeProfileId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _isLoading = true;
    _streamingText = '';
    _activeToolQuery = null;

    // Add user message
    _messages.add(AskAiChatMessage(role: 'user', text: trimmed));
    notifyListeners();

    // Prepare API history
    final history = _messages
        .take(_messages.length - 1)
        .map((m) => m.toApiContent())
        .toList();

    final buffer = StringBuffer();
    String? capturedQuery;

    try {
      await for (final chunk in _askAiService.streamReply(
        userMessage: trimmed,
        history: history,
        activeProfileName: activeProfileName,
        activeProfileId: activeProfileId,
        onToolExecuting: (query) {
          capturedQuery = query;
          _activeToolQuery = query;
          notifyListeners();
        },
      )) {
        buffer.write(chunk);
        _streamingText = buffer.toString();
        notifyListeners();
      }

      final finalReply = buffer.toString().trim();
      if (finalReply.isNotEmpty) {
        _messages.add(
          AskAiChatMessage(
            role: 'model',
            text: finalReply,
            executedQuery: capturedQuery,
          ),
        );
      }
    } catch (e) {
      _messages.add(
        AskAiChatMessage(
          role: 'model',
          text: 'Error generating response: $e',
        ),
      );
    } finally {
      _isLoading = false;
      _streamingText = '';
      _activeToolQuery = null;
      notifyListeners();
    }
  }

  void clearConversation() {
    _messages.clear();
    _streamingText = '';
    _activeToolQuery = null;
    _isLoading = false;
    notifyListeners();
  }
}
