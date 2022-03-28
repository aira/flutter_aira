import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'models/feedback.dart';
import 'models/participant.dart';
import 'models/service_request.dart';
import 'models/session.dart';
import 'models/track.dart';
import 'platform_exceptions.dart';
import 'platform_mq.dart';
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
  PlatformMQ? _mq;

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

    _mq?.dispose();
    _mq = null;
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

      _mq?.dispose();
      _mq = PlatformMQImpl(_config.environment, _session!);

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

  /// Logs in with a phone number.
  ///
  /// [phoneNumber] is the phone number in E.164 format, and [verificationCode] is the verification code sent to the
  /// phone by [sendPhoneVerificationCode].
  Future<Session> loginWithPhone(String phoneNumber, String verificationCode) async {
    // Exchange the phone verification code for a password.
    var body = jsonEncode({
      'authCode': verificationCode,
      'phoneNumber': phoneNumber,
    });
    var response = await _httpPost('/api/smartapp/verify/confirm', body);
    if (response['newUser']) {
      // TODO: If this is a new user, they need to sign up before logging in.
      throw PlatformLocalizedException(
          '', 'The mobile number $phoneNumber is not on file. Please log in with your email or call customer care.');
    }

    // Login with the phone number and password.
    body = jsonEncode({
      'authProvider': 'PHONE_VERIFICATION',
      'login': phoneNumber,
      'loginfrom': 'AIRA SMART', // Platform knows the Explorer app as "AIRA SMART".
      'password': response['verificationCode'],
    });
    _session = Session.fromJson(await _httpPost('/api/user/login', body));

    _mq?.dispose();
    _mq = PlatformMQImpl(_config.environment, _session!);

    return _session!;
  }

  /// Logs in with an email address.
  ///
  /// [email] is the email address and [verificationCode] is the verification code sent to the email address by
  /// [sendEmailVerificationCode].
  Future<Session> loginWithEmail(String email, String verificationCode) async {
    // Exchange the email verification code for a password.
    String body = jsonEncode({
      'authCode': verificationCode,
      'email': email,
    });
    Map<String, dynamic> response = await _httpPost('/api/smartapp/verify/email/confirm', body);

    if (response['newUser']) {
      // TODO: If this is a new user, they need to sign up before logging in.
    }

    // Login with the email address and password.
    body = jsonEncode({
      'authProvider': 'EMAIL_VERIFICATION',
      'login': email,
      'loginfrom': 'AIRA SMART', // Platform knows the Explorer app as "AIRA SMART".
      'password': response['verificationCode'],
    });
    _session = Session.fromJson(await _httpPost('/api/user/login', body));

    _mq?.dispose();
    _mq = PlatformMQImpl(_config.environment, _session!);

    return _session!;
  }

  /// Logs out the user.
  Future<void> logout() async {
    // TODO: Actually log out. For now, we're copying the legacy apps and just removing the token.
    _session = null;
    _mq?.dispose();
    _mq = null;
  }

  /// Creates a service request for the logged-in user.
  Future<Room> createServiceRequest(RoomHandler roomHandler) async {
    _verifyIsLoggedIn();

    Map<String, dynamic> context = {
      'app': await _appContext,
      'device': await _deviceContext,
      'permissions': {'location': false},
      'intent': 'NONE',
    };

    String body = jsonEncode({
      'context': jsonEncode(context),
      'requestSource': 'explorer-ui', // TODO: What source(s) should we use?
      'requestType': 'AIRA', // Required but unused.
      'useWebrtcRoom': true,
    });

    ServiceRequest serviceRequest =
        ServiceRequest.fromJson(await _httpPost('/api/user/$_userId/service-request', body));

    return KurentoRoom(_config.environment, this, _mq!, serviceRequest, roomHandler);
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
      {Feedback? agentFeedback, Feedback? appFeedback, Feedback? offerFeedback}) async {
    _verifyIsLoggedIn();

    String body = jsonEncode({
      'serviceId': serviceRequestId,
      'comment': jsonEncode({
        'schemaVersion': 1,
        'agent': agentFeedback?.toJson(),
        'app': appFeedback?.toJson(),
        'offer': offerFeedback?.toJson(),
      }),
    });

    await _httpPost('/api/smartapp/feedback', body);
  }

  Future<Map<String, dynamic>> _httpSend(String method, String unencodedPath,
      {Map<String, String>? additionalHeaders, Map<String, String>? queryParameters, Object? body}) async {
    try {
      final uri = Uri.https(_platformHost, unencodedPath, queryParameters);
      final traceId = _nextTraceId();
      final headers = await _getHeaders(traceId, additionalHeaders);

      _log.finest('trace_id=$traceId method=$method uri=$uri${body != null ? ' body=$body' : ''}');

      switch (method) {
        case 'GET':
          return _parseResponse(await _httpClient.get(uri, headers: headers));
        case 'POST':
          return _parseResponse(await _httpClient.post(uri, headers: headers, body: body));
        case 'PUT':
          return _parseResponse(await _httpClient.put(uri, headers: headers, body: body));
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

  Future<Map<String, String>> _getHeaders(int traceId, Map<String, String>? additionalHeaders) async {
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
    if (kIsWeb) {
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

  Map<String, dynamic> _parseResponse(http.Response response) {
    final jsonBody = response.body;
    if (jsonBody.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Successful but empty response.
        return {};
      } else {
        // This should not be common. If the error comes from Platform, the error message will be included in the body.
        throw PlatformUnknownException('Platform request failed with HTTP ${response.statusCode}');
      }
    }

    final body = jsonDecode(jsonBody);
    if (body['response']?['status'] == 'SUCCESS') {
      return body;
    } else if (body['response']?['errorCode'] == 'SEC-001') {
      _session = null;
      _mq?.dispose();
      _mq = null;
      throw const PlatformInvalidTokenException();
    } else if (body['response']?['errorMessage'] != null) {
      throw PlatformLocalizedException(body['response']?['errorCode'], body['response']['errorMessage']);
    } else {
      throw PlatformUnknownException('Platform returned unexpected body: $jsonBody');
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

  PlatformClientConfig(this.environment, this.apiKey, this.clientId);
}
