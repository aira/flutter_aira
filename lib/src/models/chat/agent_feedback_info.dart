import 'package:flutter_aira/src/models/conversion_extension.dart';

/// Information about the feedback provided by the Visual Interpreter.
class AgentFeedbackInfo {
  /// Creates a new instance of [AgentFeedbackInfo].
  const AgentFeedbackInfo({
    this.authorId,
    this.authorFirstName,
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
        authorFirstName = json['authorFirstName'],
        rating = json['rating'],
        textRating = json['textRating'],
        imageRating = json['imageRating'],
        comment = json['comment'],
        verifiedContent = json['verifiedContent'],
        state = AgentFeedbackState.fromValue(json['state']),
        requestedAt = (json['requestedAt'] as String?)?.dateTimeZ,
        updatedAt = (json['updatedAt'] as String?)?.dateTimeZ,
        analysis = json['analysis'];

  /// The ID of the author of the feedback which is the Visual Interpreter.
  final int? authorId;

  /// The first name of the author of the feedback which is the Visual Interpreter.
  final String? authorFirstName;

  /// The rating for the text content.
  /// 1: Good, -1: Bad
  final int? textRating;

  /// The rating for the image content.
  /// 1: Good, -1: Bad
  final int? imageRating;

  /// The verified content by the Visual Interpreter.
  final String? verifiedContent;

  /// The state of the feedback.
  final AgentFeedbackState state;

  /// The date and time when the feedback was requested.
  final DateTime? requestedAt;

  /// The date and time when the feedback was updated.
  final DateTime? updatedAt;
  final String? comment;
  final int? rating;
  final Map<String, dynamic>? analysis;

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorFirstName': authorFirstName,
      'rating': rating,
      'textRating': textRating,
      'imageRating': imageRating,
      'comment': comment,
      'verifiedContent': verifiedContent,
      'state': state.name,
      'requestedAt': requestedAt?.dateTimeStringZ,
      'updatedAt': updatedAt?.dateTimeStringZ,
      'analysis': analysis,
    };
  }
}

/// The state of the feedback.
/// The states can be found in the backend under https://github.com/aira/aira-backend-services/blob/main/api-models/src/main/resources/openapi/task-manager.yaml#L693-L697
enum AgentFeedbackState {
  pending('PENDING'),
  assigned('ASSIGNED'),
  started('STARTED'),
  completed('COMPLETED');

  final String value;

  const AgentFeedbackState(this.value);

  /// Gets the [AgentFeedbackState] from the given value.
  ///
  /// If the value is not found, [pending] is returned.
  static AgentFeedbackState fromValue(String? value) {
    return AgentFeedbackState.values
        .firstWhere((e) => e.value == value, orElse: () => pending);
  }
}
