import 'package:flutter_aira/src/models/chat/chat_feedback_info.dart';
import 'package:flutter_aira/src/models/conversion_extension.dart';

class ChatSessionInfo {
  ChatSessionInfo.temp()
      : chatId = 0,
        userId = 0,
        createdAt = DateTime.now(),
        messages = [];

  ChatSessionInfo.fromJson(Map<String, dynamic> json)
      : chatId = json['chatId'],
        userId = json['userId'],
        createdAt = (json['createdAt'] as String).dateTimeZ,
        messages = json['messages'] != null
            ? (json['messages'] as List)
                .map((e) => ChatMessageInfo.fromJson(e))
                .toList()
            : [];

  final int chatId;
  final int userId;
  final DateTime createdAt;
  List<ChatMessageInfo> messages;
}

enum SenderRole {
  assistant,
  user;

  static SenderRole fromName(String name) {
    return SenderRole.values.byName(name.toLowerCase());
  }
}

class ChatMessageInfo {
  ChatMessageInfo.temp({required this.role, this.message, this.imageUrl})
      : id = 0,
        chatId = 0,
        senderId = 0,
        userFeedback = null;

  ChatMessageInfo.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        chatId = json['chatId'],
        senderId = json['senderId'],
        role = SenderRole.fromName(json['role']),
        message = json['message'],
        userFeedback = json['userFeedback'] != null
            ? ChatFeedbackInfo.fromJson(json['userFeedback'])
            : null,
        imageUrl = json['imageUrl'];

  final int id;
  final int chatId;
  final int senderId;
  final SenderRole role;
  final String? message;
  final String? imageUrl;
  final ChatFeedbackInfo? userFeedback;
}
