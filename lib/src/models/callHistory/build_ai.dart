class BuildAi {
  /// Creates a new instance of [BuildAi].
  const BuildAi({
    required this.status,
    required this.isExplorerAllowedToShare,
    required this.explorerCanChangeAllowSharing,
    required this.reasonForNotAllowingChangeSharingStatus,
  });

  BuildAi.fromJson(Map<String, dynamic> json)
      : status = BuildAiStatus.fromValue(json['status']),
        isExplorerAllowedToShare = json['explorerAllowSharing'],
        explorerCanChangeAllowSharing = json['explorerCanChangeAllowSharing'],
        reasonForNotAllowingChangeSharingStatus =
            NotAllowSharingReason.fromValue(
          json['cannotChangeAllowSharingReason'],
        );

  /// The status of the session, whether the call can be shared or not.
  final BuildAiStatus? status;

  /// Whether the explorer is allowed to share the call.
  final bool? isExplorerAllowedToShare;

  /// Whether the explorer can change the allow sharing status.
  final bool explorerCanChangeAllowSharing;

  /// The reason for not allowing the change of sharing status.
  final NotAllowSharingReason? reasonForNotAllowingChangeSharingStatus;

  Map<String, dynamic> toMap() {
    return {
      'status': status?.value,
      'explorerAllowSharing': isExplorerAllowedToShare,
      'explorerCanChangeAllowSharing': explorerCanChangeAllowSharing,
      'cannotChangeAllowSharingReason':
          reasonForNotAllowingChangeSharingStatus?.value,
    };
  }
}

/// The status of the session, whether the call can be shared or not.
///All status can be found here https://github.com/aira/platform/blob/master/core/server/AiraPlatformManager/src/main/java/io/aira/manager/service/request/ServiceRequestManager.java.
enum BuildAiStatus {
  doNotAllowSharing('DO_NOT_ALLOW_SHARING'),
  allowSharing('ALLOW_SHARING'),
  shared('SHARED'),
  ineligibleContent('INELIGIBLE_CONTENT'),
  ineligibleCountry('INELIGIBLE_COUNTRY'),
  ineligibleBilling('INELIGIBLE_BILLING');

  final String value;

  const BuildAiStatus(this.value);

  /// Gets the [BuildAiStatus] from the given value.
  ///
  /// If the value is not found, [allowSharing] is returned.
  static BuildAiStatus fromValue(String? value) {
    return BuildAiStatus.values
        .firstWhere((e) => e.value == value, orElse: () => allowSharing);
  }
}

enum NotAllowSharingReason {
  ineligible('INELIGIBLE'),
  timePassed('TIME_PAST');

  final String value;

  const NotAllowSharingReason(this.value);

  /// Gets the [NotAllowSharingReason] from the given value.
  ///
  /// If the value is not found, [ineligible] is returned.
  static NotAllowSharingReason fromValue(String? value) {
    return NotAllowSharingReason.values
        .firstWhere((e) => e.value == value, orElse: () => ineligible);
  }
}