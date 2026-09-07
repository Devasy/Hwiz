/// Represents a single AI chat session (a conversation thread)
class AiChatSession {
  final int? id;
  final int? profileId;
  final String title; // Auto-generated from first user message
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  const AiChatSession({
    this.id,
    this.profileId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
  });

  AiChatSession copyWith({
    int? id,
    int? profileId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? messageCount,
  }) {
    return AiChatSession(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'profile_id': profileId,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AiChatSession.fromMap(Map<String, dynamic> map) {
    return AiChatSession(
      id: map['id'] as int?,
      profileId: map['profile_id'] as int?,
      title: map['title'] as String? ?? 'Chat',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      messageCount: map['message_count'] as int? ?? 0,
    );
  }
}

/// Represents a single message within a chat session
class AiChatMessage {
  final int? id;
  final int sessionId;
  final String role; // 'user' or 'model'
  final String text;
  final String? executedQuery; // SQL query used by the model
  final DateTime createdAt;

  const AiChatMessage({
    this.id,
    required this.sessionId,
    required this.role,
    required this.text,
    this.executedQuery,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'session_id': sessionId,
      'role': role,
      'text': text,
      'executed_query': executedQuery,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AiChatMessage.fromMap(Map<String, dynamic> map) {
    return AiChatMessage(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      role: map['role'] as String,
      text: map['text'] as String,
      executedQuery: map['executed_query'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert for Gemini API history format
  Map<String, dynamic> toApiContent() {
    return {
      'role': role,
      'parts': [
        {'text': text}
      ],
    };
  }
}
