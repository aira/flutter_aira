enum Rating {
  excellent(2),
  positive(1),
  neutral(0),
  negative(-1),
  disappointed(-2);

  final int _value;

  const Rating(this._value);

  int get value => _value;

  static Rating? fromValue(int? value) {
    if (null == value) {
      return null;
    }
    switch (value) {
      case 2:
        return excellent;
      case 1:
        return positive;
      case 0:
        return neutral;
      case -1:
        return negative;
      case -2:
        return disappointed;
    }
    throw 'Unsupported Rating value: $value';
  }

  String get name => toString().split('.').last;
}

class Feedback {
  String? comment;
  Rating? rating;

  Feedback({this.comment, this.rating});

  static Feedback? fromJson(Map<String, dynamic>? map) {
    if (map == null) return null;

    return Feedback(
      comment: map['comment'],
      rating: Rating.fromValue(map['rating']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment': comment,
      'rating': rating?.value,
    };
  }
}
