class CallSession {
  CallSession.fromJson(Map<String, dynamic> json)
      : agentId = json['agentId'],
        agentfirstname = json['agentfirstname'],
        agentlastname = json['agentlastname'],
        agentname = json['agentname'],
        callCount = json['callCount'],
        cannotTalk = json['cannotTalk'],
        durationMinutes = json['durationMinutes'],
        endTimeStamp = json['endTimeStamp'],
        firstCall = json['firstCall'],
        firstname = json['firstname'],
        guest = json['guest'],
        lastname = json['lastname'],
        onboardingComplete = json['onboardingComplete'],
        requestSource = json['requestSource'],
        requestTimeStamp = json['requestTimeStamp'],
        requestType = json['requestType'],
        serviceId = json['serviceId'],
        serviceid = json['serviceid'],
        startTimeStamp = json['startTimeStamp'],
        status = json['status'],
        testCall = json['testCall'],
        userId = json['userId'],
        username = json['username'];

  int userId;
  String? username;
  String? firstname;
  String? lastname;
  int? agentId;
  String? agentname;
  String? agentfirstname;
  String? agentlastname;
  String status;
  String requestType;
  String? requestTimeStamp; //treating dates as strings since thats how platform schema is set
  String? startTimeStamp;
  String? endTimeStamp;
  int? durationMinutes;
  int? serviceid;
  int? serviceId;
  String? requestSource;
  bool testCall;
  bool? firstCall;
  int? callCount;
  bool? onboardingComplete;
  bool? guest;
  bool cannotTalk;
}