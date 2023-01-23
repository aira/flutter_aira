import 'package:flutter_aira/src/models/convertion_extension.dart';
import 'package:flutter_aira/src/models/secondaryUser.dart';

/// Some plans are shared by primary Explorer to secondary Explorers.
/// This Object contains details on who can use minutes within a Plan.
class PlanUsageBreakdown extends MinuteSharingMember {
  /// Minutes used by the Explorer in the plan.
  int minutesUsed;

  PlanUsageBreakdown.fromJson(Map<String, dynamic> json)
      : minutesUsed = json['minutesUsed'],
        super(
          firstName: json['firstName'],
          isPaused: json['isPaused'],
          lastName: json['lastName'],
          userId: json['userId'],
          userType: json['userType'],
        );
}

/// Contains main information about usage.
class Usage {

  /// End date of a billing cycle.
  DateTime? billingCycleEnd;

  /// Start date of a billing cycle.
  DateTime? billingCycleStart;

  /// Indicator if the Explorer has access to a 5 min free call.
  bool? hasFreeCall;

  /// Name of the plan.
  String? planName;

  /// Indicates if the plan is unlimited.
  bool? planUnlimited;

  /// Indicates if the User is Primary.
  bool primary;

  /// Breakdown of the usage by Primary and Secondary users.
  List<PlanUsageBreakdown>? planUsageBreakdownList;

  /// Delay before next free 5 min call.
  DateTime? timeUntilNextFreeCall;

  /// Total amount of free access minutes used.
  int? totalAccessMinutesUsed;

  /// Total of credited minutes.
  int? totalCreditMinutes;

  /// Total amount of used credited minutes.
  int? totalCreditMinutesUsed;

  /// Total amount of add-on minutes. Those minutes don't expires at the end of a cycle.
  int? totalFixedMinutes;

  /// Total amount of used add-on minutes.
  int? totalFixedMinutesUsed;

  /// Total available minutes in the plan.
  int? totalMinutes;

  /// Total of used minutes in the plan.
  int? totalMinutesLeft;

  /// Grand total of minutes used.
  int? totalMinutesUsed;

  /// Total amount of primary minutes in the plan. These primary minutes are personal minutes.
  int? totalPrimaryMinutes;

  /// Total amount of used primary minutes in the plan.
  int? totalPrimaryMinutesUsed;

  Usage.fromJson(Map<String, dynamic> json)
      : billingCycleEnd = null == json['billingCycleEnd'] ? null : DateTime.fromMillisecondsSinceEpoch(json['billingCycleEnd']),
        billingCycleStart = null == json['billingCycleStart'] ? null : DateTime.fromMillisecondsSinceEpoch(json['billingCycleStart']),
        hasFreeCall = json['hasFreeCall'],
        planName = json['planName'],
        planUnlimited = json['planUnlimited'],
        planUsageBreakdownList = (json['usageBreakdown'] as List<dynamic>).map((e) => PlanUsageBreakdown.fromJson(e)).toList(growable: false),
        primary = json['primary'],
        timeUntilNextFreeCall = (json['timeUntilNextFreeCall'] as String?)?.dateTimeZ,
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