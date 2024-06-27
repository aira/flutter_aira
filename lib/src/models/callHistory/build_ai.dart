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

  BuildAi copyWith({
    BuildAiStatus? status,
    bool? isExplorerAllowedToShare,
    bool? explorerCanChangeAllowSharing,
    NotAllowSharingReason? reasonForNotAllowingChangeSharingStatus,
  }) {
    return BuildAi(
      status: status ?? this.status,
      isExplorerAllowedToShare:
          isExplorerAllowedToShare ?? this.isExplorerAllowedToShare,
      explorerCanChangeAllowSharing:
          explorerCanChangeAllowSharing ?? this.explorerCanChangeAllowSharing,
      reasonForNotAllowingChangeSharingStatus:
          reasonForNotAllowingChangeSharingStatus ??
              this.reasonForNotAllowingChangeSharingStatus,
    );
  }
}

/// The status of the session, whether the call can be shared or not.
/// All statuses can be found here https://github.com/aira/platform/blob/master/core/server/AiraPlatformManager/src/main/java/io/aira/dto/buildai/BuildAiStatus.java
enum BuildAiStatus {
  /// The explorer has chosen NOT to share the session
  doNotAllowSharing('DO_NOT_ALLOW_SHARING'),

  /// All the business rules were met to allow sharing with the AI partner, the 72-hour time window did not pass
  allowSharing('ALLOW_SHARING'),

  /// All the business rules were met to allow sharing with the AI partner, the 72-hour time window passed
  shared('SHARED'),

  /// The session is ineligible as it contains sensitive information (marked by a VI)
  ineligibleContent('INELIGIBLE_CONTENT'),

  /// The session was initiated from a country that is not eligible for sharing
  ineligibleCountry('INELIGIBLE_COUNTRY'),

  /// The session is ineligible to share due to not using the eligible access offer during the session
  ineligibleBilling('INELIGIBLE_BILLING'),

  /// The session is ineligible as it was part of a call transfer
  ineligibleCallTransfer('INELIGIBLE_CALL_TRANSFER'),
  ;

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
