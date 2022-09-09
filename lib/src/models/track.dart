class Track {
  int id;
  int participantId;
  int? incomingTrackId;

  Track.fromJson(Map<String, dynamic> json)
      : id = int.parse(json['id']),
        participantId = json['participantId'],
        incomingTrackId = int.tryParse(json['incomingTrackId'] ?? '');

  bool get isOutgoing => incomingTrackId == null;
}
