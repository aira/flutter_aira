class Track {
  int id;
  int participantId;
  int? incomingTrackId;
  String? audioType;
  String? videoType;

  Track.fromJson(Map<String, dynamic> json)
      : id = int.parse(json['id']),
        participantId = json['participantId'],
        incomingTrackId = int.tryParse(json['incomingTrackId'] ?? ''),
        // determines track type, values : recvonly - sendonly
        audioType = json['audio'],
        videoType = json['video'];

  // determining kind of incoming track based on nullity check of audio and video type
  // only one is not null for incoming track
  TrackKind? get kind {
    if (audioType != null) return TrackKind.audio;
    if (videoType != null) return TrackKind.video;
    return null;
  }

  bool get isOutgoing => incomingTrackId == null;
}

enum TrackKind { audio, video }
