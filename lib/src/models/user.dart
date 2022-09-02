class User {
  int accountId;
  String accountName;
  String accountType;

  User.fromJson(Map<String, dynamic> json)
      : accountId = int.parse(json['accounts']['account']['id']),
        accountName = json['accounts']['account']['name'],
        accountType =json['accounts']['userType'];
}

class UserDetails {
  List<User>? details;

  UserDetails.fromJson(Map<String, dynamic> json)
      : details = (json['details'] as List<dynamic>).map((details) => User.fromJson(details)).toList(growable: false);
}
