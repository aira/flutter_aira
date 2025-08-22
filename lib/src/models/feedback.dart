enum Rating {
  excellent(2),
  positive(1),
  neutral(0),
  negative(-1),
  terrible(-2);

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
        return terrible;
    }
    throw 'Unsupported Rating value: $value';
  }

  static Rating? fromStars(int? starIndex) {
    if (starIndex == null) return null;
    switch (starIndex) {
      case 0:
        return Rating.terrible; // Maps to -2 (most negative)
      case 1:
        return Rating.negative; // Maps to -1
      case 2:
        return Rating.neutral; // Maps to 0 (neutral)
      case 3:
        return Rating.positive; // Maps to +1 (positive)
      case 4:
        return Rating.excellent; // Maps to +2 (most positive)
      default:
        throw ArgumentError('Invalid star rating: $starIndex');
    }
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
