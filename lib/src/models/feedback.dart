enum Rating {
  positive(1),
  neutral(0),
  negative(-1);

  final int _value;
  const Rating(this._value);

  int get value => _value;
  static Rating? fromValue(int? value) {
    if (null == value) {
      return null;
    }
    switch(value) {
      case 1: return positive;
      case 0: return neutral;
      case -1: return negative;
    }
    throw 'Unsupported Rating value: $value';
  }
  String get name => toString().split('.').last;
}

class Feedback {
  String? comment;
  Rating? rating;
  final Set<String> tags = {};

  Feedback();

  Feedback.fromJson(Map<String, dynamic> json)
      : comment = json['comment'],
        rating = Rating.fromValue(json['rating']) {
    List<dynamic> newTags = json['tags'] ?? [];
    tags.addAll(newTags.cast<String>().toList(growable: false));
  }

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

  AgentFeedback(): super();

  AgentFeedback.fromJson(Map<String, dynamic> json)
      : requestReview = json['requestReview'] ?? false,
        shareKudos = json['shareKudos'] ?? false,
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'requestReview': requestReview,
      'shareKudos': shareKudos,
    };
  }
}
