/// Publicly available properties of a user. These properties can be read or
/// updated through [PlatformClient.getUserProperty] and
/// [PlatformClient.setUserProperty].
enum UserProperty {
  firstName,
  lastName,
  preferredLang,
  showReferrerRewardSplash,
  ;

  String get name => toString().split('.').last;
}
