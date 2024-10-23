import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_aira/flutter_aira.dart';
import 'package:flutter_aira/src/models/conversion_extension.dart';
import 'package:flutter_aira/src/models/track.dart';
import 'package:flutter_aira/src/platform_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logging/logging.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'models/participant.dart';
import 'models/participant_message.dart';
import 'platform_mq.dart';
import 'sfu_connection.dart';

typedef AccessOfferChangeCallback = void Function(
  AccessOfferDetails accessOffer,
  Duration? remainingTime,
);

abstract class RoomHandler {
  /// Adds a remote stream. This signals the client application that a new
  /// remote stream (participant) has join our video conferencing room.
  Future<void> addRemoteStream(int trackId, MediaStream stream);

  /// Removes a remote stream. This signals the client that a remote stream
  /// (participant) has been removed from out video conferencing room.
  Future<void> removeRemoteStream(int trackId);

  /// Takes a photo.
  Future<ByteBuffer> takePhoto();

  /// Toggle on and off the flashlight (torch). This API doesn't check if it is running on WEB or mobile.
  Future<void> toggleFlashlight();
}

abstract class Room implements Listenable {
  /// Called when a reconnect is initiated.
  VoidCallback? onReconnect;

  /// Called when a reconnect has completed.
  VoidCallback? onReconnected;

  /// Called when a reconnect has failed.
  VoidCallback? onReconnectionFailed;

  /// Called the connection to Aira Servers is lost. This will happen when the device can't connect through either:
  /// wifi, mobile data, bluetooth, ethernet or any other communication means.
  VoidCallback? onConnectionLost;

  VoidCallback? onConnectedSuccessfully;

  /// Called when a participant to the call has failed to connect.
  /// [isOutgoingConnection] indicates which type of connection failed.
  void Function(bool isOutgoingConnection)? onConnectionFailed;

  /// AccessOffer Change Notification.
  AccessOfferChangeCallback? onAccessOfferChange;

  /// The ID of the service request.
  int get serviceRequestId;

  /// The state of the service request.
  ServiceRequestState get serviceRequestState;

  /// The name of the Agent assigned to the service request.
  ///
  /// If the service request has not yet been assigned, this will return `null`.
  Map<String, String> get agentsName;

  /// Joins the room with the provided local audio and video stream.
  Future<void> join(MediaStream localStream);

  /// Whether the local audio is muted.
  bool get isAudioMuted;

  ///Whether the camera focus is centered.
  bool? get isCameraFocusCentered;

  /// Mutes or un-mutes the local audio.
  Future<void> setAudioMuted(bool muted);

  /// Whether the local video is muted.
  bool get isVideoMuted;

  /// Mutes or un-mutes the local video.
  Future<void> setVideoMuted(bool muted);

  /// Whether the presentation is muted.
  bool get isPresentationMuted;

  /// Mutes or un-mutes the presentation.
  Future<void> setPresentationMuted(bool muted);

  /// Enables or disables privacy mode.
  ///
  /// In privacy mode, the local audio, video and presentation are _all_ muted. This is equivalent to calling
  /// [setAudioMuted], [setVideoMuted] and [setPresentationMuted], and is intended as a convenience for apps that do not
  /// support muting the tracks independently.
  Future<void> setPrivacyMode(bool enabled);

  /// Starts presenting the provided display stream.
  Future<void> startPresenting(MediaStream displayStream);

  /// Stops presenting the display stream.
  Future<void> stopPresenting();

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
  // Private constructor.
  KurentoRoom._(
    this._env,
    this._client,
    Session session,
    this._serviceRequest,
    this._roomHandler,
  );

  static final Logger _log = Logger('KurentoRoom');

  final PlatformEnvironment _env;
  final PlatformClient _client;
  late final PlatformMQ _mq;
  @override
  final ServiceRequest _serviceRequest;
  final RoomHandler _roomHandler;

  final Map<int, SfuConnection> _connectionByTrackId = {};
  final Map<int, int> _incomingTrackIdByOutgoingTrackId = {};
  final Map<String, List<int>> _tracksByAgentId = {};

  bool _isDisposed = false;
  bool _isAudioMuted = false;
  bool _isVideoMuted = false;
  bool _isPresentationMuted = false;
  bool _isReconnecting = false;
  bool? _isCameraFocusCentered = false;
  MediaStream? _presentationStream;

  bool get _isPresenting => null != _presentationStream;
  ServiceRequestState _serviceRequestState = ServiceRequestState.queued;
  final Map<String, String> _agentsName = {};

  MediaStream? _localStream;
  int? _localTrackId;
  Timer? _getServiceRequestStatusTimer;
  StreamSubscription<List<ConnectivityResult>>?
      _connectivityMonitoringSubscription;
  ConnectivityResult? _currentlyUsedConnectionType;

  // Factory for creating an initialized room (idea borrowed from https://stackoverflow.com/a/59304510).
  static Future<Room> create(
    PlatformEnvironment env,
    PlatformClient client,
    Session session,
    ServiceRequest serviceRequest,
    RoomHandler roomHandler,
  ) async {
    KurentoRoom room = KurentoRoom._(
      env,
      client,
      session,
      serviceRequest,
      roomHandler,
    );
    try {
      await room._init(session);
      return room;
    } catch (e) {
      _log.shout('Unable to initialize the WebRTC Room.', e);
      // If something went wrong, trash the room.
      await room.dispose();
      rethrow;
    }
  }

  Future<void> _init(Session session) async {
    _mq = await PlatformMQImpl.create(
      _env,
      session,
      lastWillMessage: _lastWillMessage,
      lastWillTopic: _lastWillTopic,
    );
    // Asynchronously subscribe to the room-related topics.
    await _mq.subscribe(
      _participantEventTopic,
      MqttQos.atMostOnce,
      _handleParticipantEventMessage,
    );
    await _mq.subscribe(
      _participantTopic,
      MqttQos.atMostOnce,
      _handleParticipantMessage,
    );
    await _mq.subscribe(
      _serviceRequestPresenceTopic,
      MqttQos.atLeastOnce,
      _handleServiceRequestPresenceMessage,
    );
    await _mq.subscribe(
      _callEventsTopic,
      MqttQos.atLeastOnce,
      _handleCallEvents,
    );

    // HACK: The `_serviceRequestPresenceTopic` has been unreliable and we haven't yet figured out why. Until then,
    // we're backing it up by periodically checking the status of the service request.
    // FIXME: This timer eats up the exceptions thrown by the '_getServiceRequestStatus()' function which is an issue when the token is not valid anymore.
    _getServiceRequestStatusTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _getServiceRequestStatus(),
    );

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android) {
      _connectivityMonitoringSubscription = Connectivity()
          .onConnectivityChanged
          .listen(_handleConnectionRecovery);
    }
  }

  Future<void> _handleConnectionRecovery(
    List<ConnectivityResult> results,
  ) async {
    final result = results.firstOrNull;
    if (result != _currentlyUsedConnectionType) {
      // Status has changed
      if (ServiceRequestState.started == _serviceRequestState) {
        // Communication was previously established
        if (ConnectivityResult.none == result) {
          _log.info('Lost internet connection');
          onConnectionLost?.call();
        } else {
          _log.info('Now using connection type: $result. '
              'Restarting ice on ${_connectionByTrackId.length} webrtc connections!');
          for (var element in _connectionByTrackId.values) {
            await element.restartIce();
          }
          if (ConnectivityResult.none == _currentlyUsedConnectionType) {
            await _reconnect();
          }
        }
      }

      _currentlyUsedConnectionType = result;
    }
  }

  @override
  VoidCallback? onReconnect;

  @override
  VoidCallback? onReconnected;

  @override
  VoidCallback? onReconnectionFailed;

  @override
  VoidCallback? onConnectedSuccessfully;

  @override
  VoidCallback? onConnectionLost;

  @override
  void Function(bool isOutgoingConnection)? onConnectionFailed;

  @override
  AccessOfferChangeCallback? onAccessOfferChange;

  @override
  int get serviceRequestId => _serviceRequest.id;

  @override
  ServiceRequestState get serviceRequestState => _serviceRequestState;

  @override
  Map<String, String> get agentsName => _agentsName;

  @override
  bool get isAudioMuted => _isAudioMuted;

  @override
  bool? get isCameraFocusCentered => _isCameraFocusCentered;

  @override
  bool get isVideoMuted => _isVideoMuted;

  @override
  bool get isPresentationMuted => _isPresentationMuted;

  bool get _hasVideoTrack => _localStream?.getVideoTracks().isNotEmpty ?? false;

  String get _participantEventTopic =>
      '${_env.name}/webrtc/room/${_serviceRequest.roomId}/participant/${_serviceRequest.participantId}/event';

  String get _participantTopic =>
      '${_env.name}/webrtc/room/${_serviceRequest.roomId}/participant/${_serviceRequest.participantId}';

  String get _roomTopic => '${_env.name}/webrtc/room/${_serviceRequest.roomId}';

  String get _serviceRequestPresenceTopic =>
      '${_env.name}/user/${_serviceRequest.userId}/service-request/presence';

  String get _callEventsTopic => '${_env.name}/si/ts/${_serviceRequest.userId}';

  String get _serviceInfoTopic =>
      '${_env.name}/si/fg/${_serviceRequest.userId}';

  String get _gpsLocationTopic =>
      '${_env.name}/si/fs/${_serviceRequest.userId}/gps';

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
    await _createOutgoingTrack();
    // Attempt to update the participant status just in case we succeed at
    // joining the room after the ServiceRequest's status is set to "Started"
    await _updateParticipantStatus();
  }

  @override
  Future<void> setAudioMuted(bool muted) async {
    await _setAudioMuted(muted);
    await _updateParticipantStatus();
    _log.info('set audio muted=$muted');
  }

  @override
  Future<void> setVideoMuted(bool muted) async {
    await _setVideoMuted(muted);
    await _updateParticipantStatus();
    _log.info('set video muted=$muted');
  }

  @override
  Future<void> setPresentationMuted(bool muted) async {
    await _setPresentationMuted(muted);
    await _updateParticipantStatus();
    _log.info('set presentation muted=$muted');
  }

  @override
  Future<void> setPrivacyMode(bool enabled) async {
    await _setAudioMuted(enabled);
    await _setVideoMuted(enabled);
    await _setPresentationMuted(enabled);
    await _updateParticipantStatus();
    _log.info('set privacy mode enabled=$enabled');
  }

  @override
  Future<void> startPresenting(MediaStream displayStream) async {
    if (_localTrackId == null) {
      return;
    }
    // Eventually, we will create a separate connection for screen sharing. That requires changes to Platform and Dash,
    // so for now, we start presenting by replacing the Explorer's video track with the display video track.
    _presentationStream = await displayStream.clone();

    // Since we don't show the localStream's video and the presentation simultaneously, disabled it to free up some CPU.
    _localStream!.getVideoTracks()[0].enabled = false;
    if ((_localStream?.getAudioTracks().isNotEmpty ?? false) &&
        _presentationStream!.getAudioTracks().isEmpty) {
      // Set the presentation audio track to keep audio.
      await _presentationStream!.addTrack(_localStream!.getAudioTracks()[0]);
    }

    if (kIsWeb) {
      MediaStreamTrack presentationTrack =
          _presentationStream!.getVideoTracks()[0];
      await _connectionByTrackId[_localTrackId]!
          .replaceVideoTrack(_isPresentationMuted ? null : presentationTrack);
    } else {
      // Hack! Since the "replaceVideoTrack" function causes sporadically a pixelation of the video on mobile, we are
      // recreating the video track from scratch.
      await _client.deleteTrack(
        _serviceRequest.roomId,
        _serviceRequest.participantId,
        _localTrackId!,
      );
      await _createOutgoingTrack();
    }

    await _updateParticipantStatus();
    _log.info(
      'started presenting track=${_presentationStream!.getVideoTracks()[0].label}',
    );
  }

  @override
  Future<void> stopPresenting() async {
    if (_localTrackId == null) {
      return;
    }

    _localStream!.getVideoTracks()[0].enabled = true;
    if (null != _presentationStream) {
      // Properly disposing of the presentation tracks.
      if (_presentationStream!.getAudioTracks().isNotEmpty) {
        if (null != _localStream &&
            _presentationStream!.getAudioTracks()[0].id ==
                _localStream!.getAudioTracks()[0].id) {
          // If we are using _localStream's audio track, don't destroy it!
          await _presentationStream!
              .removeTrack(_localStream!.getAudioTracks()[0]);
        } else {
          await _presentationStream!.getAudioTracks()[0].stop();
        }
      }
      await _presentationStream!.getVideoTracks()[0].stop();
      await _presentationStream!.dispose();
      _presentationStream = null;
    }

    if (kIsWeb) {
      // Until we create a separate connection for screen sharing, we stop presenting by restoring the Explorer's video
      // track.
      await _connectionByTrackId[_localTrackId]!.replaceVideoTrack(
        _isVideoMuted || !_hasVideoTrack
            ? null
            : _localStream!.getVideoTracks()[0],
      );
    } else {
      // Hack! Since the "replaceVideoTrack" function causes sporadically a pixelation of the video on mobile, we are
      // recreating the video track from scratch.
      await _client.deleteTrack(
        _serviceRequest.roomId,
        _serviceRequest.participantId,
        _localTrackId!,
      );
      await _createOutgoingTrack();
    }

    await _updateParticipantStatus();
    _log.info('stopped presenting');
  }

  @override
  Future<void> replaceStream(MediaStream mediaStream) async {
    if (_localTrackId == null) {
      return; // NOOP: The connection is not initialized and this would fail.
    } else {
      // Replace the stored local stream.
      _localStream = mediaStream;

      // Replace the tracks.
      await _connectionByTrackId[_localTrackId]!.replaceAudioTrack(
        _isAudioMuted || mediaStream.getAudioTracks().isEmpty
            ? null
            : mediaStream.getAudioTracks()[0],
      );
      if (!_isPresenting) {
        await _connectionByTrackId[_localTrackId]!.replaceVideoTrack(
          _isVideoMuted || !_hasVideoTrack
              ? null
              : mediaStream.getVideoTracks()[0],
        );
      }

      await _updateParticipantStatus();
    }
  }

  @override
  Future<void> updateLocation(Position position) async {
    if (!_mq.isConnected) {
      _log.warning('MQTT client is not connected, cannot send gps coordinates');
      return;
    }
    if (ServiceRequestState.started != _serviceRequestState) {
      _log.warning(
        'ServiceRequest is not started yet, not sending position ($_serviceRequestState)',
      );
      return;
    }

    if (_client.shouldThrottlePositionUpdate) {
      // Same throttling delay as `PlatformClient.inquireForGPSActivatedOffer`.
      return;
    }

    List<Map<String, dynamic>> serviceInfoData = [
      {
        'instrumentationType': 'TYPE_GPS',
        'paramName': 'LAT',
        'paramValue': position.latitude,
      },
      {
        'instrumentationType': 'TYPE_GPS',
        'paramName': 'LONG',
        'paramValue': position.longitude,
      },
      {
        'instrumentationType': 'TYPE_GPS',
        'paramName': 'HORIZONTAL_ACCURACY',
        'paramValue': position.accuracy,
      },
      {
        'instrumentationType': 'TYPE_GPS',
        'paramName': 'BEARING',
        'paramValue': position.heading,
      },
      {
        'instrumentationType': 'TYPE_GPS',
        'paramName': 'BEARING_ACCURACY',
        'paramValue': position.headingAccuracy,
      },
      {
        'instrumentationType': 'TYPE_GPS',
        'paramName': 'ALTITUDE',
        'paramValue': position.altitude,
      },
      {
        'instrumentationType': 'TYPE_GPS',
        'paramName': 'VERTICAL_ACCURACY',
        'paramValue': position.verticalAccuracy,
      },
      {
        'instrumentationType': 'TYPE_GPS',
        'paramName': 'SPEED',
        'paramValue': position.speed,
      },
      {
        'instrumentationType': 'TYPE_GPS',
        'paramName': 'SPEED_ACCURACY',
        'paramValue': position.speedAccuracy,
      },
    ];

    Map<String, dynamic> gpsLocationData = {
      'userId': _serviceRequest.userId,
      'clientId': _client.clientId,
      'lt': position.latitude,
      'lg': position.longitude,
    };

    try {
      await Future.wait([
        _mq.publish(
          _serviceInfoTopic,
          MqttQos.atMostOnce,
          jsonEncode({'data': serviceInfoData}),
        ),
        _mq.publish(
          _gpsLocationTopic,
          MqttQos.atMostOnce,
          jsonEncode(gpsLocationData),
        ),
      ]);
      _log.finest(
          'Published location info\n\t$serviceInfoData\n\t$gpsLocationData'
          '\n\tat ${_client.lastLocationUpdateTimestamp.millisecondsSinceEpoch}');
    } catch (e) {
      _log.warning(
        'Unable to send data to topic $_serviceInfoTopic & $_gpsLocationTopic',
        e,
      );
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

    _getServiceRequestStatusTimer?.cancel();
    await _connectivityMonitoringSubscription?.cancel();

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
    if (json['type'] == 'FLASHLIGHT') {
      await _roomHandler.toggleFlashlight();
    } else if (json['type'] == 'PHOTO') {
      if (_isVideoMuted) {
        _log.warning('cannot take photo when video is muted');
        return;
      } else if (_isPresenting) {
        _log.warning('cannot take photo when presenting');
        return;
      }
      bool isCenterFocus = json['payload']?['centerFocus'] ?? false;
      _isCameraFocusCentered = isCenterFocus;

      try {
        await _client.uploadPhoto(
          _serviceRequest.id,
          await _roomHandler.takePhoto(),
        );
      } catch (e, s) {
        _log.shout('failed to take photo', e, s);
      }
    } else if (json['type'] == 'RECONNECT') {
      await _reconnect();
    } else {
      _log.warning('ignoring participant event message type=${json['type']}');
    }
  }

  Future<void> _handleCallEvents(String message) async {
    Map<String, dynamic> json = jsonDecode(message);
    String? trigger = json['trigger'];
    _log.finest('Got following trigger: $trigger');

    // When a GPS Activated Offer is activated during a call, we get a 'SERVICE_ACCESS' message with the offer's details
    if (trigger == 'SERVICE_ACCESS') {
      Map<String, dynamic> value = json['value'] ?? [];

      Map<String, dynamic> accessOfferJson = value['access'];
      Set<String> handledAccessOfferTypes =
          AccessOfferType.values.map((aot) => aot.name).toSet();
      if (handledAccessOfferTypes.contains(accessOfferJson['class'])) {
        AccessOfferDetails accessOffer =
            AccessOfferDetails.fromJson(accessOfferJson);
        if (null == accessOffer.durationPerCall ||
            accessOffer.durationPerCall! <= 0) {
          onAccessOfferChange?.call(accessOffer, null);
        } else {
          DateTime? startTime = (value['startTime'] as String?)?.dateTimeZ;
          DateTime? accessOfferValidUntil =
              startTime?.add(Duration(seconds: accessOffer.durationPerCall!));
          Duration? remainingTime =
              accessOfferValidUntil?.difference(DateTime.now());
          onAccessOfferChange?.call(accessOffer, remainingTime);
        }
      }
    }
  }

  Future<void> _handleParticipantMessage(String message) async {
    ParticipantMessage participantMessage =
        ParticipantMessage.fromJson(jsonDecode(message));
    switch (participantMessage.type) {
      case ParticipantMessageType.ICE_CANDIDATE:
        RTCIceCandidate candidate = RTCIceCandidate(
          participantMessage.payload['candidate']!,
          participantMessage.payload['sdpMid']!,
          participantMessage.payload['sdpMLineIndex'],
        );
        if (_connectionByTrackId.containsKey(participantMessage.trackId)) {
          await _connectionByTrackId[participantMessage.trackId]!
              .handleIceCandidate(candidate);
        } else {
          _log.warning('ignoring participant message for unknown track '
              'type=${participantMessage.type} track_id=${participantMessage.trackId}');
        }
        break;
      case ParticipantMessageType.INCOMING_TRACK_CREATE:
        await _createIncomingTrack(
          participantMessage.trackId,
          participantMessage.trackKind,
        );
        break;

      case ParticipantMessageType.INCOMING_TRACK_REMOVE:
        await _removeIncomingTrack(participantMessage.trackId);
        break;

      case ParticipantMessageType.SDP_ANSWER:
        RTCSessionDescription answer = RTCSessionDescription(
          participantMessage.payload['sdp'],
          participantMessage.payload['type'],
        );
        if (_connectionByTrackId.containsKey(participantMessage.trackId)) {
          await _connectionByTrackId[participantMessage.trackId]!
              .handleSdpAnswer(answer);
        } else {
          _log.warning('ignoring participant message for unknown track '
              'type=${participantMessage.type} track_id=${participantMessage.trackId}');
        }
        break;

      default:
        _log.warning(
          'ignoring unsupported participant message type=${participantMessage.type}',
        );
    }
  }

  Future<void> _getServiceRequestStatus() async {
    Map<String, String?> response =
        await _client.getServiceRequestStatus(_serviceRequest.id);

    await _updateServiceRequestStatus(
      response['status']!,
      response['agentFirstName'],
      response['agentId'],
    );
  }

  Future<void> _handleServiceRequestPresenceMessage(String message) async {
    Map<String, dynamic> json = jsonDecode(message);
    if (json['id'] != _serviceRequest.id) return;

    await _updateServiceRequestStatus(
      json['status'],
      json['agentFirstName'],
      json['agentId'].toString(),
    );
  }

  Future<void> _updateServiceRequestStatus(
    String status,
    String? agentFirstName,
    String? agentId,
  ) async {
    _log.info('updating service request status=$status');

    switch (status) {
      case 'REQUEST':
        // Nothing to do.
        break;

      case 'ASSIGNED':
        if (_serviceRequestState == ServiceRequestState.queued) {
          _serviceRequestState = ServiceRequestState.assigned;
          _agentsName[agentId!] = agentFirstName!;
          notifyListeners();
          break;
        }
        _agentsName[agentId!] = agentFirstName!;
        break;

      case 'STARTED':
        if (_serviceRequestState == ServiceRequestState.queued) {
          // HACK: If we still think we're queued, we missed a message. Notify listeners that we're assigned, and let
          // our periodic timer change this to started the next time it fires.
          _log.warning(
            'missed service request status message topic=$_serviceRequestPresenceTopic',
          );
          await _updateServiceRequestStatus(
            'ASSIGNED',
            agentFirstName,
            agentId,
          );
        } else if (_serviceRequestState == ServiceRequestState.assigned) {
          _serviceRequestState = ServiceRequestState.started;
          notifyListeners();

          // Once we've started, we no longer need the timer to consume resources. This means we may miss an
          // Agent-initiated end message, but the impact of that is low (the Explorer can end the call themselves).
          _getServiceRequestStatusTimer?.cancel();

          // Remove the follow logging once no longer needed.
          // Some logging to help diagnose issues related to videos when they
          // arise.
          final bool hasOutgoingVideoSenderTrack = null != _localTrackId &&
              _connectionByTrackId[_localTrackId!]?.ownsVideoTrack == true;
          if (!_hasVideoTrack || !hasOutgoingVideoSenderTrack || isVideoMuted) {
            _log.shout(
              'Starting a call without video. '
              'hasOutgoingVideoSenderTrack: $hasOutgoingVideoSenderTrack, '
              '_hasVideoTrack: $_hasVideoTrack, '
              '_localTrackId: ${null == _localTrackId ? 'null' : 'not null'}, '
              'isVideoMuted: $isVideoMuted',
            );
          }

          // Now that the Agent has joined the room, publish our participant status.
          await _updateParticipantStatus();
        }
        break;
      // Handles the case when the Agent leaves the room on a call transfer, name is turned to null to represent that agent is no longer in the call
      case 'LEFT':
        _agentsName.remove(agentId.toString());
        final trackIds = _tracksByAgentId[agentId];
        for (var trackId in trackIds!) {
          await _roomHandler.removeRemoteStream(trackId);
          _removeTracksOfAgent(trackId);
        }
        notifyListeners();
        break;

      case 'END':
      case 'CANCEL':
        if (_serviceRequestState != ServiceRequestState.ended) {
          _serviceRequestState = ServiceRequestState.ended;
          if (!_isDisposed) notifyListeners();
        }
        break;

      default:
        _log.warning('ignoring unsupported service request status=$status');
    }
  }

  Future<void> _connectTrack(
    int trackId, [
    MediaStream? stream,
    TrackKind? kind,
  ]) async {
    if (_connectionByTrackId.containsKey(trackId)) {
      // We've already connected the track.
      return;
    }

    SfuConnection connection = SfuConnection(
      direction: stream != null
          ? SfuConnectionDirection.outgoing
          : SfuConnectionDirection.incoming,
      onConnectionState: _handleConnectionState,
      onIceCandidate: _handleIceCandidate,
      onSdpOffer: _handleSdpOffer,
      onTrack: _handleTrack,
      trackId: trackId,
    );

    _connectionByTrackId[trackId] = connection;

    if (stream == null) {
      await connection.connect(
        _serviceRequest.stunServers,
        _serviceRequest.turnServers,
        _serviceRequest.iceServers,
        incomingTrackKind: kind,
      );
    } else {
      MediaStreamTrack? outgoingAudioTrack;
      if (stream.getAudioTracks().isNotEmpty && !_isAudioMuted) {
        outgoingAudioTrack = stream.getAudioTracks()[0];
      }

      MediaStreamTrack? outgoingVideoTrack;
      if (stream.getVideoTracks().isNotEmpty && !_isVideoMuted) {
        outgoingVideoTrack = stream.getVideoTracks()[0];
      }

      await connection.connect(
        _serviceRequest.stunServers,
        _serviceRequest.turnServers,
        _serviceRequest.iceServers,
        outgoingAudioTrack: outgoingAudioTrack,
        outgoingVideoTrack: outgoingVideoTrack,
      );
    }
  }

  void _handleConnectionState(int trackId, RTCPeerConnectionState state) {
    // This function is the place to handle connection state changes for the room. States like
    // ServiceRequestState.started could be handled here. It is currently handled through platform events which happen
    // after the connection state changes, so this is fine as it is, but we could have a better granularigy if this was
    // handled here.

    // REVIEW: Should the room expose the connection state (e.g. `isAgentStreamConnected`, `isExplorerStreamConnected`)?
    _log.info('connection state changed track_id=$trackId state=$state');
    if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
      onConnectedSuccessfully?.call();
    }
    if (RTCPeerConnectionState.RTCPeerConnectionStateFailed == state) {
      SfuConnection connection = _connectionByTrackId.remove(trackId)!;
      onConnectionFailed
          ?.call(connection.direction == SfuConnectionDirection.outgoing);
      unawaited(connection.dispose());
    }
  }

  Future<void> _handleIceCandidate(
    int trackId,
    RTCIceCandidate candidate,
  ) async {
    ParticipantMessage message = ParticipantMessage(
      ParticipantMessageType.ICE_CANDIDATE,
      trackId,
      _serviceRequest.participantId,
      {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      },
    );
    await _mq.publish(
      _roomTopic,
      MqttQos.atMostOnce,
      jsonEncode(message.toJson()),
    );
  }

  Future<void> _handleSdpOffer(
    int trackId,
    RTCSessionDescription sessionDescription,
  ) async {
    ParticipantMessage message = ParticipantMessage(
      ParticipantMessageType.SDP_OFFER,
      trackId,
      _serviceRequest.participantId,
      {
        'type': sessionDescription.type,
        'sdp': sessionDescription.sdp,
      },
    );
    await _mq.publish(
      _roomTopic,
      MqttQos.atMostOnce,
      jsonEncode(message.toJson()),
    );
  }

  Future<void> _handleTrack(int trackId, RTCTrackEvent event) async {
    await _roomHandler.addRemoteStream(trackId, event.streams[0]);
    // adds latest incoming tracks to the last agent
    final currentAgentId = agentsName.keys.last;
    _tracksByAgentId.putIfAbsent(currentAgentId, () => []).add(trackId);
  }

  Future<void> _updateParticipantStatus() async {
    if (_serviceRequestState != ServiceRequestState.started) {
      // If the Agent hasn't joined the room yet, there's no point in publishing our participant status.
      return;
    }

    bool isActiveVideoMuted = _isPresenting
        ? _isPresentationMuted
        : _isVideoMuted ||
            !_hasVideoTrack; // Dash displays a call with no video the same as a call with muted video.

    ParticipantStatus status = ParticipantStatus.ONLINE;
    if (_isAudioMuted && isActiveVideoMuted) {
      status = ParticipantStatus.PRIVACY;
    } else if (_isAudioMuted) {
      status = ParticipantStatus.PRIVACY_VIDEO_ONLY;
    } else if (isActiveVideoMuted) {
      status = ParticipantStatus.PRIVACY_AUDIO_ONLY;
    }

    try {
      await _client.updateParticipantStatus(
        _serviceRequest.roomId,
        _serviceRequest.participantId,
        status,
      );
      _log.info('updated participant status=${status.name}');
    } catch (e) {
      _log.shout('failed to update participant status=${status.name}', e);
    }
  }

  Future<void> _setAudioMuted(bool muted) async {
    _isAudioMuted = muted;

    // If we've connected audio to the room, mute or un-mute it.
    if (_localTrackId != null) {
      MediaStreamTrack? audioTrack;
      if (!muted && (_localStream?.getAudioTracks().isNotEmpty ?? false)) {
        audioTrack = _localStream!.getAudioTracks()[0];
      }

      await _connectionByTrackId[_localTrackId]!.replaceAudioTrack(audioTrack);
    }
  }

  Future<void> _setVideoMuted(bool muted) async {
    _isVideoMuted = muted;

    // If we've connected video to the room and we're not presenting, mute or un-mute it.
    if (_localTrackId != null && !_isPresenting) {
      MediaStreamTrack? videoTrack;
      if (!muted && _hasVideoTrack) {
        videoTrack = _localStream!.getVideoTracks()[0];
      }

      await _connectionByTrackId[_localTrackId]!.replaceVideoTrack(videoTrack);
    }
  }

  Future<void> _setPresentationMuted(bool muted) async {
    _isPresentationMuted = muted;

    // If we've connected a presentation to the room, mute or un-mute it.
    if (_localTrackId != null && _isPresenting) {
      if (muted) {
        await _connectionByTrackId[_localTrackId]!.replaceVideoTrack(null);
      } else {
        await _connectionByTrackId[_localTrackId]!
            .replaceVideoTrack(_presentationStream!.getVideoTracks()[0]);
      }
    }
  }

  /// Creates and connects a track to send the [_localStream] to Kurento.
  Future<void> _createOutgoingTrack() async {
    Track track = await _client.createTrack(
      _serviceRequest.roomId,
      _serviceRequest.participantId,
    );
    _log.info('created outgoing track id=${track.id}');

    _localTrackId = track.id;
    await _connectTrack(
      _localTrackId!,
      _isPresenting ? _presentationStream : _localStream,
    );
  }

  /// Creates and connects a track to receive a remote stream from Kurento.
  Future<void> _createIncomingTrack(
    int outgoingTrackId, [
    TrackKind? kind,
  ]) async {
    Track track = await _client.createTrack(
      _serviceRequest.roomId,
      _serviceRequest.participantId,
      outgoingTrackId,
    );
    _log.info(
      'created incoming track id=${track.id} outgoing_track_id=$outgoingTrackId -- kind= ${track.kind}',
    );

    _incomingTrackIdByOutgoingTrackId[outgoingTrackId] = track.id;

    await _connectTrack(track.id, null, kind);
  }

  /// Disconnects and disposes a track receiving a remote stream from Kurento.
  Future<void> _removeIncomingTrack(int outgoingTrackId) async {
    int? incomingTrackId =
        _incomingTrackIdByOutgoingTrackId.remove(outgoingTrackId);
    if (incomingTrackId == null) {
      _log.warning(
        'incoming track not found outgoing_track_id=$outgoingTrackId',
      );
      return;
    }
    await _roomHandler.removeRemoteStream(incomingTrackId);
    _removeTracksOfAgent(incomingTrackId);
    SfuConnection? connection = _connectionByTrackId.remove(incomingTrackId);
    if (connection != null) {
      await connection.dispose();
    }

    await _client.deleteTrack(
      _serviceRequest.roomId,
      _serviceRequest.participantId,
      incomingTrackId,
    );
    _log.info(
      'removed incoming track id=$incomingTrackId outgoing_track_id=$outgoingTrackId',
    );
  }

  Future<void> _reconnect() async {
    if (_isReconnecting) {
      _log.warning('a reconnect is already in progress');
      return;
    }
    _isReconnecting = true;

    try {
      _log.info('reconnecting');

      onReconnect?.call();

      // Delete the old tracks.
      await _client.deleteTracks(
        _serviceRequest.roomId,
        _serviceRequest.participantId,
      );

      // Close the old connections.
      for (SfuConnection connection in _connectionByTrackId.values) {
        await connection.dispose();
      }

      _connectionByTrackId.keys.forEach((trackId) async {
        await _roomHandler.removeRemoteStream(trackId);
      });

      _connectionByTrackId.clear();
      _incomingTrackIdByOutgoingTrackId.clear();
      _tracksByAgentId.clear();
      // Create and connect new tracks to receive the remote streams from the other participant(s). (Do this before our
      // local stream, since we want to be able to hear the Agent ASAP.)
      for (Participant participant
          in await _client.getParticipants(_serviceRequest.roomId)) {
        if (participant.id != _serviceRequest.participantId) {
          for (Track track in participant.tracks ?? []) {
            if (track.isOutgoing) {
              await _createIncomingTrack(track.id, track.kind);
            }
          }
        }
      }

      // Create and connect a new track to send our local stream.
      await _createOutgoingTrack();

      _log.info('reconnected');
      onReconnected?.call();
    } catch (e, s) {
      _log.shout('failed to reconnect', e, s);
      onReconnectionFailed?.call();
    } finally {
      _isReconnecting = false;
    }
  }

  void _removeTracksOfAgent(int incomingTrackId) {
    _tracksByAgentId.removeWhere((key, value) {
      return value.contains(incomingTrackId);
    });
  }
}
