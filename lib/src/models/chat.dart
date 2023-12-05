class ChatSession {
  ChatSession.fromJson(Map<String, dynamic> json) : sessionId = json['sessionId'];

  final int sessionId;
}

enum AuthorRole {
  assistant,
  user,
}

class ChatMessage {
  ChatMessage.fromJson(Map<String, dynamic> json)
      : messageId = json['messageId'],
        role = AuthorRole.values.byName(json['role']),
        content = json['content'];

  final int messageId;
  final AuthorRole role;
  final String content;
}
