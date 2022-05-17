enum Rating {
  positive,
  neutral,
  negative,
}

extension RatingExtension on Rating {
  get name => toString().split('.').last;

  int get value {
    switch (this) {
      case Rating.positive:
        return 1;
      case Rating.negative:
        return -1;
      default:
        return 0;
    }
  }
}

class Feedback {
  String? comment;
  Rating? rating;
  final Set<String> tags = {};

  Map<String, dynamic> toJson() {
    return {
      'comment': comment,
      'rating': rating?.value,
      'tags': tags.toList(growable: false),
    };
  }
}

class AgentFeedback extends Feedback {
  bool requestReview = false;
  bool shareKudos = false;

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'requestReview': requestReview,
      'shareKudos': shareKudos,
    };
  }
}
