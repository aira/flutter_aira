/// Information about user feedback.
class UserFeedbackInfo {
  /// Creates a new instance of [UserFeedbackInfo].
  const UserFeedbackInfo({
    required this.authorId,
    required this.rating,
    this.comment,
  });

  /// The ID of the author of the feedback which is the explorer.
  final int authorId;

  /// The rating for the feedback.
  /// 1: Good, -1: Bad
  final int rating;

  /// The comment for the feedback.
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
