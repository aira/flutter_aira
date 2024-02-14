class ChatFeedbackInfo {
  final String authorId;
  final int rating;
  final String? comment;

  ChatFeedbackInfo({required this.authorId, required this.rating, this.comment});

  factory ChatFeedbackInfo.fromJson(Map<String, dynamic> json) {
    return ChatFeedbackInfo(
      authorId: json['authorId'],
      rating: json['rating'],
      comment: json['comment'],
    );
  }
}
