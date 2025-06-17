import 'package:flutter_aira/flutter_aira.dart';

import 'profile.dart';

class User {
  final int id;
  final String uuid;
  final String? email;
  final String firstName;
  final List<Language> languages;
  final String lastName;
  final List<String>? linkedAccounts;
  final String? phoneNumber;
  final List<Profile> profiles;
  final String? referralLink;
  final bool tosAccepted;
  final int aiDailyMessageLimit;
  final AiLanguageLevel aiLanguageLevel;
  final AiVerbosity aiVerbosity;
  final bool isASL;
  final String? googleEmail;
  final String? appleEmail;
  final bool? buildAiProgramJoined;
  final bool? airaAiTosAccepted;
  final bool? showReferrerRewardSplash;
  final bool? hasMetaGlasses;

  User({
    required this.id,
    required this.uuid,
    this.email,
    required this.firstName,
    required this.languages,
    required this.lastName,
    this.linkedAccounts,
    this.phoneNumber,
    required this.profiles,
    this.referralLink,
    required this.tosAccepted,
    required this.aiDailyMessageLimit,
    required this.aiLanguageLevel,
    required this.aiVerbosity,
    required this.isASL,
    this.appleEmail,
    this.googleEmail,
    this.buildAiProgramJoined,
    this.airaAiTosAccepted,
    this.showReferrerRewardSplash,
    this.hasMetaGlasses,
  });

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        uuid = json['uuid'],
        email = json['email'],
        firstName = json['firstName'] ?? '',
        languages = (json['language'] ?? [] as List<String>)
            .map((v) => Language.fromString(v))
            .cast<Language>()
            .toList(growable: false),
        lastName = json['lastName'] ?? '',
        linkedAccounts = (json['providers'] as List<dynamic>)
            .map((json) => json['serviceName'] as String)
            .toList(growable: false),
        phoneNumber = json['phoneNumber'],
        tosAccepted = json['tosAccepted'],
        profiles = (json['accounts'] as List<dynamic>)
            .map((e) => Profile.fromJson(e))
            .toList(growable: false),
        referralLink = json['referralLink'],
        aiDailyMessageLimit =
            _getAIDailyMessageLimitProperty(json['properties']),
        aiVerbosity = AiVerbosity.fromValue(_getProperty(json, 'aiVerbosity')),
        aiLanguageLevel =
            AiLanguageLevel.fromValue(_getProperty(json, 'aiLanguageLevel')),
        isASL = _getIsASLProperty(json['properties']),
        googleEmail = _getProperty(json, 'googleEmail'),
        appleEmail = _getProperty(json, 'appleEmail'),
        buildAiProgramJoined = _getProperty(json, 'buildAiProgramJoined'),
        airaAiTosAccepted = _getProperty(json, 'airaAiTosAccepted'),
        showReferrerRewardSplash =
            _getProperty(json, 'showReferrerRewardSplash'),
        hasMetaGlasses = _getProperty(json, 'hasMetaGlasses');

  /// Keeping immutability of the class while providing a way to clone new instances of User with different values.
  User cloneWith({
    int? id,
    String? uuid,
    String? email,
    String? firstName,
    List<Language>? languages,
    String? lastName,
    List<String>? linkedAccounts,
    String? phoneNumber,
    bool? tosAccepted,
    List<Profile>? profiles,
    String? referralLink,
    int? aiDailyMessageLimit,
    AiVerbosity? aiVerbosity,
    AiLanguageLevel? aiLanguageLevel,
    bool? isASL,
    bool? airaAiTosAccepted,
  }) =>
      User(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        email: email ?? this.email,
        firstName: firstName ?? this.firstName,
        languages: languages ?? this.languages,
        lastName: lastName ?? this.lastName,
        linkedAccounts: linkedAccounts ?? this.linkedAccounts,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        profiles: profiles ?? this.profiles,
        tosAccepted: tosAccepted ?? this.tosAccepted,
        referralLink: referralLink ?? this.referralLink,
        aiDailyMessageLimit: aiDailyMessageLimit ?? this.aiDailyMessageLimit,
        aiLanguageLevel: aiLanguageLevel ?? this.aiLanguageLevel,
        aiVerbosity: aiVerbosity ?? this.aiVerbosity,
        isASL: isASL ?? this.isASL,
        airaAiTosAccepted: airaAiTosAccepted ?? this.airaAiTosAccepted,
      );
}

dynamic _getProperty(Map<String, dynamic> json, String key) =>
    json['properties']?[key]?.first?['value'];

///Returns the value of the property [aiDailyMessageLimit] from the [json] object.
int _getAIDailyMessageLimitProperty(Map<String, dynamic> json) =>
    int.tryParse(_getProperty(json, 'aiDailyMessageLimit') ?? '0') ?? 0;

bool _getIsASLProperty(Map<String, dynamic> json) =>
    (json['routingGroup'] as List?)?.any(
      (element) => element['value']?.toString() == 'ASL required',
    ) ??
    false;

enum AiLanguageLevel {
  basic,
  preset,
  advanced;

  factory AiLanguageLevel.fromValue(String? value) {
    switch (value) {
      case 'basic':
        return AiLanguageLevel.basic;
      case 'advanced':
        return AiLanguageLevel.advanced;
      default:
        return AiLanguageLevel.preset;
    }
  }

  String toValue() {
    switch (this) {
      case AiLanguageLevel.basic:
        return 'basic';
      case AiLanguageLevel.preset:
        return 'default';
      case AiLanguageLevel.advanced:
        return 'advanced';
    }
  }
}

enum AiVerbosity {
  low,
  preset,
  high;

  factory AiVerbosity.fromValue(String? value) {
    switch (value) {
      case 'low':
        return AiVerbosity.low;
      case 'high':
        return AiVerbosity.high;
      default:
        return AiVerbosity.preset;
    }
  }

  String toValue() {
    switch (this) {
      case AiVerbosity.low:
        return 'low';
      case AiVerbosity.preset:
        return 'default';
      case AiVerbosity.high:
        return 'high';
    }
  }
}
