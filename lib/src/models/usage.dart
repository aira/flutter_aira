import 'package:intl/intl.dart';

DateTime? _parseDate(String? inputDate) {
  if (null == inputDate) {
    return null;
  } else {
    DateTime date = DateFormat('yyyy-MM-dd\'T\'HH:mm:ssZ').parse(inputDate);
    return date.add(date.timeZoneOffset);
  }
}

/// Some plans are shared by primary Explorer to secondary Explorers.
/// This Object contains details on who can use minutes within a Plan.
class PlanUsageBreakdown {
  /// Explorer's first name.
  String firstName;

  /// When secondary Explorer, your usage can be paused by the primary user.
  bool isPaused;

  /// Explorer's last name.
  String? lastName;

  /// Minutes used by the Explorer in the plan.
  int minutesUsed;

  /// Explorer's user Id.
  int userId;

  /// Type of user.
  String userType;

  PlanUsageBreakdown.fromJson(Map<String, dynamic> json)
      : firstName = json['firstName'],
        isPaused = json['isPaused'],
        lastName = json['lastName'],
        minutesUsed = json['minutesUsed'],
        userId = json['userId'],
        userType = json['userType'];
}

/// Contains main information about usage.
class Usage {
  /// Name of the plan.
  String? planName;

  /// Total available minutes in the plan.
  int? totalMinutes;

  /// Total of used minutes in the plan.
  int? totalMinutesLeft;

  /// Total amount of primary minutes in the plan. These primary minutes are personal minutes.
  int? totalPrimaryMinutes;

  /// Total amount of used primary minutes in the plan.
  int? totalPrimaryMinutesUsed;

  /// Total amount of free access minutes used.
  int? totalAccessMinutesUsed;

  /// Grand total of minutes used.
  int? totalMinutesUsed;

  /// Total of credited minutes.
  int? totalCreditMinutes;

  /// Total amount of used credited minutes.
  int? totalCreditMinutesUsed;

  /// Total amount of add-on minutes. Those minutes don't expires at the end of a cycle.
  int? totalFixedMinutes;

  /// Total amount of used add-on minutes.
  int? totalFixedMinutesUsed;

  /// Start date of a billing cycle.
  DateTime? billingCycleStart;

  /// End date of a billing cycle.
  DateTime? billingCycleEnd;

  /// Indicator if the Explorer has access to a 5 min free call.
  bool? hasFreeCall;

  /// Delay before next free 5 min call.
  DateTime? timeUntilNextFreeCall;

  /// Indicates if the User is Primary.
  bool primary;

  /// Indicates if the plan is unlimited.
  bool? planUnlimited;

  /// Breakdown of the usage by Primary and Secondary users.
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