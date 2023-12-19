import 'package:flutter_aira/src/models/account.dart';
import 'package:flutter_aira/src/models/conversion_extension.dart';

enum AccessOfferType {
  product,
  promotion,
  site;

  String get name => toString().split('.').last;

  static AccessOfferType? from(String? value) =>
      null == value ? null : AccessOfferType.values.byName(value.toLowerCase());
}

class AccessOfferDetails {
  AccessOfferDetails.fromJson(Map<String, dynamic> json) :
    account = null == json['account'] ? null : AccountDetails.fromJson(json['account']),
    activated = json['activated'],
    activatedEffectiveSeconds = json['activatedEffectiveSeconds'],
    availableToGuests = json['availableToGuests'],
    description = json['description'],
    distanceMiles = json['distanceMiles'],
    durationAllowed = json['durationAllowed'],
    durationPerCall = json['durationPerCall'],
    durationUsed = json['durationUsed'],
    effectiveFrom = (json['effectiveFrom'] as String?)?.dateTimeZ,
    effectiveTo = (json['effectiveTo'] as String?)?.dateTimeZ,
    enabled = json['enabled'],
    expired = json['expired'],
    id = json['id'],
    key = json['key'],
    message = json['message'],
    name = json['name'],
    offerType = AccessOfferType.from(json['class']!)!,
    requireAgentApproval = json['requireAgentApproval'],
    siteAddress = null == json['siteAddress'] ? null : SiteAddress.fromJson(json['siteAddress']),
    siteId = json['siteId'],
    sticky = json['sticky'],
    // tasks = json['tasks'],
    termsAndConditionsUrl = json['termsAndConditionsUrl'],
    type = json['type']
  ;

  AccountDetails? account;
  bool? activated;
  int? activatedEffectiveSeconds;
  bool? availableToGuests;
  String? description;
  double? distanceMiles;
  int? durationAllowed;
  int? durationPerCall;
  int? durationUsed;
  DateTime? effectiveFrom;
  DateTime? effectiveTo;
  bool? enabled;
  bool? expired;
  int id;
  String? key;
  String? message;
  String name;
  AccessOfferType offerType;
  bool? requireAgentApproval;
  SiteAddress? siteAddress;
  int? siteId;
  bool? sticky;
  // List<Task>? tasks;
  String? termsAndConditionsUrl;
  String? type;

  Map<String, dynamic> toJson() => {
        'account': account?.toJson(),
        'activated': activated,
        'activatedEffectiveSeconds': activatedEffectiveSeconds,
        'availableToGuests': availableToGuests,
        'description': description,
        'distanceMiles': distanceMiles,
        'durationAllowed': durationAllowed,
        'durationPerCall': durationPerCall,
        'durationUsed': durationUsed,
        'effectiveFrom': effectiveFrom?.toIso8601String(),
        'effectiveTo': effectiveTo?.toIso8601String(),
        'enabled': enabled,
        'expired': expired,
        'id': id,
        'key': key,
        'message': message,
        'name': name,
        'class': offerType.name,
        'requireAgentApproval': requireAgentApproval,
        'siteAddress': siteAddress?.toJson(),
        'siteId': siteId,
        'sticky': sticky,
        'termsAndConditionsUrl': termsAndConditionsUrl,
        'type': type,
  };
}

class AccountDetails {
  AccountDetails.fromJson(Map<String, dynamic> json) :
    acceptBusinessUsers = json['acceptBusinessUsers'],
    accountCode = json['accountCode'],
    accountId = json['accountId'],
    accountType = AccountType.fromName(json['accountType']),
    email = json['email'],
    firstname = json['firstname'],
    name = json['name'],
    type = json['type'];

  bool? acceptBusinessUsers;
  String? accountCode;
  int? accountId;
  AccountType? accountType;
  String? email;
  String? firstname;
  String? name;
  String? type; // TODO: could be an enum! PUBLIC, PRIVATE, ???

  Map<String, dynamic> toJson() =>
      {
        'acceptBusinessUsers': acceptBusinessUsers,
        'accountCode': accountCode,
        'accountId': accountId,
        'accountType': accountType?.name,
        'email': email,
        'firstname': firstname,
        'name': name,
        'type': type,
      };
}

class SiteAddress {
  SiteAddress.fromJson(Map<String, dynamic> json)
      : address1 = json['address1'],
        address2 = json['address2'],
        address3 = json['address3'],
        city = json['city'],
        country = json['country'],
        county = json['county'],
        latitudeLongitude = (json['latitudeLongitude'] as List<dynamic>).cast<double>().toList(growable: false),
        state = json['state'],
        zip = json['zip'];

  String? address1;
  String? address2;
  String? address3;
  String? city;
  String? country;
  String? county;
  List<double> latitudeLongitude = [];
  String? state;
  String? zip;

  Map<String, dynamic> toJson() =>
      {
        'address1': address1,
        'address2': address2,
        'address3': address3,
        'city': city,
        'country': country,
        'county': county,
        'latitudeLongitude': latitudeLongitude,
        'state': state,
        'zip': zip,
      };
}