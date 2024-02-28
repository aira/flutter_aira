import '../../models/conversion_extension.dart';

class AgentFeedbackInfo {
  const AgentFeedbackInfo({
    this.authorId,
    this.rating,
    this.textRating,
    this.imageRating,
    this.comment,
    this.verifiedContent,
    required this.state,
    required this.requestedAt,
    this.updatedAt,
    this.analysis,
  });

  AgentFeedbackInfo.fromJson(Map<String, dynamic> json)
      : authorId = json['authorId'],
        rating = json['rating'],
        textRating = json['textRating'],
        imageRating = json['imageRating'],
        comment = json['comment'],
        verifiedContent = json['verifiedContent'],
        state = AgentFeedbackState.fromValue(json['state']),
        requestedAt = (json['requestedAt'] as String).dateTimeZ,
        updatedAt = (json['updatedAt'] as String?)?.dateTimeZ,
        analysis = json['analysis'];

  final int? authorId;
  final int? rating;
  final int? textRating;
  final int? imageRating;
  final String? comment;
  final String? verifiedContent;
  final AgentFeedbackState state;
  final DateTime requestedAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? analysis;

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'rating': rating,
      'textRating': textRating,
      'imageRating': imageRating,
      'comment': comment,
      'verifiedContent': verifiedContent,
      'state': state.name,
      'requestedAt': requestedAt.dateTimeStringZ,
      'updatedAt': updatedAt?.dateTimeStringZ,
      'analysis': analysis,
    };
  }
}

enum AgentFeedbackState {
  pending('PENDING'),
  inProgress('IN_PROGRESS'),
  completed('COMPLETED');

  final String value;

  const AgentFeedbackState(this.value);

  static AgentFeedbackState fromValue(String value) {
    return AgentFeedbackState.values.firstWhere((e) => e.value == value);
  }
}
