import 'profile.dart';

class User {
  final int id;
  final String firstName;
  final String lastName;
  final List<Profile> profiles;
  final bool isGuest;

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        firstName = json['firstName'],
        lastName = json['lastName'] ?? '',
        isGuest = json['guest'] ?? true, // This information comes from table `user_property_value` and defaults to true in platform (see SubscriptionManager.isGuestSafe(userId))
        profiles = (json['accounts'] as List<dynamic>).map((e) => Profile.fromJson(e)).toList(growable: false);
}