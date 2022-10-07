class PlanSubscription {
  String? planCode;
  String? name;
  String? subCycleEndDate;
  String? accountCode;
  String? subscriptionStatus;
  String? planType;
  int? createdDate;   //this is a string in platform schema
  int? subscriptionId;
  int? usageLimit;
  int? validityMonths;

  PlanSubscription.fromJson(Map<String, dynamic> json)
      : accountCode = json['accountCode'],
        createdDate = null == json['createdDate'] ? null : int.parse(json['createdDate']),
        name = json['name'],
        planType = json['planType'],
        subCycleEndDate = json['subCycleEndDate'],
        subscriptionId = json['subscriptionId'],
        subscriptionStatus = json['subscriptionStatus'],
        usageLimit = json['usageLimit'],
        validityMonths = json['validityMonths'],
        planCode = json['planCode'];
}

class PlanUsageBreakdown {
  String? firstName;
  int? userId;
  String? userType;
  int? minutesUsed;
  int? siteMinutesUsed;
  bool? isPaused;
  bool? paused;

  PlanUsageBreakdown.fromJson(Map<String, dynamic> json)
      : isPaused = json['isPaused'],
        minutesUsed = json['minutesUsed'],
        paused = json['paused'],
        siteMinutesUsed = json['siteMinutesUsed'],
        userId = json['userId'],
        userType = json['userType'],
        firstName = json['firstName'];
}

class PlanMinuteBreakdown {
  int? allocated;
  int? consumed;
  String? usageType;
  String? serviceType;
  String? productType;

  PlanMinuteBreakdown.fromJson(Map<String, dynamic> json)
      : allocated = json['allocated'],
        consumed = json['consumed'],
        usageType = json['usageType'],
        serviceType = json['serviceType'],
        productType = json['productType'];
}

class PlanUsage {
  String? planName;
  int? totalMinutes;
  int? totalMinutesLeft;
  int? totalPrimaryMinutes;
  int? totalPrimaryMinutesUsed;
  int? totalAccessMinutesUsed;
  int? totalProductMinutesUsed;
  int? totalPromotionMinutesUsed;
  int? totalSiteMinutesUsed;
  int? totalMinutesUsed;
  int? totalMinutesRolledOver;
  int? totalCreditMinutes;
  int? totalCreditMinutesUsed;
  int? totalPrivateSiteMinutes;
  int? totalPrivateSiteMinutesUsed;
  int? totalFixedMinutes;
  int? totalFixedMinutesUsed;
  int? billingCycleStart;
  int? billingCycleEnd;
  String? billingCycleStartDate;
  String? billingCycleEndDate;
  bool? canPurchaseMinutes;
  bool? canModifyPlan;
  bool? hasFreeCall;
  String? timeUntilNextFreeCall;
  bool? primary;
  bool? planUnlimited;

  List<PlanUsageBreakdown>? planUsageBreakdownList;
  List<PlanMinuteBreakdown>? planMinuteBreakdownList;

  PlanUsage.fromJson(Map<String, dynamic> json)
      : billingCycleEnd = json['billingCycleEnd'],
        billingCycleEndDate = json['billingCycleEndDate'],
        billingCycleStart = json['billingCycleStart'],
        billingCycleStartDate = json['billingCycleStartDate'],
        canModifyPlan = json['canModifyPlan'],
        canPurchaseMinutes = json['canPurchaseMinutes'],
        hasFreeCall = json['hasFreeCall'],
        planMinuteBreakdownList = (json['minuteBreakdown'] as List<dynamic>).map((e) => PlanMinuteBreakdown.fromJson(e)).toList(growable: false),
        planName = json['planName'],
        planUnlimited = json['planUnlimited'],
        planUsageBreakdownList = (json['usageBreakdown'] as List<dynamic>).map((e) => PlanUsageBreakdown.fromJson(e)).toList(growable: false),
        primary = json['primary'],
        timeUntilNextFreeCall = json['timeUntilNextFreeCall'],
        totalAccessMinutesUsed = json['totalAccessMinutesUsed'],
        totalCreditMinutes = json['totalCreditMinutes'],
        totalCreditMinutesUsed = json['totalCreditMinutesUsed'],
        totalFixedMinutes = json['totalFixedMinutes'],
        totalFixedMinutesUsed = json['totalFixedMinutesUsed'],
        totalMinutes = json['totalMinutes'],
        totalMinutesLeft = json['totalMinutesLeft'],
        totalMinutesRolledOver = json['totalMinutesRolledOver'],
        totalMinutesUsed = json['totalMinutesUsed'],
        totalPrimaryMinutes = json['totalPrimaryMinutes'],
        totalPrimaryMinutesUsed = json['totalPrimaryMinutesUsed'],
        totalPrivateSiteMinutes = json['totalPrivateSiteMinutes'],
        totalPrivateSiteMinutesUsed = json['totalPrivateSiteMinutesUsed'],
        totalProductMinutesUsed = json['totalProductMinutesUsed'],
        totalPromotionMinutesUsed = json['totalPromotionMinutesUsed'],
        totalSiteMinutesUsed = json['totalSiteMinutesUsed'];
}