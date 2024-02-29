import 'package:flutter_aira/src/models/conversion_extension.dart';

import 'agent_feedback_info.dart';
import 'user_feedback_info.dart';

/// Information about a chat session.
class ChatSessionInfo {
  /// Creates a new instance of [ChatSessionInfo].
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

  /// The ID of the chat session.
  final int chatId;

  /// The ID of the user.
  final int userId;

  /// The date and time when the chat session was created.
  final DateTime createdAt;

  /// The list of messages in the chat session.
  List<ChatMessageInfo> messages;
}

/// The role of the sender of a chat message.
enum SenderRole {
  assistant,
  user;

  /// Gets [SenderRole] from the given name.
  static SenderRole fromName(String name) {
    return SenderRole.values.byName(name.toLowerCase());
  }
}

/// Information about a chat message.
class ChatMessageInfo {
  /// Creates a new instance of [ChatMessageInfo].
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

  /// The ID of the chat message.
  final int id;

  /// The ID of the chat session.
  final int chatId;

  /// The ID of the sender.
  final int senderId;

  /// The role of the sender.
  final SenderRole role;

  /// The message content.
  final String? message;

  /// The URL of the image.
  final String? imageUrl;

  /// The user feedback.
  final UserFeedbackInfo? userFeedback;

  /// The agent feedback.
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
