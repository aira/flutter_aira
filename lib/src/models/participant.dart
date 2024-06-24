import 'track.dart';

// ignore_for_file: constant_identifier_names
enum ParticipantStatus {
  /// The participant is sending both audio and video.
  ONLINE,

  /// The participant is in full privacy mode and not sending audio or video.
  PRIVACY,

  /// The participant is in partial privacy mode and sending audio only.
  PRIVACY_AUDIO_ONLY,

  /// The participant is in partial privacy mode and sending video only.
  PRIVACY_VIDEO_ONLY,
}

extension ParticipantStatusExtension on ParticipantStatus {
  get name => toString().split('.').last;
}

class Participant {
  int id;
  List<Track>? tracks;

  Participant.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        tracks = (json['tracks'] as List<dynamic>)
            .map((track) => Track.fromJson(track))
            .toList(growable: false);
}
