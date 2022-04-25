class Message {
  /// The text of the message.
  final String text;

  /// The time at which the message was sent, in milliseconds since the Unix epoch.
  final int sentAt;

  /// The ID of the service request during which the message was sent.
  final int serviceRequestId;

  /// The ID of the user who sent the message.
  final int userId;

  Message(this.text, this.sentAt, this.serviceRequestId, this.userId);
}
