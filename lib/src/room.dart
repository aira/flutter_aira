import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_aira/src/models/position.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logging/logging.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:pubnub/pubnub.dart' as pn;

import 'messaging_client.dart';
import 'models/message.dart';
import 'models/participant.dart';
import 'models/participant_message.dart';
import 'models/service_request.dart';
import 'models/session.dart';
import 'models/track.dart';
import 'platform_client.dart';
import 'platform_mq.dart';
import 'sfu_connection.dart';

abstract class RoomHandler {
  /// Adds the remote stream to an [RTCVideoRenderer].
  Future<void> addRemoteStream(MediaStream stream);

  /// Takes a photo.
  Future<ByteBuffer> takePhoto();
}

abstract class Room implements Listenable {
  /// The ID of the service request.
  int get serviceRequestId;

  /// The state of the service request.
  ServiceRequestState get serviceRequestState;

  /// The name of the Agent assigned to the service request.
  ///
  /// If the service request has not yet been assigned, this will return `null`.
  String? get agentName;

  /// Getter providing the [MessagingClient].
  ///
  /// If the application does not support messaging, the returned value will be null.
  MessagingClient? get messagingClient;

  /// A broadcast stream of messages sent and received.
  ///
  /// If the application does not support messaging, this will throw an exception.
  @Deprecated('This getter was moved into [MessagingClient].')
  Stream<Message> get messageStream;

  /// Joins the room with the provided local audio and video stream.
  ///
  /// If the room should be joined with the audio and/or video muted, disable the corresponding track(s) before calling
  /// [join].
  Future<void> join(MediaStream localStream);

  /// Whether the local audio is muted.
  bool get isAudioMuted;

  /// Mutes or un-mutes the local audio.
  Future<void> setAudioMuted(bool muted);

  /// Whether the local video is muted.
  bool get isVideoMuted;

  /// Mutes or un-mutes the local video.
  Future<void> setVideoMuted(bool muted);

  /// Enables or disables privacy mode.
  ///
  /// In privacy mode, both the local audio and video (if present) are muted. This is equivalent to calling both
  /// [setAudioMuted] and [setVideoMuted] and is intended as a convenience for apps that do not support muting the audio
  /// and video independently.
  Future<void> setPrivacyMode(bool enabled);

  /// Starts presenting the provided display stream.
  Future<void> startPresenting(MediaStream displayStream);

  Future<void> setPresentationMuted(bool muted);

  /// Stops presenting the display stream.
  Future<void> stopPresenting();

  /// Sends the provided message to the Agent.
  ///
  /// If the application does not support messaging, this will throw an exception.
  @Deprecated('This function was moved into [MessagingClient].')
  Future<void> sendMessage(String text);

  /// Replaces the local audio and video stream with the provided one.
  Future<void> replaceStream(MediaStream localStream);

  /// Leaves the room and discards any resources used.
  ///
  /// After this is called, the object is not in a usable state and should be discarded.
  Future<void> dispose();

  /// Function to call to update the location during a call. This function is meant to use in conjunction with a
  /// Position Stream which you can get through Flutter plugins like Geolocator and Location.
  Future<void> updateLocation(Position position);
}

class KurentoRoom extends ChangeNotifier implements Room {
  final Logger _log = Logger('KurentoRoom');

  final PlatformEnvironment _env;
  final PlatformClient _client;
  late final PlatformMQ _mq;
  @override
  final MessagingClient? messagingClient;
  final ServiceRequest _serviceRequest;
  final RoomHandler _roomHandler;

  final Map<int, SfuConnection> _connectionByTrackId = {};

  bool _isDisposed = false;
  bool _isAudioMuted = false;
  bool _isVideoMuted = false;
  MediaStreamTrack? _presentationVideoTrack;
  bool get _isPresenting => null != _presentationVideoTrack;
  ServiceRequestState _serviceRequestState = ServiceRequestState.queued;
  String? _agentName;
  MediaStream? _localStream;
  int? _localTrackId;
  pn.Subscription? _messageSubscription;

  // Private constructor.
  KurentoRoom._(
    this._env,
    this._client,
    Session session,
    this.messagingClient,
    this._serviceRequest,
    this._roomHandler,
  );

  Future<void> _init(Session session) async {
    _mq = await PlatformMQImpl.create(_env, session, lastWillMessage: _lastWillMessage, lastWillTopic: _lastWillTopic);
    // Asynchronously subscribe to the room-related topics.
    await _mq.subscribe(_participantEventTopic, MqttQos.atMostOnce, _handleParticipantEventMessage);
    await _mq.subscribe(_participantTopic, MqttQos.atMostOnce, _handleParticipantMessage);
    await _mq.subscribe(_serviceRequestPresenceTopic, MqttQos.atLeastOnce, _handleServiceRequestPresenceMessage);
  }

  // Factory for creating an initialized room (idea borrowed from https://stackoverflow.com/a/59304510).
  static Future<Room> create(PlatformEnvironment env, PlatformClient client, Session session,
      MessagingClient? messagingClient, ServiceRequest serviceRequest, RoomHandler roomHandler) async {
    KurentoRoom room = KurentoRoom._(env, client, session, messagingClient, serviceRequest, roomHandler);
    try {
      await room._init(session);
      return room;
    } catch (e) {
      // If something went wrong, trash the room.
      await room.dispose();
      rethrow;
    }
  }

  @override
  int get serviceRequestId => _serviceRequest.id;

  @override
  ServiceRequestState get serviceRequestState => _serviceRequestState;

  @override
  String? get agentName => _agentName;

  @override
  Stream<Message> get messageStream {
    if (messagingClient == null) {
      throw UnsupportedError('The application does not support messaging');
    } else {
      return messagingClient!.messageStream;
    }
  }

  String get _participantEventTopic =>
      '${_env.name}/webrtc/room/${_serviceRequest.roomId}/participant/${_serviceRequest.participantId}/event';

  String get _participantTopic =>
      '${_env.name}/webrtc/room/${_serviceRequest.roomId}/participant/${_serviceRequest.participantId}';

  String get _roomTopic => '${_env.name}/webrtc/room/${_serviceRequest.roomId}';

  String get _serviceRequestPresenceTopic => '${_env.name}/user/${_serviceRequest.userId}/service-request/presence';

  String get _serviceInfoTopic => '${_env.name}/si/fg/${_serviceRequest.userId}';

  String get _gpsLocationTopic => '${_env.name}/si/fs/${_serviceRequest.userId}/gps';

  // If the MQTT client disconnects ungracefully, the last-will message will cancel the service request if it is still
  // queued using Platform's (deprecated but functional) ServiceRequestsListener.
  String get _lastWillMessage => jsonEncode({
        'action': 'CANCEL',
        'requestType': 'AIRA',
        'serviceid': _serviceRequest.id,
        'userid': _serviceRequest.userId,
      });

  String get _lastWillTopic => '${_env.name}/sr/req';

  @override
  Future<void> join(MediaStream localStream) async {
    _localStream = localStream;

    // Create a track for the Explorer audio and video.
    // REVIEW: Instead of connecting the real stream now, we could connect a dummy stream and then replace the tracks
    // after the call has started. That way, we won't be recording audio and video prematurely. See
    // https://w3c.github.io/webrtc-pc/#advanced-peer-to-peer-example-with-warm-up for a how-to.
    Track track = await _client.createTrack(_serviceRequest.roomId, _serviceRequest.participantId);
    _log.info('created outgoing track id=${track.id}');

    _localTrackId = track.id;

    // Start the WebRTC signaling process.
    await _connectTrack(_localTrackId!, _localStream);
  }

  @override
  void setAudioMuted(bool muted) {
    if (_localStream == null) {
      throw StateError('Cannot mute audio before joining the room');
    }
    if (_localStream!.getAudioTracks().isEmpty) {
      throw StateError('Cannot mute audio because there is not audio tracks to mute');
    } else {
      _localStream!.getAudioTracks()[0].enabled = !muted;
      _updateParticipantStatus();
    }
  }

  @override
  void setVideoMuted(bool muted) {
    if (_localStream == null) {
      throw StateError('Cannot mute video before joining the room');
    }
    MediaStreamTrack? activeVideoTrack = _activeVideoTrack;
    if (null == activeVideoTrack) {
      throw StateError('Cannot mute video because there is not video tracks to mute');
    } else {
      activeVideoTrack.enabled = !muted;
      _updateParticipantStatus();
    }
  }

  @override
  Future<void> setPrivacyMode(bool enabled) async {
    if (_localStream == null) {
      throw StateError('Cannot set privacy mode before joining the room');
    }

    if (_localStream!.getAudioTracks().isNotEmpty) {
      _localStream!.getAudioTracks()[0].enabled = !enabled;
    }

    MediaStreamTrack? videoTrack = _activeVideoTrack;
    if (videoTrack != null) {
      videoTrack.enabled = !enabled;
    }

    await _updateParticipantStatus();
  }

  @override
  Future<void> startPresenting(MediaStream displayStream) async {
    // Eventually, we will create a separate connection for screen sharing. That requires changes to Platform and Dash,
    // so for now, we start presenting by replacing the Explorer's video track with the display video track.
    _presentationVideoTrack = displayStream.getVideoTracks()[0];
    await _connectionByTrackId[_localTrackId]!.replaceVideoTrack(_presentationVideoTrack);
    _log.info('started presenting track=${_presentationVideoTrack!.label}');
    await _updateParticipantStatus();
  }

  @override
  Future<void> stopPresenting() async {
    // Until we create a separate connection for screen sharing, we stop presenting by restoring the Explorer's video
    // track.
    await _connectionByTrackId[_localTrackId]!.replaceVideoTrack(
        _localStream!.getVideoTracks().isEmpty ? null : _localStream!.getVideoTracks()[0]
    );
    _presentationVideoTrack = null;
    _log.info('Stopped presenting');
    await _updateParticipantStatus();
  }

  @override
  Future<void> sendMessage(String text) async {
    if (messagingClient == null) {
      throw UnsupportedError('The application does not support messaging');
    } else {
      await messagingClient!.sendMessage(text);
    }
  }

  @override
  Future<void> replaceStream(MediaStream mediaStream) async {
    // Replace the stored local stream.
    _localStream = mediaStream;

    // Replace the tracks.
    await _connectionByTrackId[_localTrackId]!.replaceAudioTrack(
        mediaStream.getAudioTracks().isEmpty ? null : mediaStream.getAudioTracks()[0]
    );
    if (!_isPresenting) {
      await _connectionByTrackId[_localTrackId]!.replaceVideoTrack(
          mediaStream.getVideoTracks().isEmpty ? null : mediaStream.getVideoTracks()[0]
      );
    }

    // Publish our participant status using the mute states of the new local stream.
    await _updateParticipantStatus();
  }

  @override
  Future<void> updateLocation(Position position) async {
    if (!_mq.isConnected) {
      _log.warning('MQTT client is not connected, cannot send gps coordinates');
      return;
    }
    if (ServiceRequestState.started != _serviceRequestState) {
      _log.warning('ServiceRequest is not started yet, not sending position ($_serviceRequestState)');
      return;
    }

    List<Map<String, dynamic>> serviceInfoData = [
      {'instrumentationType': 'TYPE_GPS', 'paramName': 'LAT', 'paramValue': position.latitude},
      {'instrumentationType': 'TYPE_GPS', 'paramName': 'LONG', 'paramValue': position.longitude},
      {'instrumentationType': 'TYPE_GPS', 'paramName': 'HORIZONTAL_ACCURACY', 'paramValue': position.accuracy},
      {'instrumentationType': 'TYPE_GPS', 'paramName': 'BEARING', 'paramValue': position.heading},
      {'instrumentationType': 'TYPE_GPS', 'paramName': 'BEARING_ACCURACY', 'paramValue': position.headingAccuracy},
      {'instrumentationType': 'TYPE_GPS', 'paramName': 'ALTITUDE', 'paramValue': position.altitude},
      {'instrumentationType': 'TYPE_GPS', 'paramName': 'VERTICAL_ACCURACY', 'paramValue': position.verticalAccuracy},
      {'instrumentationType': 'TYPE_GPS', 'paramName': 'SPEED', 'paramValue': position.speed},
      {'instrumentationType': 'TYPE_GPS', 'paramName': 'SPEED_ACCURACY', 'paramValue': position.speedAccuracy},
    ];

    Map<String, dynamic> gpsLocationData = {
      'userId': _serviceRequest.userId,
      'lt': position.latitude,
      'lg': position.longitude,
    };

    try {
      _log.finest('Publish location info\n\t$serviceInfoData\n\t$gpsLocationData');
      await Future.wait([
        _mq.publish(_serviceInfoTopic, MqttQos.atMostOnce, jsonEncode({'data': serviceInfoData})),
        _mq.publish(_gpsLocationTopic, MqttQos.atMostOnce, jsonEncode(gpsLocationData)),
      ]);
    } catch (e) {
      _log.warning('Unable to send data to topic $_serviceInfoTopic & $_gpsLocationTopic', e);
    }
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;

    await _messageSubscription?.dispose();

    _mq.dispose();

    if (_serviceRequestState != ServiceRequestState.ended) {
      if (_serviceRequestState == ServiceRequestState.queued) {
        await _client.cancelServiceRequest(_serviceRequest.id);
      } else {
        await _client.endServiceRequest(_serviceRequest.id);
      }
    }

    for (SfuConnection connection in _connectionByTrackId.values) {
      await connection.dispose();
    }

    super.dispose();
  }

  Future<void> _handleParticipantEventMessage(String message) async {
    Map<String, dynamic> json = jsonDecode(message);
    if (json['type'] == 'PHOTO') {
      if (_isVideoMuted) {
        _log.warning('cannot take photo when video is muted');
        return;
      } else if (_isPresenting) {
        _log.warning('cannot take photo when presenting');
        return;
      }

      try {
        await _client.uploadPhoto(_serviceRequest.id, await _roomHandler.takePhoto());
      } catch (e, s) {
        _log.shout('failed to take photo', e, s);
      }
    } else {
      _log.warning('ignoring participant event message type=${json['type']}');
    }
  }

  Future<void> _handleParticipantMessage(String message) async {
    ParticipantMessage participantMessage = ParticipantMessage.fromJson(jsonDecode(message));
    switch (participantMessage.type) {
      case ParticipantMessageType.ICE_CANDIDATE:
        RTCIceCandidate candidate = RTCIceCandidate(participantMessage.payload['candidate']!,
            participantMessage.payload['sdpMid']!, participantMessage.payload['sdpMLineIndex']);
        if (_connectionByTrackId.containsKey(participantMessage.trackId)) {
          await _connectionByTrackId[participantMessage.trackId]!.handleIceCandidate(candidate);
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
        await _connectTrack(track.id);

        if (serviceRequestState == ServiceRequestState.queued) {
          // HACK: If the Agent is sending audio and we still think we're queued, we're not receiving messages on the
          // service request presence topic. Until we can figure out why this is happening, pretend we received a
          // message and transition the service request status to started.
          _log.shout('missed service request status message topic=$_serviceRequestPresenceTopic');
          _agentName = '';
          _serviceRequestState = ServiceRequestState.started;
          await _updateParticipantStatus();
          notifyListeners();
        }
        break;

      case ParticipantMessageType.SDP_ANSWER:
        RTCSessionDescription answer =
            RTCSessionDescription(participantMessage.payload['sdp'], participantMessage.payload['type']);
        if (_connectionByTrackId.containsKey(participantMessage.trackId)) {
          await _connectionByTrackId[participantMessage.trackId]!.handleSdpAnswer(answer);
        } else {
          _log.warning('ignoring participant message for unknown track '
              'type=${participantMessage.type} track_id=${participantMessage.trackId}');
        }
        break;

      default:
        _log.warning('ignoring unsupported participant message type=${participantMessage.type}');
    }
  }

  Future<void> _handleServiceRequestPresenceMessage(String message) async {
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
        await _updateParticipantStatus();

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

  Future<void> _handleIceCandidate(int trackId, RTCIceCandidate candidate) async {
    ParticipantMessage message = ParticipantMessage(
        ParticipantMessageType.ICE_CANDIDATE,
        trackId,
        _serviceRequest.participantId,
        {'candidate': candidate.candidate, 'sdpMid': candidate.sdpMid, 'sdpMLineIndex': candidate.sdpMLineIndex});
    await _mq.publish(_roomTopic, MqttQos.atMostOnce, jsonEncode(message.toJson()));
  }

  Future<void> _handleSdpOffer(int trackId, RTCSessionDescription sessionDescription) async {
    ParticipantMessage message = ParticipantMessage(ParticipantMessageType.SDP_OFFER, trackId,
        _serviceRequest.participantId, {'type': sessionDescription.type, 'sdp': sessionDescription.sdp});
    await _mq.publish(_roomTopic, MqttQos.atMostOnce, jsonEncode(message.toJson()));
  }

  Future<void> _handleTrack(int trackId, RTCTrackEvent event) async {
    await _roomHandler.addRemoteStream(event.streams[0]);
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
