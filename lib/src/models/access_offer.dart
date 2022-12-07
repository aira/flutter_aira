import 'package:flutter_aira/src/models/account.dart';
import 'package:flutter_aira/src/models/convertion_extension.dart';

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
    requireAgentApproval = json['requireAgentApproval'],
    siteAddress = null == json['siteAddress'] ? null : SiteAddress.fromJson(json['siteAddress']),
    siteId = json['siteId'],
    sticky = json['sticky'],
    // tasks = json['tasks'],
    termsAndConditionsUrl = json['termsAndConditionsUrl'],
    type = json['type']
  ;

  /*
{"payload":[
  {"entireCall":true,"termsAndConditionsUrl":null,"renewalTimestamp":null,"description":"For spring cleaning tasks around the house and on the computer","type":"PUBLIC","enabled":true,"availableToGuests":true,"enforcedOnExplorers":false,"termsAndConditions":null,"effectiveTo":null,"durationUsed":0,"expired":false,"id":57,"class":"promotion","renewalDurationAllowed":null,"key":"AVP-CLEANING","tasks":[],"agentMessage":"For up to 30 minutes this month, this Access Offer covers: general cleaning around the house, identifying and organizing items around the house, and cleaning up files on the computer.\n\nNot covered: Anything unrelated to general cleaning or organization around the home or computer.\n\nhttps://www.google.com/","visible":true,"requireAgentApproval":true,"callPeriodLength":3600,"message":"For up to 30 minutes this month, you can use this Access Offer for spring cleaning tasks like general cleaning around the house, organizing items around the house, and cleaning up files on the computer.","enforcedOnDuration":60,"site":null,"callsPerPeriod":-1,"name":"Agent Voted Promo-Spring Cleaning","sticky":false,"activatedEffectiveSeconds":null,"durationAllowed":3600,"durationPerCall":1800,"validationUserProperties":[],"effectiveFrom":null,"account":{"accountId":5557,"allowRecording":false,"accountCode":"203892","acceptBusinessUsers":true,"createdTimestamp":"2021-03-08T22:37:54Z","accountType":"BUSINESS","name":"Amazon - Employee","modifiedTimestamp":"2022-11-10T00:21:09Z","id":5557,"businessType":null},"activated":true},
  {"entireCall":true,"termsAndConditionsUrl":"https://aira.io","renewalTimestamp":null,"description":"Demonstrating Aira to friends","type":"PUBLIC","enabled":true,"availableToGuests":false,"enforcedOnExplorers":true,"termsAndConditions":null,"effectiveTo":null,"durationUsed":0,"expired":false,"id":7,"class":"promotion","renewalDurationAllowed":null,"key":"DEO","tasks":[],"agentMessage":"For up to 15 minutes at a time, Aira sponsors free service when Explorers demonstrate Aira to employers, people who are blind or have low vision, or anyone interested in Aira Access.","visible":true,"requireAgentApproval":true,"callPeriodLength":86400,"message":"For up to 15 minutes at a time, Aira sponsors free service when Explorers demonstrate Aira to employers, people who are blind or have low vision, or anyone interested in Aira Access.","enforcedOnDuration":0,"site":null,"callsPerPeriod":-1,"name":"Demo (Explorers Only)","sticky":false,"activatedEffectiveSeconds":null,"durationAllowed":-1,"durationPerCall":900,"validationUserProperties":[],"effectiveFrom":null,"account":{"accountId":3425,"allowRecording":true,"accountCode":"201582","acceptBusinessUsers":true,"createdTimestamp":"2018-09-13T23:47:38Z","accountType":"BUSINESS","name":"Intuit Quickbooks","modifiedTimestamp":"2019-05-13T23:50:55Z","id":3425,"businessType":null},"activated":true},
  {"entireCall":false,"termsAndConditionsUrl":null,"renewalTimestamp":null,"description":"5-minute calls for short everyday tasks","type":"PUBLIC","enabled":true,"availableToGuests":true,"enforcedOnExplorers":true,"termsAndConditions":null,"effectiveTo":null,"durationUsed":0,"expired":false,"id":19,"class":"promotion","renewalDurationAllowed":null,"key":"7DT","tasks":[],"agentMessage":"Aira is free for anyone to use! Anyone can make 5-minute calls for free, such as for short everyday tasks.\nThis is not an Access offer, but rather, a base level of free service. Aira’s free service and Access offers both provide free use of Aira. ","visible":false,"requireAgentApproval":false,"callPeriodLength":3600,"message":"You can now make short calls to Aira agents for free, every day. Great for doing those short tasks around the house. Try it now!","enforcedOnDuration":60,"site":null,"callsPerPeriod":-1,"name":"Free Daily Calls","sticky":false,"activatedEffectiveSeconds":null,"durationAllowed":-1,"durationPerCall":-1,"validationUserProperties":[],"effectiveFrom":"2019-06-24T00:00:00Z","account":{"accountId":2579,"allowRecording":true,"accountCode":"200643","acceptBusinessUsers":true,"createdTimestamp":"2017-10-27T21:32:55Z","accountType":"BUSINESS","name":"Aira Tech Corp","modifiedTimestamp":"2018-11-20T18:56:55Z","id":2579,"businessType":null},"activated":true},
  {"entireCall":false,"termsAndConditionsUrl":null,"renewalTimestamp":null,"description":"5-minute calls for short everyday tasks","type":"PRIVATE","enabled":true,"availableToGuests":true,"enforcedOnExplorers":true,"termsAndConditions":null,"effectiveTo":null,"durationUsed":316,"expired":false,"id":38,"class":"promotion","renewalDurationAllowed":null,"key":"FMF_GUEST","tasks":[],"agentMessage":"Aira is free for anyone to use! Anyone can make 5-minute calls for free, such as for short everyday tasks.\nThis is not an Access offer, but rather, a base level of free service. Aira’s free service and Access offers both provide free use of Aira. ","visible":false,"requireAgentApproval":false,"callPeriodLength":86400,"message":"You can now make short calls to Aira agents for free, every day. Great for doing those short tasks around the house. Try it now!","enforcedOnDuration":30,"site":null,"callsPerPeriod":1,"name":"Free Daily Calls","sticky":true,"activatedEffectiveSeconds":-1,"durationAllowed":-1,"durationPerCall":300,"validationUserProperties":[],"effectiveFrom":null,"account":{"accountId":2579,"allowRecording":true,"accountCode":"200643","acceptBusinessUsers":true,"createdTimestamp":"2017-10-27T21:32:55Z","accountType":"BUSINESS","name":"Aira Tech Corp","modifiedTimestamp":"2018-11-20T18:56:55Z","id":2579,"businessType":null},"activated":true},
  {"entireCall":true,"termsAndConditionsUrl":null,"renewalTimestamp":null,"description":"5-minute calls for short everyday tasks","type":"PUBLIC","enabled":true,"availableToGuests":true,"enforcedOnExplorers":true,"termsAndConditions":null,"effectiveTo":null,"durationUsed":0,"expired":false,"id":40,"class":"promotion","renewalDurationAllowed":null,"key":"VOTE_2020","tasks":[],"agentMessage":"This offer is eligible to be used for tasks related to exercising one's right to vote in the 2020 U.S. election. Each person can use up to 120 minutes of Aira before the offer expires. Eligible tasks: researching 2020 candidates, registering to vote, reviewing sample ballots, navigation to and through polling locations, coordinating transportation to polling location, waiting in line at polling location/ensuring safe social distancing, filling out ballot at physical polling location (if allowed at that location - up to Explorer to know), reading mail-in ballot instructions, post-voting selfies. Ineligible tasks: researching anything unrelated to the 2020 ballot content, scrolling through social media, posting about political beliefs on social media, donating to campaigns/PACs/etc, election canvassing.","visible":true,"requireAgentApproval":true,"callPeriodLength":3600,"message":"This offer is eligible to be used for tasks related to exercising one's right to vote in the 2020 U.S. election. Each person can use up to 120 minutes of Aira before the offer expires. This offer is valid 10/2/2020-11/3/2020 and only eligible to be used in the United States.","enforcedOnDuration":60,"site":null,"callsPerPeriod":-1,"name":"Get Out the Vote 2020","sticky":false,"activatedEffectiveSeconds":null,"durationAllowed":-1,"durationPerCall":-1,"validationUserProperties":[],"effectiveFrom":"2020-10-02T07:00:00Z","account":{"accountId":2579,"allowRecording":true,"accountCode":"200643","acceptBusinessUsers":true,"createdTimestamp":"2017-10-27T21:32:55Z","accountType":"BUSINESS","name":"Aira Tech Corp","modifiedTimestamp":"2018-11-20T18:56:55Z","id":2579,"businessType":null},"activated":true},
   */

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
  int? id;
  String? key;
  String? message;
  String name;
  bool? requireAgentApproval;
  SiteAddress? siteAddress;
  int? siteId;
  bool? sticky;
  // List<Task>? tasks;
  String? termsAndConditionsUrl;
  String? type;
}

class AccountDetails {
  AccountDetails.fromJson(Map<String, dynamic> json) :
    acceptBusinessUsers = json['acceptBusinessUsers'],
    accountCode = json['accountCode'],
    accountId = json['accountId'],
    accountType = AccountType.fromName(json['accountType']),
    // dob = json['dob'],
    email = json['email'],
    firstname = json['firstname'],
    // gender = json['gender'],
    // lastname = json['lastname'],
    name = json['name'],
    // password = json['password'],
    // phone = json['phone'],
    type = json['type'];

  bool? acceptBusinessUsers;
  String? accountCode;
  int? accountId;
  AccountType? accountType;
  // String? dob;
  String? email;
  String? firstname;
  // String? gender;
  // String? lastname;
  String? name;
  // String? password;
  // String? phone;
  String? type; // TODO: could be an enum! PUBLIC, PRIVATE, ???
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
}