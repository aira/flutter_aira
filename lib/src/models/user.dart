import 'profile.dart';

enum LanguageType {
  english,
  french,
  spanish,
  ;

  static LanguageType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ENGLISH': return LanguageType.english;
      case 'FRENCH': return LanguageType.french;
      case 'SPANISH': return LanguageType.spanish;
      default: throw UnimplementedError('Unsupported language: $value');
    }
  }
  String get name => toString().split('.').last;
}

class User {
  final int id;
  final String firstName;
  final List<Language> languages;
  final String lastName;
  final List<Profile> profiles;
  final bool isGuest;

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        firstName = json['firstName'],
        languages =
            (json['language'] ?? [] as List<String>).map((v) => LanguageType.fromString(v)).toList(growable: false),
        lastName = json['lastName'] ?? '',
        isGuest = json['guest'] ?? true, // This information comes from table `user_property_value` and defaults to true in platform (see SubscriptionManager.isGuestSafe(userId))
        profiles = (json['accounts'] as List<dynamic>).map((e) => Profile.fromJson(e)).toList(growable: false);
}