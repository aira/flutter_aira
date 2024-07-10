import 'package:flutter_aira/flutter_aira.dart';

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
  final String? referralLink;
  final bool tosAccepted;
  final int aiDailyMessageLimit;
  final AiLanguageLevel aiLanguageLevel;
  final AiVerbosity aiVerbosity;
  final bool isASL;

  User({
    required this.id,
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
  });

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
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
        aiVerbosity = _getAIVerbosityProperty(json['properties']),
        aiLanguageLevel = _getAILanguageLevelProperty(json['properties']),
        isASL = _getIsASLProperty(json['properties']);

  /// Keeping immutability of the class while providing a way to clone new instances of User with different values.
  User cloneWith({
    int? id,
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
        tosAccepted: tosAccepted ?? this.tosAccepted,
        referralLink: referralLink ?? this.referralLink,
        aiDailyMessageLimit: aiDailyMessageLimit ?? this.aiDailyMessageLimit,
        aiLanguageLevel: aiLanguageLevel ?? this.aiLanguageLevel,
        aiVerbosity: aiVerbosity ?? this.aiVerbosity,
        isASL: isASL ?? this.isASL,
      );
}

///Returns the value of the property [aiDailyMessageLimit] from the [json] object.
int _getAIDailyMessageLimitProperty(Map<String, dynamic> json) =>
    int.tryParse(json['aiDailyMessageLimit']?.first?['value'] ?? '0') ?? 0;

bool _getIsASLProperty(Map<String, dynamic> json) =>
    (json['routingGroup'] as List?)?.any(
      (element) => element['value']?.toString() == 'ASL required',
    ) ??
    false;

AiLanguageLevel _getAILanguageLevelProperty(Map<String, dynamic> json) =>
    AiLanguageLevel.fromValue(json['aiLanguageLevel']?.first?['value']);

AiVerbosity _getAIVerbosityProperty(Map<String, dynamic> json) =>
    AiVerbosity.fromValue(json['aiVerbosity']?.first?['value']);

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
