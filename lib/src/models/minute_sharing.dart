

/// Object containing all the required information to manage secondary users.
class MinuteSharingMember {
  /// Explorer's first name.
  String firstName;

  /// When secondary Explorer, your usage can be paused by the primary user.
  bool isPaused;

  /// Explorer's last name.
  String? lastName;

  /// Explorer's user Id.
  int userId;

  /// Type of user.
  String userType;

  MinuteSharingMember({
    required this.firstName,
    required this.isPaused,
    this.lastName,
    required this.userId,
    required this.userType,
  });

  MinuteSharingMember.fromJson(Map<String, dynamic> json)
      : firstName = json['firstName'],
  // See endpoint implementation in Platform 'AccountUserMapper.toDTO' and 'SmartAppManager.getUsageInfoSafe' to
  // validate this logic.
        isPaused = json['status'].toString().toUpperCase() == 'PAUSED',
        lastName = json['lastName'],
        userId = json['userId'],
        userType = json['userType'];
}

/// Object Returned by [PlatformClient.getSecondaryUsers] which contains all the minute sharing information linked to a
/// primary account.
class MinuteSharingInformation {
  /// List of all pending minute sharing email invitations.
  List<String> inviteeEmails;

  /// List of all secondary users who currently have access to primary account minutes.
  List<MinuteSharingMember> members;

  /// Total number of additional members who can share minutes with primary user.
  int? maxAdditionalShared;

  MinuteSharingInformation.fromJson(Map<String, dynamic> json)
      : inviteeEmails = (json['invites'] as List<dynamic>)
            .map((invitee) => invitee['invitee'])
            .cast<String>()
            .toList(growable: false),
        members = (json['users'] as List<dynamic>)
            .map((pUsage) => MinuteSharingMember.fromJson(pUsage))
            .toList(growable: false),
        maxAdditionalShared = json['maxAdditionalShared'];
}
//{
// "code":"3400706fc7604b3eb662171faad897da",
// "invitedBy":6256,
// "invitedByFirstName":"Israel",
// "hasAiraAccount":false,
// "invitee":"israel.painchaud+3@gmail.com"
//}

//{
// "entireCall":true,
//> "lastName":"Painchaud",
// "termsAndConditionsUrl":null,
// "renewalTimestamp":null,
// "description":null,
// "type":"PRIVATE",
//> "enabled":true,
// "availableToGuests":true,
// "enforcedOnExplorers":true,
// "termsAndConditions":null,
//- "effectiveTo":null,
//> "durationUsed":0,
// "expired":true,
// "consumeOnSite":false,
// "id":218565,
// "class":"account",
// "renewalDurationAllowed":null,
// "key":"",
// "agentMessage":null,
// "visible":false,
//- "accountType":"PRIMARY",
// "requireAgentApproval":false,
// "createdTimestamp":"2022-06-23T21:34:29Z",
// "callPeriodLength":86400,
// "defaultProfile":true,
// "message":null,
//> "userId":6256,
// "enforcedOnDuration":0,
// "firstName":"Israel",
// "accountId":5628,
// "createdDate":1656020069000,
// "callsPerPeriod":-1,
// "modifiedDate":1666982903000,
// "name":"",
// "activatedEffectiveSeconds":-1,
// "modifiedTimestamp":"2022-10-28T18:48:23Z",
//> "userType":"primary",
// "durationAllowed":-1,
// "durationPerCall":-1,
// "validationUserProperties":null,
// "effectiveFrom":null,
// "account":{
//   "accountId":5628,
//   "allowRecording":true,
//   "accountCode":"203965",
//   "acceptBusinessUsers":false,
//   "createdTimestamp":"2022-06-23T21:34:27Z",
//   "accountType":"INDIVIDUAL",
//   "name":"Explorer",
//   "modifiedTimestamp":"2022-06-23T21:34:27Z",
//   "id":5628,
//   "businessType":null
// },
// "status":"ACTIVE",
// "activated":true
//}
