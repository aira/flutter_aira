import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Represents a single incoming or outgoing connection to the selective forwarding unit (SFU).
class SfuConnection {
  final int trackId;
  final MediaStream? _localStream;
  late final RTCPeerConnection _peerConnection;
  late final RTCRtpTransceiver _audio;
  late final RTCRtpTransceiver _video;

  final Function(int trackId, RTCPeerConnectionState) onConnectionState;
  final Function(int trackId, RTCIceCandidate candidate) onIceCandidate;
  final Function(int trackId, RTCSessionDescription offer) onSdpOffer;
  final Function(int trackId, RTCTrackEvent event) onTrack;

  /// Creates a new [SfuConnection].
  ///
  /// Provide [_localStream] if this is an outgoing connection sending the stream's audio and video to the SFU;
  /// otherwise, this is an incoming connection receiving audio from the SFU.
  SfuConnection(this.trackId, this.onConnectionState, this.onIceCandidate, this.onSdpOffer, this.onTrack,
      [MediaStream? localStream])
      : _localStream = localStream;

  /// Connects to the SFU.
  Future<void> connect(List<dynamic> stunServers, List<dynamic> turnServers) async {
    Map<String, dynamic> configuration = _getConfiguration(stunServers, turnServers);

    // Create the peer connection.
    _peerConnection = await createPeerConnection(configuration)
      ..onConnectionState = ((state) => onConnectionState.call(trackId, state))
      ..onIceCandidate = ((candidate) => onIceCandidate.call(trackId, candidate))
      ..onTrack = ((event) => onTrack.call(trackId, event));

    if (_localStream == null) {
      // Add a transceiver for receiving audio.
      _audio = await _peerConnection.addTransceiver(
          kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
          init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly));
    } else {
      // Add transceivers for sending audio and video.
      // REVIEW: Do we need to set any encoding options, similar to
      // https://github.com/flutter-webrtc/flutter-webrtc-demo/blob/b2a495d8888fa84da9c8eba164cb2c8d46988a44/lib/src/call_sample/signaling.dart#L352-L373?
      _audio = await _peerConnection.addTransceiver(
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendOnly, streams: [_localStream!]),
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        track: _localStream!.getAudioTracks()[0],
      );
      if (_localStream!.getVideoTracks().isNotEmpty) {
        _video = await _peerConnection.addTransceiver(
          init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendOnly, streams: [_localStream!]),
          kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
          track: _localStream!.getVideoTracks()[0],
        );
      } else {
        _video = await _peerConnection.addTransceiver(
          init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendOnly),
          kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        );
      }
    }

    // Create the SDP offer.
    RTCSessionDescription offer = await _peerConnection.createOffer({
      'mandatory': {
        'OfferToReceiveAudio': _localStream == null,
        'OfferToReceiveVideo': false,
      },
      'optional': [],
    });
    await _peerConnection.setLocalDescription(offer);

    // Send the SDP offer to the SFU.
    onSdpOffer.call(trackId, offer);
  }

  Future<void> replaceTrack(MediaStreamTrack track) async {
    if (_localStream == null) {
      throw StateError('Cannot replace track on incoming connection');
    }

    // Find the right kind of sender and replace its track.
    if (track.kind == 'audio') {
      await _audio.sender.replaceTrack(track);
    } else {
      await _video.sender.replaceTrack(track);
    }
  }

  /// Handles an ICE candidate from the SFU.
  Future<void> handleIceCandidate(RTCIceCandidate candidate) => _peerConnection.addCandidate(candidate);

  /// Handles an SDP answer from the SFU.
  Future<void> handleSdpAnswer(RTCSessionDescription answer) => _peerConnection.setRemoteDescription(answer);

  /// Disconnects from the SFU.
  Future<void> dispose() {
    return _peerConnection.close();
  }

  Map<String, dynamic> _getConfiguration(List<dynamic> stunServers, List<dynamic> turnServers) {
    Map<String, dynamic> configuration = {
      'sdpSemantics': 'unified-plan',
    };

    List<dynamic> iceServers = [];

    for (Map<String, dynamic> stunServer in stunServers) {
      iceServers.add({'urls': 'stun:${stunServer['address']}'});
    }

    for (Map<String, dynamic> turnServer in turnServers) {
      iceServers.add({
        'urls': 'turn:${turnServer['address']}',
        'username': turnServer['username'],
        'credential': turnServer['password'],
      });
    }

    configuration['iceServers'] = iceServers;

    return configuration;
  }
}
