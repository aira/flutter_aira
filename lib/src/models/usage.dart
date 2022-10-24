import 'package:intl/intl.dart';

DateTime? _parseDate(String? inputDate) {
  if (null == inputDate) {
    return null;
  } else {
    DateTime date = DateFormat('yyyy-MM-dd\'T\'HH:mm:ssZ').parse(inputDate);
    return date.add(date.timeZoneOffset);
  }
}

class PlanUsageBreakdown {
  String firstName;
  bool isPaused;
  String? lastName;
  int minutesUsed;
  int userId;
  String userType;

  PlanUsageBreakdown.fromJson(Map<String, dynamic> json)
      : firstName = json['firstName'],
        isPaused = json['isPaused'],
        lastName = json['lastName'],
        minutesUsed = json['minutesUsed'],
        userId = json['userId'],
        userType = json['userType'];
}

class Usage {
  String? planName;
  int? totalMinutes;
  int? totalMinutesLeft;
  int? totalPrimaryMinutes;
  int? totalPrimaryMinutesUsed;
  int? totalAccessMinutesUsed;
  int? totalMinutesUsed;
  int? totalCreditMinutes;
  int? totalCreditMinutesUsed;
  int? totalFixedMinutes;
  int? totalFixedMinutesUsed;
  DateTime? billingCycleStart;
  DateTime? billingCycleEnd;
  bool? hasFreeCall;
  DateTime? timeUntilNextFreeCall;
  bool primary;
  bool? planUnlimited;

  List<PlanUsageBreakdown>? planUsageBreakdownList;

  Usage.fromJson(Map<String, dynamic> json)
      : billingCycleEnd = null == json['billingCycleEnd'] ? null : DateTime.fromMillisecondsSinceEpoch(json['billingCycleEnd']),
        billingCycleStart = null == json['billingCycleStart'] ? null : DateTime.fromMillisecondsSinceEpoch(json['billingCycleStart']),
        hasFreeCall = json['hasFreeCall'],
        planName = json['planName'],
        planUnlimited = json['planUnlimited'],
        planUsageBreakdownList = (json['usageBreakdown'] as List<dynamic>).map((e) => PlanUsageBreakdown.fromJson(e)).toList(growable: false),
        primary = json['primary'],
        timeUntilNextFreeCall = _parseDate(json['timeUntilNextFreeCall']),
        totalAccessMinutesUsed = json['totalAccessMinutesUsed'],
        totalCreditMinutes = json['totalCreditMinutes'],
        totalCreditMinutesUsed = json['totalCreditMinutesUsed'],
        totalFixedMinutes = json['totalFixedMinutes'],
        totalFixedMinutesUsed = json['totalFixedMinutesUsed'],
        totalMinutes = json['totalMinutes'],
        totalMinutesLeft = json['totalMinutesLeft'],
        totalMinutesUsed = json['totalMinutesUsed'],
        totalPrimaryMinutes = json['totalPrimaryMinutes'],
        totalPrimaryMinutesUsed = json['totalPrimaryMinutesUsed'];
}