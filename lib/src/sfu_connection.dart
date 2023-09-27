import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// The direction of the connection to the selective forwarding unit (SFU).
enum SfuConnectionDirection {
  /// An incoming connection receiving audio from the SFU.
  incoming,

  /// An outgoing connection sending audio and (optionally) video to the SFU.
  outgoing,
}

/// Represents a single incoming or outgoing connection to the selective forwarding unit (SFU).
class SfuConnection {
  /// Creates a new [SfuConnection].
  SfuConnection({
    required this.direction,
    required this.onConnectionState,
    required this.onIceCandidate,
    required this.onSdpOffer,
    required this.onTrack,
    required this.trackId,
  });

  final int trackId;
  final SfuConnectionDirection direction;

  late final RTCPeerConnection _peerConnection;
  late final RTCRtpTransceiver _audio;
  late final RTCRtpTransceiver _video;
  RTCPeerConnectionState? _connectionState;

  bool get isConnectionFailed => _connectionState == RTCPeerConnectionState.RTCPeerConnectionStateFailed;

  final Function(int trackId, RTCPeerConnectionState) onConnectionState;
  final Function(int trackId, RTCIceCandidate candidate) onIceCandidate;
  final Function(int trackId, RTCSessionDescription offer) onSdpOffer;
  final Function(int trackId, RTCTrackEvent event) onTrack;

  bool get _isIncoming => direction == SfuConnectionDirection.incoming;

  /// Connects to the SFU.
  Future<void> connect(
    List<dynamic> stunServers,
    List<dynamic> turnServers, {
    MediaStreamTrack? outgoingAudioTrack,
    MediaStreamTrack? outgoingVideoTrack,
  }) async {
    Map<String, dynamic> configuration = _getConfiguration(stunServers, turnServers);

    // Create the peer connection.
    _peerConnection = await createPeerConnection(configuration)
      ..onConnectionState = ((state) {
        _connectionState = state;
        onConnectionState.call(trackId, state);
      })
      ..onIceCandidate = ((candidate) => onIceCandidate.call(trackId, candidate))
      ..onTrack = ((event) => onTrack.call(trackId, event));

    if (_isIncoming) {
      // Add a transceiver for receiving audio.
      _audio = await _peerConnection.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
    } else {
      // Add transceivers for sending audio and video.
      // REVIEW: Do we need to set any encoding options, similar to
      // https://github.com/flutter-webrtc/flutter-webrtc-demo/blob/b2a495d8888fa84da9c8eba164cb2c8d46988a44/lib/src/call_sample/signaling.dart#L352-L373?
      if (outgoingAudioTrack != null) {
        _audio = await _peerConnection.addTransceiver(
          init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendOnly),
          kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
          track: outgoingAudioTrack,
        );
      } else {
        _audio = await _peerConnection.addTransceiver(
          init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendOnly),
          kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        );
      }
      if (outgoingVideoTrack != null) {
        _video = await _peerConnection.addTransceiver(
          init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendOnly),
          kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
          track: outgoingVideoTrack,
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
        'OfferToReceiveAudio': _isIncoming,
        'OfferToReceiveVideo': false,
      },
      'optional': [],
    });
    await _peerConnection.setLocalDescription(offer);

    // Send the SDP offer to the SFU.
    onSdpOffer.call(trackId, offer);
  }

  Future<void> replaceAudioTrack(MediaStreamTrack? track) async {
    if (_isIncoming) {
      throw StateError('Cannot replace audio track on incoming connection');
    }
    if (kIsWeb || !Platform.isAndroid) {
      await _audio.sender.replaceTrack(track);
    } else {
      await _audio.sender.setTrack(track, takeOwnership: false);
    }
  }

  Future<void> replaceVideoTrack(MediaStreamTrack? track) async {
    if (_isIncoming) {
      throw StateError('Cannot replace video track on incoming connection');
    }
    if (kIsWeb || !Platform.isAndroid) {
      await _video.sender.replaceTrack(track);
    } else {
      await _video.sender.setTrack(track, takeOwnership: false);
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

  Map<String, dynamic> _getConfiguration(
    List<dynamic> stunServers,
    List<dynamic> turnServers,
  ) {
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

  Future<void> restartIce() {
    return _peerConnection.restartIce();
  }
}
