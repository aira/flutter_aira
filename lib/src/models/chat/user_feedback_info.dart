class UserFeedbackInfo {
  const UserFeedbackInfo({
    required this.authorId,
    required this.rating,
    this.comment,
  });

  final int authorId;
  final int rating;
  final String? comment;

  UserFeedbackInfo.fromJson(Map<String, dynamic> json)
      : authorId = json['authorId'],
        rating = json['rating'],
        comment = json['comment'];

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'rating': rating,
      'comment': comment,
    };
  }
}
