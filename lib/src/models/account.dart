import 'package:collection/collection.dart';

enum AccountType {
  /// A business account.
  business,

  /// An individual account.
  individual,

  /// A reseller account.
  reseller;

  String get name => toString().split('.').last;

  static AccountType fromName(String name) {
    return AccountType.values.byName(name.toLowerCase());
  }
}

enum AccessAiRestriction {
  fullAccess('FULL_ACCESS'),
  noHistory('NO_HISTORY'),
  noAccess('NO_ACCESS');

  final String value;

  const AccessAiRestriction(this.value);

  /// Gets the [AccessAiRestriction] from the given value.
  ///
  /// If the value is not found, [null] is returned.
  static AccessAiRestriction? fromValue(String? value) {
    return AccessAiRestriction.values.firstWhereOrNull((e) => e.value == value);
  }
}

class Account {
  final int id;
  final String name;
  final AccountType type;

  ///The Account(Profile) access limitations to AccessAI.
  final AccessAiRestriction? accessAI;

  Account.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        type = AccountType.fromName(json['accountType']),
        accessAI = AccessAiRestriction.fromValue(json['accessAi']);
}
