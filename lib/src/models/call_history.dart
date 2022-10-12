import 'package:intl/intl.dart';

DateTime? _parseDate(String? dateToParse) => null == dateToParse ? null : DateFormat('MM/dd/yyyy HH:mm:ss').parse(dateToParse);

class CallSession {
  CallSession.fromJson(Map<String, dynamic> json)
      : agentId = json['agentId'],
        agentFirstName = json['agentfirstname'],
        callCount = json['callCount'],
        cannotTalk = json['cannotTalk'],
        durationMinutes = json['durationMinutes'],
        endTimeStamp = json['endTimeStamp'],
        requestSource = json['requestSource'],
        requestTimeStamp = _parseDate(json['requestTimeStamp']),
        requestType = json['requestType'],
        serviceId = json['serviceid'],
        startTimeStamp = json['startTimeStamp'],
        status = json['status'],
        userFirstname = json['firstname'],
        userId = json['userId'];

  int? agentId;
  String? agentFirstName; //*
  int? callCount;
  bool cannotTalk;
  int? durationMinutes; //*
  String? endTimeStamp;
  String? requestSource;
  DateTime? requestTimeStamp; //*
  String requestType;
  int? serviceId; //*
  String? startTimeStamp;
  String status;
  String? userFirstname;
  int userId;
}