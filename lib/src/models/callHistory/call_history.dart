import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter_aira/src/models/callHistory/build_ai.dart';
import 'package:flutter_aira/src/models/callHistory/feedback_form.dart';
import 'package:flutter_aira/src/models/conversion_extension.dart';
import 'package:flutter_aira/src/models/feedback.dart';

/// Object containing all the Feedback Information.
class SessionFeedback {
  SessionFeedback({
    required this.serviceId,
    required this.serviceUuid,
    this.requestReview = false,
    this.appFeedback,
    this.agentFeedback,
    this.aiFeedback,
  });

  factory SessionFeedback.fromJson({
    required Map<String, dynamic> json,
    required String serviceUuid,
  }) {
    String? commentRaw = json['comment'];
    Map<String, dynamic> commentJson;
    try {
      // If the feedback is from the new generation of application, the feedback will be stored as JSON within "comment".
      // If the "comment" is null, the feedback comes from Legacy.
      commentJson = null == commentRaw
          ? _convertFeedbackFromLegacy(json)
          : jsonDecode(commentRaw);
    } catch (e) {
      // If the content of "comment" is not parsable as JSON, this is a legacy feedback.
      commentJson = _convertFeedbackFromLegacy(json);
    }
    bool requestReview = commentJson['agent']?['requestReview'] ?? false;
    return SessionFeedback(
      serviceId: json['serviceId'],
      serviceUuid: serviceUuid,
      requestReview: requestReview,
      appFeedback: Feedback.fromJson(commentJson['app']),
      agentFeedback: Feedback.fromJson(commentJson['agent']),
      aiFeedback: Feedback.fromJson(commentJson['ai']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'serviceUuid': serviceUuid,
      'requestReview': requestReview,
      'app': appFeedback?.toJson(),
      'agent': agentFeedback?.toJson(),
      'ai': aiFeedback?.toJson(),
    };
  }

  /// Service request ID.
  /// Please check the [serviceUuid] if [serviceId] not exist.
  int? serviceId;

  /// please check the [serviceId] if [serviceUuid] not exist.
  String? serviceUuid;

  /// True if the Explorer requested special attention to his review.
  bool requestReview;

  /// Explorer's Feedback about the application.
  Feedback? appFeedback;

  /// Explorer's Feedback about the Agent.
  Feedback? agentFeedback;

  Feedback? aiFeedback;

  static Map<String, dynamic> _convertFeedbackFromLegacy(
    Map<String, dynamic> json,
  ) =>
      {
        'agent': {
          'comment': json['comment'],
          'rating': json['taskSuccess'] ? 1 : -1,
        },
      };
}

/// Contains Information saved about previous calls.
class CallSession {
  CallSession.fromJson(Map<String, dynamic> json)
      : agentId = json['agentId'],
        agentFirstName = json['agentfirstname'],
        endTimeStamp = (json['endTimeStamp'] as String?)?.dateTime,
        requestSource = json['requestSource'],
        requestTimeStamp = (json['requestTimeStamp'] as String?)?.dateTime,
        serviceId = json['serviceid'] ?? json['serviceId'],
        serviceUuid = json['serviceUuid'],
        startTimeStamp = (json['startTimeStamp'] as String?)?.dateTime,
        status = json['status'],
        userFirstname = json['firstname'],
        userId = json['userId'],
        userFeedback = null == json['userFeedback']
            ? null
            : SessionFeedback.fromJson(
                json: json['userFeedback'],
                serviceUuid: json['serviceUuid'],
              ),
        buildAi =
            json['buildAi'] != null ? BuildAi.fromJson(json['buildAi']) : null,
        userFeedbackForm = FeedbackForm.fromJson(json['userFeedbackForm']),
        callType = CallType.fromString(json['callType']),
        chatRoomId = json['chatRoomId'];

  /// ID representing the Agent.
  int? agentId;

  /// First name of the agent.
  String? agentFirstName;

  /// End time of the call.
  DateTime? endTimeStamp;

  /// Identification of the application initiating the call.
  String? requestSource;

  /// Timestamp of the service request.
  DateTime? requestTimeStamp;

  /// ID representing the Service Request.
  int serviceId;

  String serviceUuid;

  /// Start time of the call.
  DateTime? startTimeStamp;

  /// Possible ending call statuses: ACCOUNT_IN_USE, CANCEL, END, ERROR, FAILED, OUT_OF_MINUTES, OUTSIDE_SERVICE_HOUR
  /// STALE, THROTTLED and TIMEOUT
  String status;

  /// Explorer's first name.
  String? userFirstname;

  /// Explorer's user Id.
  int userId;

  /// The Explorer's feedback.
  SessionFeedback? userFeedback;

  ///BuildAi program data.
  BuildAi? buildAi;

  FeedbackForm userFeedbackForm;

  /// Default is [CallType.standard].
  CallType callType;

  String? chatRoomId;
}

enum CallType {
  standard('STANDARD'),
  aiVisualInterpreter('AI_VISUAL_INTERPRETER'),
  ;

  const CallType(this.value);

  final String value;

  static CallType fromString(String? value) {
    if (value == null) return CallType.standard;

    return CallType.values.firstWhereOrNull((e) => e.value == value) ??
        CallType.standard;
  }
}
