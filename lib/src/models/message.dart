class Message {
  /// The text of the message.
  final String text;

  /// The time at which the message was sent, in milliseconds since the Unix epoch.
  final int sentAt;

  /// Whether the message was sent by the Agent.
  final bool sentByAgent;

  /// The ID of the user who sent the message.
  final int userId;

  Message(this.text, this.sentAt, this.sentByAgent, this.userId);
}
