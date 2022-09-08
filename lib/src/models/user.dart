enum ProfileType { primary, business }

extension ProfileTypeExtension on ProfileType {
  get name => toString().split('.').last;
}

class Profile {
  int accountId;
  String accountName;
  ProfileType type;

  Profile.fromJson(Map<String, dynamic> json)
      : accountId = json['account']['id'],
        accountName = json['account']['name'],
        type = ProfileType.values.firstWhere((e) => e.name == json['userType']);
}

class User {
  String firstName;
  String lastName;
  List<Profile> profiles;

  User.fromJson(Map<String, dynamic> json)
      : firstName = json['firstName'],
        lastName = json['lastName'],
        profiles = (json['accounts'] as List<dynamic>).map((e) => Profile.fromJson(e)).toList(growable: false);
}