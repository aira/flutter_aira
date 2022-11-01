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
  final String? email;
  final String firstName;
  final List<Language> languages;
  final String lastName;
  final String? phoneNumber;
  final List<Profile> profiles;

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        email = json['email'],
        firstName = json['firstName'],
        languages =
            (json['language'] ?? [] as List<String>).map((v) => LanguageType.fromString(v)).toList(growable: false),
        lastName = json['lastName'] ?? '',
        phoneNumber = json['phoneNumber'],
        profiles = (json['accounts'] as List<dynamic>).map((e) => Profile.fromJson(e)).toList(growable: false);
}