import 'dart:convert';

import 'package:flutter_aira/src/models/feedback.dart';
import 'package:intl/intl.dart';

DateTime? _parseDate(String? dateToParse) {
  if (null == dateToParse) {
    return null;
  } else {
    DateTime date = DateFormat('MM/dd/yyyy HH:mm:ss').parse(dateToParse);
    return date.add(date.timeZoneOffset);
  }
}

/// Object containing all the Feedback Information.
class SessionFeedback {
  SessionFeedback({required this.serviceId, this.requestReview = false, this.appFeedback, this.agentFeedback});
  factory SessionFeedback.fromJson(Map<String, dynamic> json) {
    String? commentRaw = json['comment'];
    Map<String, dynamic> commentJson;
    try {
      // If the feedback is from the new generation of application, the feedback will be stored as JSON within "comment".
      // If the "comment" is null, the feedback comes from Legacy.
      commentJson = null == commentRaw ? _convertFeedbackFromLegacy(json) : jsonDecode(commentRaw);
    } catch (e) {
      // If the content of "comment" is not parsable as JSON, this is a legacy feedback.
      commentJson = _convertFeedbackFromLegacy(json);
    }
    bool requestReview = commentJson['agent']?['requestReview'] ?? false;
    return SessionFeedback(
      serviceId: json['serviceId'],
      requestReview: requestReview,
      appFeedback: null == commentJson['app'] ? null : Feedback.fromJson(commentJson['app']),
      agentFeedback: null == commentJson['agent'] ? null : AgentFeedback.fromJson(commentJson['agent']),
    );
  }

  /// Service request ID.
  int serviceId;

  /// True if the Explorer requested special attention to his review.
  bool requestReview;

  /// Explorer's Feedback about the application.
  Feedback? appFeedback;

  /// Explorer's Feedback about the Agent.
  AgentFeedback? agentFeedback;

  static Map<String, dynamic> _convertFeedbackFromLegacy(Map<String, dynamic> json) =>
      {
        'agent': {
          'comment': json['comment'],
          'rating': json['taskSuccess'] ? 1 : -1,
        }
      };
}

/// Contains Information saved about previous calls.
class CallSession {
  CallSession.fromJson(Map<String, dynamic> json)
      : agentId = json['agentId'],
        agentFirstName = json['agentfirstname'],
        endTimeStamp = _parseDate(json['endTimeStamp'])!,
        requestSource = json['requestSource'],
        requestTimeStamp = _parseDate(json['requestTimeStamp']),
        serviceId = json['serviceid'],
        startTimeStamp = _parseDate(json['startTimeStamp'])!,
        status = json['status'],
        userFirstname = json['firstname'],
        userId = json['userId'],
        userFeedback = null == json['userFeedback'] ? null : SessionFeedback.fromJson(json['userFeedback']);

  /// ID representing the Agent.
  int? agentId;

  /// First name of the agent.
  String? agentFirstName;

  /// End time of the call.
  DateTime endTimeStamp;

  /// Identification of the application initiating the call.
  String? requestSource;

  /// Timestamp of the service request.
  DateTime? requestTimeStamp;

  /// ID representing the Service Request.
  int serviceId;

  /// Start time of the call.
  DateTime startTimeStamp;

  /// Possible ending call statuses: ACCOUNT_IN_USE, CANCEL, END, ERROR, FAILED, OUT_OF_MINUTES, OUTSIDE_SERVICE_HOUR
  /// STALE, THROTTLED and TIMEOUT
  String status;

  /// Explorer's first name.
  String? userFirstname;

  /// Explorer's user Id.
  int userId;

  /// The Explorer's feedback.
  SessionFeedback? userFeedback;
}