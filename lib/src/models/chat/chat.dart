import '../../models/conversion_extension.dart';

import 'agent_feedback_info.dart';
import 'user_feedback_info.dart';

class ChatSessionInfo {
  ChatSessionInfo({
    required this.chatId,
    required this.userId,
    required this.createdAt,
    required this.messages,
  });

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
  const ChatMessageInfo({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.role,
    this.message,
    this.imageUrl,
    this.userFeedback,
    this.agentFeedback,
  });

  ChatMessageInfo.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        chatId = json['chatId'],
        senderId = json['senderId'],
        role = SenderRole.fromName(json['role']),
        message = json['message'],
        userFeedback = json['userFeedback'] != null
            ? UserFeedbackInfo.fromJson(json['userFeedback'])
            : null,
        agentFeedback = json['agentFeedback'] != null
            ? AgentFeedbackInfo.fromJson(json['agentFeedback'])
            : null,
        imageUrl = json['imageUrl'];

  final int id;
  final int chatId;
  final int senderId;
  final SenderRole role;
  final String? message;
  final String? imageUrl;
  final UserFeedbackInfo? userFeedback;
  final AgentFeedbackInfo? agentFeedback;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'role': role.name,
      'message': message,
      'imageUrl': imageUrl,
      'userFeedback': userFeedback?.toMap(),
      'agentFeedback': agentFeedback?.toMap(),
    };
  }

  ChatMessageInfo copyWith({
    int? id,
    int? chatId,
    int? senderId,
    SenderRole? role,
    String? message,
    String? imageUrl,
    UserFeedbackInfo? userFeedback,
    AgentFeedbackInfo? agentFeedback,
  }) {
    return ChatMessageInfo(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      role: role ?? this.role,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      userFeedback: userFeedback ?? this.userFeedback,
      agentFeedback: agentFeedback ?? this.agentFeedback,
    );
  }
}
