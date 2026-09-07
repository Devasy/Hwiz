import 'package:flutter/foundation.dart';
import '../models/chat_history.dart';
import '../services/ask_ai_service.dart';
import '../services/database_helper.dart';

class AskAiViewModel extends ChangeNotifier {
  final AskAiService _askAiService = AskAiService();
  final DatabaseHelper _db = DatabaseHelper.instance;

  // ── Current session state ──────────────────────────────────────────────
  int? _currentSessionId;
  final List<AiChatMessage> _messages = [];
  bool _isLoading = false;
  String _streamingText = '';
  String? _activeToolQuery;

  /// Monotonically increasing token — incremented on every clear/new conversation.
  /// Each [sendMessage] captures its token at launch; callbacks check it before
  /// mutating state to prevent stale replies from corrupting a fresh conversation.
  int _generationToken = 0;

  // ── History list state ─────────────────────────────────────────────────
  List<AiChatSession> _sessions = [];
  bool _sessionsLoaded = false;

  // ── Getters ────────────────────────────────────────────────────────────
  int? get currentSessionId => _currentSessionId;
  List<AiChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String get streamingText => _streamingText;
  String? get activeToolQuery => _activeToolQuery;
  List<AiChatSession> get sessions => List.unmodifiable(_sessions);

  static const List<String> suggestions = [
    'Summarize my latest blood report',
    'Are any parameters abnormal across my tests?',
    'Show my Cholesterol and Lipid profile trend',
    'How has my Fasting Blood Sugar changed over time?',
    'Compare my last two reports for any changes',
  ];

  // ── History loading ────────────────────────────────────────────────────

  Future<void> loadSessions({int? profileId}) async {
    _sessions = await _db.getChatSessions(profileId: profileId);
    _sessionsLoaded = true;
    notifyListeners();
  }

  /// Load a previously saved session into the active chat
  Future<void> restoreSession(int sessionId) async {
    final msgs = await _db.getChatMessages(sessionId);
    _currentSessionId = sessionId;
    _messages
      ..clear()
      ..addAll(msgs);
    _streamingText = '';
    _activeToolQuery = null;
    _isLoading = false;
    notifyListeners();
  }

  // ── Messaging ─────────────────────────────────────────────────────────

  Future<void> sendMessage(
    String text, {
    String? activeProfileName,
    int? activeProfileId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    // Capture the generation token for this request.
    // If the conversation is cleared mid-flight, _generationToken will be
    // incremented and all callbacks below will be silently discarded.
    final myToken = _generationToken;

    _isLoading = true;
    _streamingText = '';
    _activeToolQuery = null;

    // Create a new DB session on first message
    if (_currentSessionId == null) {
      final title = trimmed.length > 60 ? '${trimmed.substring(0, 57)}…' : trimmed;
      _currentSessionId = await _db.createChatSession(
        title: title,
        profileId: activeProfileId,
      );
    }

    // Persist + display user message
    final userMsg = AiChatMessage(
      sessionId: _currentSessionId!,
      role: 'user',
      text: trimmed,
      createdAt: DateTime.now(),
    );
    await _db.addChatMessage(userMsg);
    _messages.add(userMsg);
    notifyListeners();

    // Build history for API (all but the last user message)
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
          if (_generationToken != myToken) return; // stale
          capturedQuery = query;
          _activeToolQuery = query;
          notifyListeners();
        },
      )) {
        if (_generationToken != myToken) return; // stale — discard silently
        buffer.write(chunk);
        _streamingText = buffer.toString();
        notifyListeners();
      }

      if (_generationToken != myToken) return; // cleared before completion

      final finalReply = buffer.toString().trim();
      if (finalReply.isNotEmpty) {
        final modelMsg = AiChatMessage(
          sessionId: _currentSessionId!,
          role: 'model',
          text: finalReply,
          executedQuery: capturedQuery,
          createdAt: DateTime.now(),
        );
        await _db.addChatMessage(modelMsg);
        _messages.add(modelMsg);
      }
    } catch (e) {
      if (_generationToken != myToken) return; // stale error — discard
      final errMsg = AiChatMessage(
        sessionId: _currentSessionId!,
        role: 'model',
        text: 'Error generating response: $e',
        createdAt: DateTime.now(),
      );
      await _db.addChatMessage(errMsg);
      _messages.add(errMsg);
    } finally {
      if (_generationToken == myToken) {
        _isLoading = false;
        _streamingText = '';
        _activeToolQuery = null;
        notifyListeners();
      }
    }

    // Refresh the sessions list so the history panel stays current
    if (_sessionsLoaded) {
      _sessions = await _db.getChatSessions();
      notifyListeners();
    }
  }

  /// Start a fresh conversation (does NOT delete the old session from DB)
  void startNewConversation() {
    _generationToken++; // invalidate any in-flight stream callbacks
    _currentSessionId = null;
    _messages.clear();
    _streamingText = '';
    _activeToolQuery = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Clear in-memory messages only (back-compat; does NOT delete DB session)
  void clearConversation() => startNewConversation();

  // ── History management ────────────────────────────────────────────────

  Future<void> deleteSession(int sessionId) async {
    await _db.deleteChatSession(sessionId);
    _sessions.removeWhere((s) => s.id == sessionId);
    // If we just deleted the active session, reset current state
    if (_currentSessionId == sessionId) {
      _currentSessionId = null;
      _messages.clear();
    }
    notifyListeners();
  }

  Future<void> deleteAllSessions({int? profileId}) async {
    await _db.deleteAllChatSessions(profileId: profileId);
    _sessions.clear();
    _currentSessionId = null;
    _messages.clear();
    notifyListeners();
  }
}
