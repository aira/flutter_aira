class Message {
  /// Whether the message was sent by the Explorer.
  final bool isLocal;

  /// The time at which the message was sent, in milliseconds since the Unix epoch.
  final int sentAt;

  /// The text of the message.
  final String text;

  /// The ID of the user who sent the message.
  final int userId;

  /// The ID of the message.
  final int messageId;

  /// Whether the message was sent by the Agent.
  bool get isRemote => !isLocal;

  /// The File Id of the stored file within history.
  String? fileId;

  /// The File Name of the stored file within history.
  String? fileName;

  Message({
    required this.isLocal,
    required this.sentAt,
    required this.text,
    required this.userId,
    required this.messageId,
    this.fileId,
    this.fileName,
  });
}
