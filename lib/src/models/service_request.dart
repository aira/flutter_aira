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
  final List<dynamic> stunServers;
  final List<dynamic> turnServers;
  /// If iceService is not empty, it should be used instead of building the
  /// ice server list from stunServers and turnServers.
  final List<dynamic> iceServers;

  ServiceRequest.fromJson(Map<String, dynamic> json)
      : id = json['serviceId'],
        participantId = json['userWebrtcParticipantId'],
        roomId = json['webrtcRoomId'],
        userId = json['userId'],
        stunServers = json['stunServers'],
        turnServers = json['turnServers'],
        iceServers = json['iceServers'] ?? [];
}
