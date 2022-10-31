import 'profile.dart';

class User {
  final int id;
  final String? email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final List<Profile> profiles;

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        email = json['email'],
        firstName = json['firstName'],
        lastName = json['lastName'] ?? '',
        phoneNumber = json['phoneNumber'],
        profiles = (json['accounts'] as List<dynamic>).map((e) => Profile.fromJson(e)).toList(growable: false);
}