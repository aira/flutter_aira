// ignore_for_file: constant_identifier_names

import 'account.dart';

enum Language {
  English,
  French,
  Spanish,
}

extension LanguageExtension on Language {
  get name => toString().split('.').last;
}

enum ProfileType {
  /// A user linked to a business account.
  business,

  /// The account owner.
  primary,

  /// A user sharing the minutes of an individual account.
  secondary;

  static ProfileType fromName(String name) {
    return ProfileType.values.byName(name.toLowerCase());
  }
}

class Profile {
  final Account account;
  final ProfileType type;

  Profile.fromJson(Map<String, dynamic> json)
      : account = Account.fromJson(json['account']),
        type = ProfileType.fromName(json['userType']);
}
