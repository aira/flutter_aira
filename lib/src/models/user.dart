import 'profile.dart';

class User {
  final int id;
  final String? email;
  final String firstName;
  final List<Language> languages;
  final String lastName;
  final List<String>? linkedAccounts;
  final String? phoneNumber;
  final List<Profile> profiles;

  User({
    required this.id,
    this.email,
    required this.firstName,
    required this.languages,
    required this.lastName,
    this.linkedAccounts,
    this.phoneNumber,
    required this.profiles,
  });

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        email = json['email'],
        firstName = json['firstName'] ?? '',
        languages = (json['language'] ?? [] as List<String>).map((v) => Language.fromString(v)).cast<Language>().toList(growable: false),
        lastName = json['lastName'] ?? '',
        linkedAccounts = (json['providers'] as List<dynamic>).map((json) => json['serviceName'] as String).toList(growable: false),
        phoneNumber = json['phoneNumber'],
        profiles = (json['accounts'] as List<dynamic>).map((e) => Profile.fromJson(e)).toList(growable: false);

  /// Keeping immutability of the class while providing a way to clone new instances of User with different values.
  User cloneWith({
    int? id,
    String? email,
    String? firstName,
    List<Language>? languages,
    String? lastName,
    List<String>? linkedAccounts,
    String? phoneNumber,
    List<Profile>? profiles,
  }) =>
      User(
        id: id ?? this.id,
        email: email ?? this.email,
        firstName: firstName ?? this.firstName,
        languages: languages ?? this.languages,
        lastName: lastName ?? this.lastName,
        linkedAccounts: linkedAccounts ?? this.linkedAccounts,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        profiles: profiles ?? this.profiles,
      );
}