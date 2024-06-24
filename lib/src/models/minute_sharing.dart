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
  int maxAdditionalShared;

  /// Returns true if the user is a Guest.
  bool isGuest;

  MinuteSharingInformation.fromJson(Map<String, dynamic> json)
      : inviteeEmails = (json['invites'] as List<dynamic>)
            .map((invitee) => invitee['invitee'])
            .cast<String>()
            .toList(growable: false),
        members = (json['users'] as List<dynamic>)
            .map((pUsage) => MinuteSharingMember.fromJson(pUsage))
            .toList(growable: false),
        maxAdditionalShared = json['maxAdditionalShared'],
        isGuest = json['isGuest'];
}
