import 'package:flutter_aira/src/models/conversion_extension.dart';

class ChatSessionInfo {
  ChatSessionInfo.fromJson(Map<String, dynamic> json)
      : chatId = json['chatId'],
        userId = json['userId'],
        createdAt = (json['createdAt'] as String).dateTimeZ;

  final int chatId;
  final int userId;
  final DateTime createdAt;
}

enum SenderRole {
  assistant,
  user;

  static SenderRole fromName(String name) {
    return SenderRole.values.byName(name.toLowerCase());
  }
}

class ChatMessageInfo {
  ChatMessageInfo.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        chatId = json['chatId'],
        senderId = json['senderId'],
        role = SenderRole.fromName(json['role']),
        message = json['message'],
        imageUrl = json['imageUrl'];

  final int id;
  final int chatId;
  final int senderId;
  final SenderRole role;
  final String? message;
  final String? imageUrl;
}
