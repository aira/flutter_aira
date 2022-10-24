import 'package:intl/intl.dart';

DateTime? _parseDate(String? dateToParse) {
  if (null == dateToParse) {
    return null;
  } else {
    DateTime date = DateFormat('MM/dd/yyyy HH:mm:ss').parse(dateToParse);
    return date.add(date.timeZoneOffset);
  }
}

class SessionFeedback {
  SessionFeedback.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        userId = json['userId'],
        submittedBy = json['submittedBy'],
        serviceId = json['serviceId'],
        comment = json['comment'],
        stars = json['stars'],
        taskSuccess = json['taskSuccess'];

  int id;
  int userId;
  int submittedBy;
  int serviceId;
  String? comment;
  int stars;
  bool taskSuccess;
}

class CallSession {
  CallSession.fromJson(Map<String, dynamic> json)
      : agentId = json['agentId'],
        agentFirstName = json['agentfirstname'],
        cannotTalk = json['cannotTalk'],
        durationMinutes = json['durationMinutes'],
        endTimeStamp = _parseDate(json['endTimeStamp'])!,
        requestSource = json['requestSource'],
        requestTimeStamp = _parseDate(json['requestTimeStamp']),
        requestType = json['requestType'],
        serviceId = json['serviceid'],
        startTimeStamp = _parseDate(json['startTimeStamp'])!,
        status = json['status'],
        userFirstname = json['firstname'],
        userId = json['userId'],
        userFeedback = null == json['userFeedback'] ? null : SessionFeedback.fromJson(json['userFeedback']);

  int? agentId;
  String? agentFirstName;
  bool cannotTalk;
  int? durationMinutes;
  DateTime endTimeStamp;
  String? requestSource;
  DateTime? requestTimeStamp;
  String requestType;
  int? serviceId;
  DateTime startTimeStamp;
  String status;
  String? userFirstname;
  int userId;
  SessionFeedback? userFeedback;
}