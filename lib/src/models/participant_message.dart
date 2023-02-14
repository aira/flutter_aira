// ignore_for_file: constant_identifier_names
enum ParticipantMessageType {
  ICE_CANDIDATE,
  INCOMING_TRACK_CREATE,
  INCOMING_TRACK_REMOVE,
  SDP_ANSWER,
  SDP_OFFER,
  TRACK_ERROR,
}

extension ParticipantMessageTypeExtension on ParticipantMessageType {
  get name => toString().split('.').last;

  static ParticipantMessageType fromName(String name) => ParticipantMessageType.values
      .firstWhere((type) => type.name == name, orElse: () => throw UnimplementedError(name));
}

class ParticipantMessage {
  ParticipantMessageType type;
  int trackId;
  int participantId;
  Map<String, dynamic> payload;

  ParticipantMessage(this.type, this.trackId, this.participantId, this.payload);

  ParticipantMessage.fromJson(Map<String, dynamic> json)
      : this(
          ParticipantMessageTypeExtension.fromName(json['type']),
          int.parse(json['trackId']),
          json['participantId'],
          json['payload'],
        );

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'trackId': trackId,
      'participantId': participantId,
      'payload': payload,
    };
  }
}
