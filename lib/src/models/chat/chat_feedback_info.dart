class ChatFeedbackInfo {
  final int authorId;
  final int rating;
  final String? comment;

  ChatFeedbackInfo(
      {required this.authorId, required this.rating, this.comment});

  ChatFeedbackInfo.fromJson(Map<String, dynamic> json)
      : authorId = json['authorId'],
        rating = json['rating'],
        comment = json['comment'];
}
