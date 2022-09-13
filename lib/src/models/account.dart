enum AccountType {
  /// A business account.
  business,

  /// An individual account.
  individual,

  /// A reseller account.
  reseller;

  static AccountType fromName(String name) {
    return AccountType.values.byName(name.toLowerCase());
  }
}

class Account {
  final int id;
  final String name;
  final AccountType type;

  Account.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        type = AccountType.fromName(json['accountType']);
}
