enum ServiceRequestState {
  /// The service request is in the queue.
  queued,

  /// The service request has been assigned to an Agent.
  assigned,

  /// The assigned Agent has joined the room and billing has started.
  started,

  /// The service request has ended.
  ended,
}

class ServiceRequest {
  final int id;
  final int participantId;
  final int roomId;
  final int userId;
  final int accountId;
  final List<dynamic> stunServers;
  final List<dynamic> turnServers;

  ServiceRequest.fromJson(Map<String, dynamic> json)
      : id = json['serviceId'],
        participantId = json['userWebrtcParticipantId'],
        roomId = json['webrtcRoomId'],
        userId = json['userId'],
        accountID = json['accountId']
        stunServers = json['stunServers'],
        turnServers = json['turnServers'];
}
