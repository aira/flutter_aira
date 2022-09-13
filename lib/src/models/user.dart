import 'profile.dart';

class User {
  final int id;
  final String firstName;
  final String lastName;
  final List<Profile> profiles;

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        firstName = json['firstName'],
        lastName = json['lastName'],
        profiles = (json['accounts'] as List<dynamic>).map((e) => Profile.fromJson(e)).toList(growable: false);
}