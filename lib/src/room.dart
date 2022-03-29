import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logging/logging.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'models/participant.dart';
import 'models/participant_message.dart';
import 'models/service_request.dart';
import 'models/track.dart';
import 'platform_client.dart';
import 'platform_mq.dart';
import 'sfu_connection.dart';

abstract class RoomHandler {
  /// Adds the remote stream to an [RTCVideoRenderer].
  Future<void> addRemoteStream(MediaStream stream);
}

abstract class Room implements Listenable {
  /// Returns the ID of the service request.
  int get serviceRequestId;

  /// Returns the state of the service request.
  ServiceRequestState get serviceRequestState;

  /// Returns the name of the Agent assigned to the service request.
  ///
  /// If the service request has not yet been assigned, this will return `null`.
  String? get agentName;

  /// Joins the room with the provided local audio and video stream.
  ///
  /// If the room should be joined with the audio and/or video muted, disable the corresponding track(s) before calling
  /// [join].
  Future<void> join(MediaStream localStream);

  /// Mutes or un-mutes the local audio stream.
  void setAudioMuted(bool muted);

  /// Mutes or un-mutes the local video stream.
  void setVideoMuted(bool muted);

  /// Leaves the room and discards any resources used.
  ///
  /// After this is called, the object is not in a usable state and should be discarded.
  Future<void> dispose();
}

class KurentoRoom extends ChangeNotifier implements Room {
  final Logger _log = Logger('KurentoRoom');

  final PlatformEnvironment _env;
  final PlatformClient _client;
  final PlatformMQ _mq;
  final ServiceRequest _serviceRequest;
  final RoomHandler _roomHandler;

  final Map<int, SfuConnection> _connectionByTrackId = {};

  bool _disposed = false;
  ServiceRequestState _serviceRequestState = ServiceRequestState.queued;
  String? _agentName;
  MediaStream? _localStream;

  KurentoRoom(this._env, this._client, this._mq, this._serviceRequest, this._roomHandler) {
    // Asynchronously subscribe to the room-related topics.
    // REVIEW: If these subscriptions fail, we're not going to get anywhere. How should we handle errors? Could we
    // add a "error" room state and notify listeners that something's wrong?
    _mq.subscribe(_serviceRequestPresenceTopic, MqttQos.atLeastOnce, _handleServiceRequestPresenceMessage);
    _mq.subscribe(_participantTopic, MqttQos.atLeastOnce, _handleParticipantMessage);
  }

  @override
  int get serviceRequestId => _serviceRequest.id;

  @override
  ServiceRequestState get serviceRequestState => _serviceRequestState;

  @override
  String? get agentName => _agentName;

  // The audio is muted if there is no audio track or if the first audio track is disabled.
  bool get _isAudioMuted => _localStream!.getAudioTracks().isEmpty ? true : !_localStream!.getAudioTracks()[0].enabled;

  // The video is muted if there is no video track or if the first video track is disabled.
  bool get _isVideoMuted => _localStream!.getVideoTracks().isEmpty ? true : !_localStream!.getVideoTracks()[0].enabled;

  String get _participantTopic =>
      '${_env.name}/webrtc/room/${_serviceRequest.roomId}/participant/${_serviceRequest.participantId}';

  String get _roomTopic => '${_env.name}/webrtc/room/${_serviceRequest.roomId}';

  String get _serviceRequestPresenceTopic => '${_env.name}/user/${_serviceRequest.userId}/service-request/presence';

  @override
  Future<void> join(MediaStream localStream) async {
    _localStream = localStream;

    // Create a track for the Explorer audio and video.
    // REVIEW: Instead of connecting the real stream now, we could connect a dummy stream and then replace the tracks
    // after the call has started. That way, we won't be recording audio and video prematurely. See
    // https://w3c.github.io/webrtc-pc/#advanced-peer-to-peer-example-with-warm-up for a how-to.
    Track track = await _client.createTrack(_serviceRequest.roomId, _serviceRequest.participantId);
    _log.info('created outgoing track id=${track.id}');

    // Start the WebRTC signaling process.
    await _connectTrack(track.id, _localStream);
  }

  @override
  void setAudioMuted(bool muted) {
    if (_localStream == null) {
      throw StateError('Cannot mute audio before joining the room');
    }

    _localStream!.getAudioTracks()[0].enabled = !muted;
    _updateParticipantStatus();
  }

  @override
  void setVideoMuted(bool muted) {
    if (_localStream == null) {
      throw StateError('Cannot mute video before joining the room');
    }

    _localStream!.getVideoTracks()[0].enabled = !muted;
    _updateParticipantStatus();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;

    _mq.unsubscribe(_serviceRequestPresenceTopic);
    _mq.unsubscribe(_participantTopic);

    if (_serviceRequestState != ServiceRequestState.ended) {
      if (_serviceRequestState == ServiceRequestState.queued) {
        _client.cancelServiceRequest(_serviceRequest.id);
      } else {
        _client.endServiceRequest(_serviceRequest.id);
      }
    }

    for (SfuConnection connection in _connectionByTrackId.values) {
      connection.dispose();
    }

    super.dispose();
  }

  void _handleParticipantMessage(String message) async {
    ParticipantMessage participantMessage = ParticipantMessage.fromJson(jsonDecode(message));
    switch (participantMessage.type) {
      case ParticipantMessageType.ICE_CANDIDATE:
        RTCIceCandidate candidate = RTCIceCandidate(participantMessage.payload['candidate']!,
            participantMessage.payload['sdpMid']!, participantMessage.payload['sdpMLineIndex']);
        if (_connectionByTrackId.containsKey(participantMessage.trackId)) {
          _connectionByTrackId[participantMessage.trackId]!.handleIceCandidate(candidate);
        } else {
          _log.warning('ignoring participant message for unknown track '
              'type=${participantMessage.type} track_id=${participantMessage.trackId}');
        }
        break;

      case ParticipantMessageType.INCOMING_TRACK_CREATE:
        // Create a track for the Agent audio.
        Track track = await _client.createTrack(
            _serviceRequest.roomId, _serviceRequest.participantId, participantMessage.trackId);
        _log.info('created incoming track id=${track.id} outgoing_track_id=${participantMessage.trackId}');

        // Start the WebRTC signaling process.
        _connectTrack(track.id);
        break;

      case ParticipantMessageType.SDP_ANSWER:
        RTCSessionDescription answer =
            RTCSessionDescription(participantMessage.payload['sdp'], participantMessage.payload['type']);
        if (_connectionByTrackId.containsKey(participantMessage.trackId)) {
          _connectionByTrackId[participantMessage.trackId]!.handleSdpAnswer(answer);
        } else {
          _log.warning('ignoring participant message for unknown track '
              'type=${participantMessage.type} track_id=${participantMessage.trackId}');
        }
        break;

      default:
        _log.warning('ignoring unsupported participant message type=${participantMessage.type}');
    }
  }

  void _handleServiceRequestPresenceMessage(String message) async {
    Map<String, dynamic> json = jsonDecode(message);
    if (json['id'] != _serviceRequest.id) {
      // Ignore status updates for other service requests (right now, Platform enforces that an Explorer can only be in
      // one session, but that may change in the future).
      return;
    }

    _log.info('service request status changed id=${json['id']} status=${json['status']}');

    switch (json['status']) {
      case 'ASSIGNED':
        _serviceRequestState = ServiceRequestState.assigned;
        _agentName = json['agentFirstName'];
        break;

      case 'STARTED':
        _serviceRequestState = ServiceRequestState.started;

        // Now that the Agent has joined the room, publish our participant status.
        _updateParticipantStatus();

        break;

      default:
        _serviceRequestState = ServiceRequestState.ended;
    }

    // Notify listeners of the state change.
    notifyListeners();
  }

  Future<void> _connectTrack(int trackId, [MediaStream? stream]) async {
    if (_connectionByTrackId.containsKey(trackId)) {
      // We've already connected the track.
      return;
    }

    SfuConnection connection =
        SfuConnection(trackId, _handleConnectionState, _handleIceCandidate, _handleSdpOffer, _handleTrack, stream);

    _connectionByTrackId[trackId] = connection;

    return connection.connect(_serviceRequest.stunServers, _serviceRequest.turnServers);
  }

  void _handleConnectionState(int trackId, RTCPeerConnectionState state) {
    // REVIEW: Should the room expose the connection state (e.g. `isAgentStreamConnected`, `isExplorerStreamConnected`)?
    _log.info('connection state changed track_id=$trackId state=$state');
  }

  void _handleIceCandidate(int trackId, RTCIceCandidate candidate) {
    ParticipantMessage message = ParticipantMessage(
        ParticipantMessageType.ICE_CANDIDATE,
        trackId,
        _serviceRequest.participantId,
        {'candidate': candidate.candidate, 'sdpMid': candidate.sdpMid, 'sdpMLineIndex': candidate.sdpMLineIndex});
    _mq.publish(_roomTopic, MqttQos.atLeastOnce, jsonEncode(message.toJson()));
  }

  void _handleSdpOffer(int trackId, RTCSessionDescription sessionDescription) {
    ParticipantMessage message = ParticipantMessage(ParticipantMessageType.SDP_OFFER, trackId,
        _serviceRequest.participantId, {'type': sessionDescription.type, 'sdp': sessionDescription.sdp});
    _mq.publish(_roomTopic, MqttQos.atLeastOnce, jsonEncode(message.toJson()));
  }

  void _handleTrack(int trackId, RTCTrackEvent event) {
    _roomHandler.addRemoteStream(event.streams[0]);
  }

  Future<void> _updateParticipantStatus() async {
    if (_serviceRequestState != ServiceRequestState.started) {
      // If the Agent hasn't joined the room yet, there's no point in publishing our participant status.
      return;
    }

    ParticipantStatus status = ParticipantStatus.ONLINE;
    if (_isAudioMuted && _isVideoMuted) {
      status = ParticipantStatus.PRIVACY;
    } else if (_isAudioMuted) {
      status = ParticipantStatus.PRIVACY_VIDEO_ONLY;
    } else if (_isVideoMuted) {
      status = ParticipantStatus.PRIVACY_AUDIO_ONLY;
    }

    try {
      await _client.updateParticipantStatus(_serviceRequest.roomId, _serviceRequest.participantId, status);
      _log.info('updated participant status=${status.name}');
    } catch (e) {
      _log.shout('failed to update participant status=${status.name}', e);
    }
  }
}
