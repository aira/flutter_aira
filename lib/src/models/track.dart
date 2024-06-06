class Track {
  int id;
  int participantId;
  int? incomingTrackId;
  TrackKind? kind;

  Track.fromJson(Map<String, dynamic> json)
      : id = int.parse(json['id']),
        participantId = json['participantId'],
        incomingTrackId = int.tryParse(json['incomingTrackId'] ?? ''),
        kind = json['audio'] ?? false ? TrackKind.audio : (json['video'] ?? false ? TrackKind.video : null);

  bool get isOutgoing => incomingTrackId == null;
}

enum TrackKind { audio, video }
