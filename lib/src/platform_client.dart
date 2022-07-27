import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_aira/src/messaging_client.dart';
import 'package:flutter_aira/src/models/position.dart';
import 'package:flutter_aira/src/models/sent_file_info.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'models/credentials.dart';
import 'models/feedback.dart';
import 'models/participant.dart';
import 'models/profile.dart';
import 'models/service_request.dart';
import 'models/session.dart';
import 'models/track.dart';
import 'platform_exceptions.dart';
import 'room.dart';

/// The Platform client.
class PlatformClient {
  final _log = Logger('PlatformClient');

  // Reuse the HTTP client as a performance optimization.
  final http.Client _httpClient;

  // A random number generator for generating trace IDs.
  final _random = Random();

  final PlatformClientConfig _config;
  Session? _session;
  MessagingClient? messagingClient;

  int get _userId => _session!.userId;

  String get _token => _session!.token;

  /// Creates a new [PlatformClient] with the specified [PlatformClientConfig].
  ///
  /// [httpClient] can be provided if you want to use your own HTTP client (e.g. a
  /// [`SentryHttpClient`](https://docs.sentry.io/platforms/dart/usage/advanced-usage/)).
  PlatformClient(this._config, [http.Client? httpClient]) : _httpClient = httpClient ?? http.Client();

  /// Discards any resources associated with the [PlatformClient].
  ///
  /// After this is called, the object is not in a usable state and should be discarded.
  void dispose() {
    _httpClient.close();
  }

  /// Sends a verification code to a phone number.
  ///
  /// [countryCode] is the phone number's country code in ISO 3166-1 alpha-2 format (e.g. `US` or `CA`), [phoneNumber]
  /// is the phone number in E.164 format, and [recaptchaToken] is the optional reCAPTCHA Enterprise token.
  Future<void> sendPhoneVerificationCode(String countryCode, String phoneNumber, [String? recaptchaToken]) async {
    var body = jsonEncode({
      'countryCode': countryCode,
      'phoneNumber': phoneNumber,
      'recaptchaToken': recaptchaToken ?? '',
    });
    await _httpPost('/api/smartapp/verify', body);
  }

  /// Confirms a verification code that was sent to a phone number by [sendPhoneVerificationCode].
  ///
  /// [phoneNumber] is the phone number in E.164 format and [verificationCode] is the verification code. If successful,
  /// the returned [Credentials] can be used to [createAccount] (if [Credentials.isNewUser] is `true`) or to
  /// [loginWithCredentials].
  Future<Credentials> confirmPhoneVerificationCode(String phoneNumber, String verificationCode) async {
    String body = jsonEncode({
      'authCode': verificationCode,
      'phoneNumber': phoneNumber,
    });

    Map<String, dynamic> response = await _httpPost('/api/smartapp/verify/confirm', body);

    return Credentials('PHONE_VERIFICATION', phoneNumber, response['verificationCode'], response['newUser']);
  }

  /// Sends a verification code to an email address.
  ///
  /// [email] is the email address and [recaptchaToken] is the optional reCAPTCHA Enterprise token.
  Future<void> sendEmailVerificationCode(String email, [String? recaptchaToken]) async {
    String body = jsonEncode({
      'email': email,
      'recaptchaToken': recaptchaToken ?? '',
    });
    await _httpPost('/api/smartapp/verify/email', body);
  }

  /// Confirms a verification code that was sent to an email address by [sendEmailVerificationCode].
  ///
  /// [email] is the email address and [verificationCode] is the verification code. If successful,
  /// the returned [Credentials] can be used to [createAccount] (if [Credentials.isNewUser] is `true`) or to
  /// [loginWithCredentials].
  Future<Credentials> confirmEmailVerificationCode(String email, String verificationCode) async {
    String body = jsonEncode({
      'authCode': verificationCode,
      'email': email,
    });

    Map<String, dynamic> response = await _httpPost('/api/smartapp/verify/email/confirm', body);

    return Credentials('EMAIL_VERIFICATION', email, response['verificationCode'], response['newUser']);
  }

  /// Returns a verification code that can be used to log in the user to the specified client.
  Future<String> createClientVerificationCode(String clientId) async {
    Map<String, dynamic> response = await _httpPost(
      '/api/smartapp/verify/client',
      {'clientId': clientId},
      additionalHeaders: {'Content-Type': 'application/x-www-form-urlencoded'},
    );

    return response['payload'];
  }

  /// Logs in with a token.
  ///
  /// Throws a [PlatformInvalidTokenException] if the [token] is invalid.
  Future<Session> loginWithToken(String token, int userId) async {
    try {
      // Set X-Aira-Token ourselves instead of using the value in _userLogin (if set).
      var response = await _httpGet('/api/user/login/validate-token', additionalHeaders: {'X-Aira-Token': token});
      if (response['userId'] != userId) {
        // If we have somebody else's token, that's A Bad Thing.
        throw const PlatformInvalidTokenException();
      }

      _session = Session(token, userId);

      _initMessagingClient();

      return _session!;
    } on PlatformLocalizedException catch (e) {
      // Platform returns error code KN-UM-056 (NOT_A_USER_TOKEN) if the token is invalid.
      if (e.code == 'KN-UM-056') {
        throw const PlatformInvalidTokenException();
      } else {
        rethrow;
      }
    }
  }

  /// Logs in with [Credentials].
  Future<Session> loginWithCredentials(Credentials credentials) async {
    String body = jsonEncode({
      'authProvider': credentials.provider,
      'login': credentials.login,
      'loginfrom': 'AIRA SMART', // Platform knows the Explorer app as "AIRA SMART".
      'password': credentials.password,
    });

    _session = Session.fromJson(await _httpPost('/api/user/login', body));

    _initMessagingClient();

    return _session!;
  }

  /// Logs in with a client verification code.
  Future<Session> loginWithClientVerificationCode(String verificationCode) async {
    Map<String, dynamic> response = await _httpPost(
      '/api/smartapp/verify/client/confirm',
      {'verificationCode': verificationCode},
      additionalHeaders: {'Content-Type': 'application/x-www-form-urlencoded'},
    );

    Credentials credentials = Credentials(
      'PHONE_VERIFICATION',
      response['verificationCode'],
      response['phoneVerificationId'].toString(),
      response['newUser'],
    );

    return loginWithCredentials(credentials);
  }

  /// Logs out the user.
  Future<void> logout() async {
    // TODO: Actually log out. For now, we're copying the legacy apps and just removing the token.
    _session = null;
  }

  /// Creates an account.
  Future<Session> createAccount(Credentials credentials, {List<Language>? preferredLanguages}) async {
    String body = jsonEncode({
      'authProvider': credentials.provider,
      'login': credentials.login,
      'preferredLang': preferredLanguages?.map((language) => language.name).toList(growable: false),
      'tosAccepted': true,
      'verificationCode': credentials.password,
    });

    await _httpPost('/api/order/guest/basic', body);

    return loginWithCredentials(credentials);
  }

  /// Creates a service request for the logged-in user.
  ///
  /// [position] is used to start a call with an initial GPS location.
  ///
  /// [message] is used to start a call with a message which will be displayed to the Agent at connection time. This is
  /// especially useful if the Explorer cannot talk.
  ///
  /// [fileMap] is used to send files to the Agent as you start the call. This feature is usually used to save call time.
  ///
  /// [cannotTalk] will let hte agent know if the Explorer cannot talk at connection time.
  Future<Room> createServiceRequest(RoomHandler roomHandler,
      {Position? position, String? message, Map<String, List<int>>? fileMap, bool? cannotTalk}) async {
    _verifyIsLoggedIn();

    List<String> fileIds = await _sendPreCallMessage(message, fileMap);
    String fileNames = fileMap?.keys.join(', ') ?? '';

    Map<String, dynamic> context = {
      'app': await _appContext,
      'device': await _deviceContext,
      'permissions': {'location': null != position},
      'intent': 'NONE',
    };

    Map<String, dynamic> params = {
      'context': jsonEncode(context),
      'requestSource': _config.clientId,
      'requestType': 'AIRA', // Required but unused.
      'hasMessage': (null != message && message.isNotEmpty) || fileNames.isNotEmpty || true == cannotTalk,
      'message': '$message${fileNames.isEmpty ? '' : ' (With files: $fileNames)'}',
      'fileIds': fileIds,
      'cannotTalk': cannotTalk ?? false,
      'useWebrtcRoom': true,
    };

    if (null != position) {
      _log.finer('Adding gps coordinates to ServiceRequest query');
      params['latitude'] = position.latitude;
      params['longitude'] = position.longitude;
    }

    ServiceRequest serviceRequest =
        ServiceRequest.fromJson(await _httpPost('/api/user/$_userId/service-request', jsonEncode(params)));

    messagingClient?.serviceRequestId = serviceRequest.id;

    return KurentoRoom.create(_config.environment, this, _session!, messagingClient, serviceRequest, roomHandler);
  }

  Future<List<String>> _sendPreCallMessage(String? text, Map<String, List<int>>? fileMap) async {
    if (null == messagingClient) {
      throw UnsupportedError('The application does not support messaging');
    }
    _log.finest('Sending pre-call message (message: $text, files: ${fileMap?.keys.join(', ')})');
    String? message = text?.trim();
    await messagingClient!.sendStart();
    if (null != fileMap && fileMap.isNotEmpty) {
      if (fileMap.length == 1) {
        // If we have only one file, send it with the file.
        var fileEntry = fileMap.entries.first;
        SentFileInfo fileInfo = await messagingClient!.sendFile(fileEntry.key, fileEntry.value, text: message);
        return [fileInfo.id];
      } else {
        // if we have multiple files, send them separately from teh message
        if (null != message && message.isNotEmpty) {
          // Waiting on first message separately to insure it gets to the server first.
          await messagingClient!.sendMessage(message);
        }

        List<Future<SentFileInfo>> futureFileInfo =
            fileMap.entries.map((e) => messagingClient!.sendFile(e.key, e.value)).toList(growable: false);
        List<SentFileInfo> fileInfoList = await Future.wait(futureFileInfo);

        List<String> fileIds = fileInfoList.map((fi) => fi.id).toList(growable: false);
        return fileIds;
      }
    } else if (null != text && text.isNotEmpty) {
      await messagingClient!.sendMessage(text);
    }
    return [];
  }

  /// Cancels a service request.
  ///
  /// Throws a [PlatformLocalizedException] if the status of the service request is not `REQUEST`.
  Future<void> cancelServiceRequest(int serviceRequestId) async {
    _verifyIsLoggedIn();
    await _httpPut('/api/service-request/$serviceRequestId/CANCEL');
  }

  /// Ends a service request.
  ///
  /// Throws a [PlatformLocalizedException] if the status of the service request is not `STARTED`.
  Future<void> endServiceRequest(int serviceRequestId) async {
    _verifyIsLoggedIn();
    await _httpPut('/api/service-request/$serviceRequestId/END');
  }

  /// Gets the participants in a room.
  Future<List<Participant>> getParticipants(int roomId) async {
    _verifyIsLoggedIn();

    Map<String, dynamic> response = await _httpGet('/api/webrtc/room/$roomId/participant');

    return (response['payload'] as List<dynamic>)
        .map((participant) => Participant.fromJson(participant))
        .toList(growable: false);
  }

  /// Updates the status of a participant in a room.
  Future<void> updateParticipantStatus(int roomId, int participantId, ParticipantStatus status) async {
    _verifyIsLoggedIn();
    await _httpPut('/api/webrtc/room/$roomId/participant/$participantId/status/${status.name}');
  }

  /// Creates a track for a participant in a room.
  ///
  /// To create an incoming track, set [incomingTrackId] to the remote participant's track ID.
  Future<Track> createTrack(int roomId, int participantId, [int? incomingTrackId]) async {
    _verifyIsLoggedIn();

    String body = jsonEncode({
      'incomingTrackId': incomingTrackId ?? '',
    });
    return Track.fromJson(await _httpPost('/api/webrtc/room/$roomId/participant/$participantId/track', body));
  }

  /// Saves feedback for a service request.
  Future<void> saveFeedback(int serviceRequestId,
      {AgentFeedback? agentFeedback, Feedback? appFeedback, Feedback? offerFeedback}) async {
    _verifyIsLoggedIn();

    String body = jsonEncode({
      'serviceId': serviceRequestId,
      'comment': jsonEncode({
        'schemaVersion': 2,
        'agent': agentFeedback?.toJson(),
        'app': appFeedback?.toJson(),
        'offer': offerFeedback?.toJson(),
      }),
    });

    await _httpPost('/api/smartapp/feedback', body);
  }

  /// Uploads a photo for a service request.
  Future<void> uploadPhoto(int serviceRequestId, ByteBuffer photo) async {
    _verifyIsLoggedIn();

    try {
      Uri uri = Uri.https(_platformHost, '/api/files/upload');
      int traceId = _nextTraceId();
      Map<String, String> headers = await _getHeaders(traceId);

      Map<String, String> fields = {
        'category': 'sr_trigger',
        'entityid': _userId.toString(),
        'entitytype': 'user',
        'serviceid': serviceRequestId.toString(),
      };
      http.MultipartFile file = http.MultipartFile.fromBytes(
        'file',
        photo.asUint8List(),
        filename: 'photo', // Unused but required.
      );

      _log.finest('trace_id=$traceId method=POST uri=$uri fields=$fields');

      http.MultipartRequest request = http.MultipartRequest('POST', uri)
        ..fields.addAll(fields)
        ..files.add(file)
        ..headers.addAll(headers);

      http.StreamedResponse response = await _httpClient.send(request);
      _parseResponse(response.statusCode, await response.stream.bytesToString());
    } on SocketException catch (e) {
      throw PlatformUnknownException(e.message);
    }
  }

  Future<Map<String, dynamic>> _httpSend(String method, String unencodedPath,
      {Map<String, String>? additionalHeaders, Map<String, String>? queryParameters, Object? body}) async {
    try {
      Uri uri = Uri.https(_platformHost, unencodedPath, queryParameters);
      int traceId = _nextTraceId();
      Map<String, String> headers = await _getHeaders(traceId, additionalHeaders: additionalHeaders);

      _log.finest('trace_id=$traceId method=$method uri=$uri${body != null ? ' body=$body' : ''}');

      switch (method) {
        case 'GET':
          http.Response response = await _httpClient.get(uri, headers: headers);
          return _parseResponse(response.statusCode, response.body);
        case 'POST':
          http.Response response = await _httpClient.post(uri, headers: headers, body: body);
          return _parseResponse(response.statusCode, response.body);
        case 'PUT':
          http.Response response = await _httpClient.put(uri, headers: headers, body: body);
          return _parseResponse(response.statusCode, response.body);
        default:
          throw UnsupportedError(method);
      }
    } on SocketException catch (e) {
      throw PlatformUnknownException(e.message);
    }
  }

  Future<Map<String, dynamic>> _httpGet(String unencodedPath,
          {Map<String, String>? additionalHeaders, Map<String, String>? queryParameters}) async =>
      _httpSend('GET', unencodedPath, additionalHeaders: additionalHeaders, queryParameters: queryParameters);

  Future<Map<String, dynamic>> _httpPost(String unencodedPath, Object? body,
          {Map<String, String>? additionalHeaders}) async =>
      _httpSend('POST', unencodedPath, additionalHeaders: additionalHeaders, body: body);

  Future<Map<String, dynamic>> _httpPut(String unencodedPath,
          {Object? body, Map<String, String>? additionalHeaders}) async =>
      _httpSend('PUT', unencodedPath, additionalHeaders: additionalHeaders, body: body);

  void _verifyIsLoggedIn() {
    if (_session == null) {
      throw const PlatformInvalidTokenException();
    }
  }

  String get _platformHost {
    switch (_config.environment) {
      case PlatformEnvironment.dev:
        return 'dev-platform.aira.io';
      case PlatformEnvironment.prod:
        return 'platform.aira.io';
      default:
        throw UnimplementedError();
    }
  }

  Future<Map<String, String>> _getHeaders(int traceId, {Map<String, String>? additionalHeaders}) async {
    final headers = {
      'Content-Type': 'application/json',
      'X-API-Key': _config.apiKey,
      'X-Client-Id': _config.clientId,
      'X-Trace-Id': traceId.toString(),
    };

    if (_session != null) {
      headers['X-Aira-Token'] = _token;
      headers['X-User-Id'] = _userId.toString();
    }

    final deviceId = await _deviceId;
    if (deviceId != null) {
      headers['X-Device-Id'] = deviceId;
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  int _nextTraceId() {
    // Platform expects trace IDs to be long values, so we'll generate one and ensure that it's less than JavaScript's
    // MAX_SAFE_INTEGER (9007199254740991).
    return (_random.nextDouble() * 100000000000000).toInt();
  }

  Future<Map<String, dynamic>> get _appContext async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return {'version': '${packageInfo.version}+${packageInfo.buildNumber}'};
  }

  Future<Map<String, dynamic>> get _deviceContext async {
    if (kIsWeb) {
      WebBrowserInfo webBrowserInfo = await DeviceInfoPlugin().webBrowserInfo;
      return {
        'platform': webBrowserInfo.browserName.toString().split('.').last,
        'platformVersion': webBrowserInfo.appVersion,
      };
    } else {
      return {
        'platform': Platform.operatingSystem.toString().split('.').last,
        'platformVersion': Platform.operatingSystemVersion,
      };
    }
  }

  Future<String?> get _deviceId async {
    if (_config.deviceId != null) {
      return _config.deviceId;
    } else if (kIsWeb) {
      // We don't have a device ID for web.
      return null;
    } else if (Platform.isAndroid) {
      // Use https://developer.android.com/reference/android/provider/Settings.Secure#ANDROID_ID.
      return (await DeviceInfoPlugin().androidInfo).androidId;
    } else if (Platform.isIOS) {
      // Use https://developer.apple.com/documentation/uikit/uidevice/1620059-identifierforvendor.
      return (await DeviceInfoPlugin().iosInfo).identifierForVendor;
    } else {
      // We don't have a device ID for other platforms.
      return null;
    }
  }

  Map<String, dynamic> _parseResponse(int statusCode, String body) {
    if (body.isEmpty) {
      if (statusCode >= 200 && statusCode < 300) {
        // Successful but empty response.
        return {};
      } else {
        // This should not be common. If the error comes from Platform, the error message will be included in the body.
        throw PlatformUnknownException('Platform request failed with HTTP $statusCode');
      }
    }

    Map<String, dynamic> json = jsonDecode(body);
    if (json['response']?['status'] == 'SUCCESS') {
      return json;
    } else if (json['response']?['errorCode'] == 'SEC-001') {
      _session = null;
      throw const PlatformInvalidTokenException();
    } else if (json['response']?['errorMessage'] != null) {
      throw PlatformLocalizedException(json['response']?['errorCode'], json['response']['errorMessage']);
    } else {
      throw PlatformUnknownException('Platform returned unexpected body: $body');
    }
  }

  void _initMessagingClient() {
    if (_config.messagingKeys != null) {
      // Initialize the PubNub client.
      messagingClient = MessagingClientPubNub(_session!, _config.messagingKeys!);
    }
  }
}

/// The Platform environment.
enum PlatformEnvironment {
  dev,
  prod,
}

extension PlatformEnvironmentExtension on PlatformEnvironment {
  get name => toString().split('.').last;
}

/// The [PlatformClient] configuration.
class PlatformClientConfig {
  final PlatformEnvironment environment;
  final String apiKey;
  final String clientId;
  final String? deviceId;
  final PlatformMessagingKeys? messagingKeys;

  /// Creates a new [PlatformClientConfig].
  ///
  /// If the [deviceId] is not provided, the [PlatformClient] will attempt to use the [`ANDROID_ID`](https://developer.android.com/reference/android/provider/Settings.Secure#ANDROID_ID)
  /// on Android and the [`identifierForVendor`](https://developer.apple.com/documentation/uikit/uidevice/1620059-identifierforvendor)
  /// on iOS. The [deviceId] is not set by default on other platforms, which will result in tokens with short lifetimes.
  PlatformClientConfig({
    required this.apiKey,
    this.deviceId,
    required this.environment,
    required this.clientId,
    this.messagingKeys,
  });
}

/// The keys used to send and receive messages if the application supports messaging.
class PlatformMessagingKeys {
  final String sendKey;
  final String receiveKey;

  PlatformMessagingKeys(this.sendKey, this.receiveKey);
}
