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

enum AccessAi {
  fullAccess('FULL_ACCESS'),
  noHistory('NO_HISTORY'),
  noAccess('NO_ACCESS');

  final String value;

  const AccessAi(this.value);

  /// Gets the [AccessAi] from the given value.
  ///
  /// If the value is not found, [noAccess] is returned.
  static AccessAi fromValue(String? value) {
    return AccessAi.values
        .firstWhere((e) => e.value == value, orElse: () => AccessAi.noAccess);
  }
}

class Account {
  final int id;
  final String name;
  final AccountType type;

  ///The Account(Profile) access limitations to AccessAI.
  final AccessAi? accessAI;

  Account.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        type = AccountType.fromName(json['accountType']),
        accessAI = AccessAi.fromValue(json['accessAi']);
}
