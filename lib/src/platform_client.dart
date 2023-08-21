import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_aira/flutter_aira.dart';
import 'package:flutter_aira/src/messaging_client.dart';
import 'package:flutter_aira/src/models/sent_file_info.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'models/participant.dart';
import 'room.dart';

/// The Platform client.
class PlatformClient {

  /// Creates a new [PlatformClient] with the specified [PlatformClientConfig].
  ///
  /// [httpClient] can be provided if you want to use your own HTTP client (e.g. a
  /// [`SentryHttpClient`](https://docs.sentry.io/platforms/dart/usage/advanced-usage/)).
  PlatformClient(this._config, [http.Client? httpClient]) : _httpClient = httpClient ?? http.Client();

  final _log = Logger('PlatformClient');

  // Reuse the HTTP client as a performance optimization.
  final http.Client _httpClient;

  // A random number generator for generating trace IDs.
  final _random = Random();

  final PlatformClientConfig _config;
  Session? _session;
  MessagingClientPubNub? _messagingClient;

  int get _userId => _session!.userId;

  String get _token => _session!.token;

  MessagingClient? get messagingClient => _messagingClient;

  DateTime _lastLocationUpdateTimestamp = DateTime.fromMillisecondsSinceEpoch(0);
  AccessOfferDetails? _lastAccessOfferUpdate;

  /// Discards any resources associated with the [PlatformClient].
  ///
  /// After this is called, the object is not in a usable state and should be discarded.
  void dispose() {
    _httpClient.close();
    _messagingClient?.dispose();
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
      additionalHeaders: {HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded'},
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

      await _initMessagingClient();

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
      'device': await _deviceContext,
      'login': credentials.login,
      'loginfrom': 'AIRA SMART', // Platform knows the Explorer app as "AIRA SMART".
      'password': credentials.password,
    });

    _session = Session.fromJson(await _httpPost('/api/user/login', body));

    await _initMessagingClient();

    return _session!;
  }

  /// Logs in with a client verification code.
  Future<Session> loginWithClientVerificationCode(String verificationCode) async {
    Map<String, dynamic> response = await _httpPost(
      '/api/smartapp/verify/client/confirm',
      {'verificationCode': verificationCode},
      additionalHeaders: {HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded'},
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
  /// If the Explorer has more than one [Profile], specify the [accountId] to use for the service request; if no
  /// [accountId] is specified, the Explorer's default account will be used.
  ///
  /// The service request can be started with a [message] and/or [fileMap] (a [Map] of file names to bytes). If the
  /// Explorer will be communicating with messages exclusively, set [cannotTalk] to `true`.
  ///
  /// If the Explorer has allowed access to their location, include their starting [position]. If there is an Aira
  /// Access offer for that location, it will be automatically activated.
  Future<Room> createServiceRequest(
    RoomHandler roomHandler, {
    int? accountId,
    bool? cannotTalk,
    Map<String, List<int>>? fileMap,
    String? message,
    Position? position,
    int? accessOfferId,
    AccessOfferType? accessOfferType,
  }) async {
    _verifyIsLoggedIn();

    String preCallMessage =
        '${message ?? ''}${fileMap != null && fileMap.isNotEmpty ? ' (With files: ${fileMap.keys.join(', ')})' : ''}';

    Map<String, dynamic> context = {
      'app': await _appContext,
      'device': await _deviceContext,
      'permissions': {'location': position != null},
      'intent': 'NONE',
    };

    Map<String, dynamic> params = {
      'accountId': accountId,
      'context': jsonEncode(context),
      'requestSource': _config.clientId,
      'requestType': 'AIRA', // Required but unused.
      'hasMessage': preCallMessage.isNotEmpty || cannotTalk == true,
      'message': preCallMessage,
      'cannotTalk': cannotTalk == true,
      'useWebrtcRoom': true,
      if (null != accessOfferId && null != accessOfferType)
        'accessOffer': {
          'access': {
            'id': accessOfferId,
            'class': accessOfferType.name,
          },
        },
    };

    if (position != null) {
      params['latitude'] = position.latitude;
      params['longitude'] = position.longitude;
    }

    // HACK: The "start" message is a legacy concept used to organize messages in Dash. It gets sent every time an
    // Explorer calls Aira, even if the call was canceled or the call didn't use messaging. Eventually, we should find a
    // solution with fewer shortcomings.
    await _messagingClient?.sendStart();

    if (preCallMessage.isNotEmpty) {
      await _sendPreCallMessage(message, fileMap);
    }

    ServiceRequest serviceRequest =
        ServiceRequest.fromJson(await _httpPost('/api/user/$_userId/service-request', jsonEncode(params)));

    _messagingClient?.serviceRequestId = serviceRequest.id;

    return KurentoRoom.create(_config.environment, this, _session!, _messagingClient, serviceRequest, roomHandler);
  }

  Future<List<String>> _sendPreCallMessage(String? text, Map<String, List<int>>? fileMap) async {
    if (null == _messagingClient) {
      throw UnsupportedError('The application does not support messaging');
    }
    _log.finest('Sending pre-call message (message: $text, files: ${fileMap?.keys.join(', ')})');
    String? message = text?.trim();
    if (null != fileMap && fileMap.isNotEmpty) {
      if (fileMap.length == 1) {
        // If we have only one file, send it with the file.
        var fileEntry = fileMap.entries.first;
        SentFileInfo fileInfo = await _messagingClient!.sendFile(fileEntry.key, fileEntry.value, text: message);
        return [fileInfo.id];
      } else {
        // if we have multiple files, send them separately from teh message
        if (null != message && message.isNotEmpty) {
          // Waiting on first message separately to insure it gets to the server first.
          await _messagingClient!.sendMessage(message);
        }

        List<Future<SentFileInfo>> futureFileInfo =
            fileMap.entries.map((e) => _messagingClient!.sendFile(e.key, e.value)).toList(growable: false);
        List<SentFileInfo> fileInfoList = await Future.wait(futureFileInfo);

        List<String> fileIds = fileInfoList.map((fi) => fi.id).toList(growable: false);
        return fileIds;
      }
    } else if (null != text && text.isNotEmpty) {
      await _messagingClient!.sendMessage(text);
    }
    return [];
  }

  /// Gets the status of a service request.
  ///
  /// If the `status` is `ASSIGNED`, this will also return the `agentFirstName`.
  ///
  /// This API is not intended for public consumption and is subject to change.
  @internal
  Future<Map<String, String?>> getServiceRequestStatus(int serviceRequestId) async {
    _verifyIsLoggedIn();

    Map<String, dynamic> response =
        await _httpGet('/api/user/service', queryParameters: {'id': serviceRequestId.toString()});

    return {
      'agentFirstName': response['agentName']?.toString().split(' ').first, // Split the first name and last initial.
      'status': response['serviceStatus'],
    };
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

  /// Deletes the specified track for a participant in a room.
  Future<void> deleteTrack(int roomId, int participantId, int trackId) async {
    _verifyIsLoggedIn();

    await _httpDelete('/api/webrtc/room/$roomId/participant/$participantId/track/$trackId');
  }

  /// Deletes all tracks for a participant in a room.
  Future<void> deleteTracks(int roomId, int participantId) async {
    _verifyIsLoggedIn();

    await _httpDelete('/api/webrtc/room/$roomId/participant/$participantId/track');
  }

  /// Saves feedback for a service request.
  Future<void> saveFeedback(SessionFeedback feedback) async {
    _verifyIsLoggedIn();

    Map<String, dynamic>? agentFeedback = feedback.agentFeedback?.toJson();
    agentFeedback?['requestReview'] = feedback.requestReview;
    String body = jsonEncode({
      'serviceId': feedback.serviceId,
      'comment': jsonEncode({
        'schemaVersion': 2,
        'agent': agentFeedback,
        'app': feedback.appFeedback?.toJson(),
      }),
      // This is to avoid the legacy logic to show non representative feedback data:
      //   if none of the rating is negative, consider the call to be a success.
      'taskSuccess':
          Rating.negative != feedback.agentFeedback?.rating && Rating.negative != feedback.appFeedback?.rating,
    });

    await _httpPost('/api/smartapp/feedback', body);
  }

  /// Uploads a photo for a service request.
  Future<void> uploadPhoto(int serviceRequestId, ByteBuffer photo) async {
    _verifyIsLoggedIn();

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
  }

  /// Returns the logged-in [User].
  Future<User> getUser() async {
    _verifyIsLoggedIn();

    Map<String, dynamic> response = await _httpGet('/api/user/$_userId');

    return User.fromJson(response);
  }

  /// Returns the current billing information for the current user.
  Future<PartialBillingInformation> getPartialBillingInformation() async {
    _verifyIsLoggedIn();

    Map<String, dynamic> response = await _httpGet('/api/user/$_userId/billing-info');

    return PartialBillingInformation.fromJson(response);
  }

  /// Used to update the [firstName] or [lastName] or both of a user.
  Future<void> updateName(String firstName, String lastName) async {
    await Future.wait([
      _updatePropertyValue('firstName', [firstName]),
      _updatePropertyValue('lastName', [lastName]),
    ]);
  }

  /// Used to update the preferred languages of a user.
  Future<void> updatePreferredLanguages(List<Language> languages) async {
    await Future.wait([
      _updatePropertyValue('preferredLang', languages.map((l) => l.name).toList(growable: false)),
    ]);
  }

  Future<Map<String, dynamic>> _updatePropertyValue(String propertyName, List<String> propertyValues) async => _httpPut(
        '/api/user/$_userId/property/$propertyName/value',
        body: jsonEncode(propertyValues.map((propertyValue) => {'value': propertyValue}).toList(growable: false)),
      );

  /// Used to start the process to update and verify a user's [email] address.
  /// This process is completed by visiting a verification link sent to [email].
  /// There is no way to get a instantaneous confirmation of the success of the update.
  Future<void> verifyEmailUpdate(String email) async {
    await _httpPut(
      '/api/user/$_userId/email',
      body: jsonEncode({'email': email}),
    );
  }

  /// Used to start the process to update and verify a user's phone number.
  /// The Explorer will get a code sent through SMS at [phoneNumber] and the user will have to send this code through
  /// [confirmPhoneNumberUpdate] to complete the phoneNumber update.
  Future<void> verifyPhoneNumberUpdate(String countryIsoCode, String fullPhoneNumber) async {
    await _httpPost(
      '/api/user/$_userId/verify',
      jsonEncode({'phoneNumber': fullPhoneNumber, 'countryCode': countryIsoCode, 'eventType': 'RESET'}),
    );
  }

  /// Confirms the phone number change by sending the received SMS Code back to the backend.
  Future<void> confirmPhoneNumberUpdate(String fullPhoneNumber, String smsCode) async {
    await _httpPost(
      '/api/user/$_userId/verify/confirm',
      jsonEncode({'authCode': smsCode, 'phoneNumber': fullPhoneNumber, 'eventType': 'RESET'}),
    );
  }

  /// Retrieves a page of photos shared with the user.
  ///
  /// A page can contain up to 25 photos. If there are more photos available, [PhotosPage.hasMore] will be `true`.
  Future<Paged<Photo>> getSharedPhotos(int page) async {
    _verifyIsLoggedIn();

    Map<String, dynamic> response = await _httpGet(
      '/api/smartapp/photos/$_userId',
      queryParameters: {'page': page.toString()},
    );
    return Paged(
      page: page,
      hasMore: response['response']['hasMore'],
      items: (response['photos'] as List<dynamic>).map((p) => Photo.fromJson(p)).toList(growable: false),
    );
  }

  /// Deletes the photos with the specified IDs.
  Future<void> deleteSharedPhotos(List<int> ids) {
    _verifyIsLoggedIn();
    return _httpDelete(
      '/api/smartapp/photos',
      body: jsonEncode({'userId': _userId, 'photoIds': ids}),
    );
  }

  /// Get Usage Information (Minutes used and available by profile, next free call availability, secondary users, etc.)
  Future<Usage> getUsage() async {
    _verifyIsLoggedIn();

    Map<String, dynamic> response = await _httpGet('/api/smartapp/usage/$_userId/v3');
    return Usage.fromJson(response);
  }

  /// Get information about all calls in history. These [CallSession] comes in batch of 25 by page.
  Future<Paged<CallSession>> getCallHistory(int page) async {
    _verifyIsLoggedIn();

    Map<String, dynamic> response = await _httpGet(
      '/api/user/service/history/bu',
      queryParameters: {'pg': page.toString(), 'userId': _userId.toString()},
    );
    return Paged(
      page: page,
      hasMore: response['response']['hasMore'],
      items: (response['requests'] as List<dynamic>)
          .where((json) => null != json['startTimeStamp'])
          .where((json) => null != json['endTimeStamp'])
          .map((p) => CallSession.fromJson(p))
          .toList(growable: false),
    );
  }

  /// This function pauses or resumes minutes sharing with secondary users.
  Future<bool> pauseSecondaryUser(int secondaryUserId, bool isPaused) async {
    Map<String, dynamic> response = await _httpPut(
      '/api/smartapp/sharing/pause/',
      body: jsonEncode({'userId': secondaryUserId, 'pauseUser': isPaused}),
    );
    return response['pauseUser'];
  }

  /// This function returns the list of both pending invitations and secondary users information.
  Future<MinuteSharingInformation> getMinuteSharingInformation() async {
    Map<String, dynamic> planResponse = {};
    bool isGuest = false;
    try {
      Future<Map<String, dynamic>> planResponseFuture = _httpGet(
        '/api/user/plan',
        queryParameters: {'userId': _userId.toString()},
      );
      planResponse = await planResponseFuture;
    } catch (e) {
      // Guest if we don't have a plan.
      isGuest = true;
      _log.finest('User $_userId doesn\'t have a primary subscription', e);
    }
    Future<Map<String, dynamic>> minuteSharingResponseFuture = _httpGet(
      '/api/account/sharing/$_userId',
    );
    Map<String, dynamic> minuteSharingResponse = await minuteSharingResponseFuture;
    minuteSharingResponse['maxAdditionalShared'] = planResponse['maxAdditionalShared'] ?? 0;
    minuteSharingResponse['isGuest'] = isGuest;
    return MinuteSharingInformation.fromJson(minuteSharingResponse);
  }

  /// Creates and sends an email invitation to a secondary account user.
  Future<void> sendMinuteSharingInvite(String email) async {
    await _httpPost(
      '/api/account/sharing/invite',
      jsonEncode({'userId': _userId, 'invitee': email}),
    );
  }

  /// Cancels a pending secondary account user invitation.
  Future<void> invalidateMinuteSharingInvite(String email) async {
    await _httpDelete(
      '/api/account/sharing/invite',
      body: jsonEncode({'userId': _userId, 'invitee': email}),
    );
  }

  /// Removes a secondary account user from the primary account.
  Future<void> removeMinuteSharingMember(int secUserId) async {
    await _httpDelete(
      '/api/account/sharing/$secUserId',
    );
  }

  /// Returns, page by page, the closest available Site Access Offers for the current user.
  Future<Paged<AccessOfferDetails>> getAccessOfferSites(
    int page, {
    required double latitude,
    required double longitude,
  }) async {
    _verifyIsLoggedIn();

    return searchAccessOfferSites(page, searchPattern: '', latitude: latitude, longitude: longitude);
  }

  /// Returns, page by page, all available Promotion Access Offers for the current user.
  Future<Paged<AccessOfferDetails>> getAccessOfferPromotions(
    int page, {
    double? latitude,
    double? longitude,
  }) =>
      _getAccessOffers('promotion', page, latitude: latitude, longitude: longitude);

  /// Returns, page by page, all available Product Access Offers for the current user.
  Future<Paged<AccessOfferDetails>> getAccessOfferProducts(
    int page, {
    double? latitude,
    double? longitude,
  }) =>
      _getAccessOffers('product', page, latitude: latitude, longitude: longitude);

  Future<Paged<AccessOfferDetails>> _getAccessOffers(
    String type,
    int page, {
    double? latitude,
    double? longitude,
  }) async {
    _verifyIsLoggedIn();

    return _processAccessOfferResponse(
      await _httpGet(
        '/api/user/$_userId/access/$type',
        queryParameters: {
          if (null != latitude) 'lat': latitude.toString(),
          if (null != longitude) 'lng': longitude.toString(),
          'limit': '25',
          'pg': page.toString(),
        },
      ),
      page,
    );
  }

  /// Search for all applicable Site access offers matching the [searchPattern] for the current User.
  /// Although [latitude] and [longitude] are nullable, the backend will throw an exception if [searchPattern] is empty
  /// and either [longitude] or [latitude] is null.
  Future<Paged<AccessOfferDetails>> searchAccessOfferSites(
    int page, {
    double? latitude,
    double? longitude,
    required String searchPattern,
  }) async {
    _verifyIsLoggedIn();

    return _processAccessOfferResponse(
      await _httpGet(
        '/api/site/search/v2',
        queryParameters: {
          'q': searchPattern,
          if (null != latitude) 'lat': latitude.toString(),
          if (null != longitude) 'lng': longitude.toString(),
          'limit': '10',
          'pg': page.toString(),
        },
      ),
      page,
      payloadTag: 'sites',
    );
  }

  /// Search for all applicable Promotion access offers matching the [searchPattern] for the current User.
  Future<Paged<AccessOfferDetails>> searchAccessOfferPromotions(
    int page, {
    required String searchPattern,
  }) =>
      _searchAccessOffers(AccessOfferType.promotion, page, searchPattern: searchPattern);

  /// Search for all applicable Product access offers matching the [searchPattern] for the current User.
  Future<Paged<AccessOfferDetails>> searchAccessOfferProducts(
    int page, {
    required String searchPattern,
  }) =>
      _searchAccessOffers(AccessOfferType.product, page, searchPattern: searchPattern);

  Future<Paged<AccessOfferDetails>> _searchAccessOffers(
    AccessOfferType type,
    int page, {
    required String searchPattern,
  }) async {
    _verifyIsLoggedIn();

    return _processAccessOfferResponse(
      await _httpGet(
        '/api/access/${type.name}/search',
        queryParameters: {
          'q': searchPattern,
          'limit': '15',
          'pg': page.toString(),
        },
      ),
      page,
    );
  }

  /// Returns the list of recently used AccessOffer for the current user.
  Future<Paged<AccessOfferDetails>> getRecentlyUsedAccessOffers(int page) async {
    _verifyIsLoggedIn();

    return _processAccessOfferResponse(
      await _httpGet(
        '/api/user/$_userId/access/recently-used',
        queryParameters: {
          'limit': '3',
          'pg': page.toString(),
        },
      ),
      page,
    );
  }

  Paged<AccessOfferDetails> _processAccessOfferResponse(
    Map<String, dynamic> response,
    int page, {
    String payloadTag = 'payload',
  }) {
    Set<String> handledAccessOfferTypes = AccessOfferType.values.map((aot) => aot.name).toSet();
    return Paged(
      page: page,
      hasMore: response['response']['hasMore'],
      items: ((response[payloadTag] as List<dynamic>?) ?? [])
          // We currently only handle the Promotions, Products and Sites.
          .where((json) => handledAccessOfferTypes.contains(json['class']))
          .map((json) => AccessOfferDetails.fromJson(json))
          .toList(growable: false),
    );
  }

  /// Returns the [AccessOfferDetails] if the access offer is valid, otherwise throws a [PlatformLocalizedException] containing the rational explaining why this is not valid or a [PlatformUnknownException] in case anything else goes wrong.
  Future<AccessOfferDetails> getValidOffer(AccessOfferType type, int id, {Position? position}) async {
    try {
      Map<String, String>? queryParameters;
      if (null != position) {
        queryParameters = {
          'lat': position.latitude.toString(),
          'lng': position.longitude.toString(),
        };
      }
      Map<String, dynamic> json = await _httpGet(
        '/api/user/$_userId/access/${type.name}/$id/valid',
        queryParameters: queryParameters,
      );
      // The validation endpoint doesn't provide the 'class'... let's add this bit of information.
      json['class'] ??= type.name;

      // Returns 204 if the offer is still valid.
      return AccessOfferDetails.fromJson(json);
    } on PlatformLocalizedException {
      _log.finest(
          'Access Offer $id ${type.name} is not valid the user $_userId with lat ${position?.latitude} and lng ${position?.longitude}',);
      rethrow;
    } catch (e) {
      _log.shout(
          'Access Offer validation for $id ${type.name} failed with user: $_userId, lat: ${position?.latitude} and lng: ${position?.longitude}',);
      rethrow;
    }
  }

  /// Returns a URL to be used to link the Lyft account to Aira.
  ///
  /// That URL should be used to obtain the code to use with [sendLyftAuthorizationCode]. Lyft will ask the proper
  /// authorizations to the user and then redirect to `aira://io.aira.smart/lyft?code=s6U7dSRXMYmJ_Q-p&state=6256` which
  /// contains the code to extract. The redirection url is now a dummy link which can be analyzed through a webview.
  ///
  /// Support for Web will be added soon.
  // Lyft uses `oauth2` to provides the code through a redirection's query parameter. The redirection URL can be
  // customized through Lyft's website. More information here: https://developer.lyft.com/docs/authentication.
  Future<String> getLyftAuthorizationUrl() async {
    _verifyIsLoggedIn();
    // FIXME: This endpoint doesn't return a "classic" `response` with `status`, `errorCode` or `errorMessage`.
    // If this is ever fixed, it would be nice to use a call to `_httpGet` instead of directly using `_httpClient`.

    Uri uri = Uri.https(_platformHost, '/api/lyft/oauth/$_userId');
    int traceId = _nextTraceId();
    Map<String, String> headers = await _getHeaders(traceId);
    http.Response response = await _httpClient.get(uri, headers: headers);
    Map<String, dynamic> json = jsonDecode(response.body);
    return json['url'];
  }

  /// Sends the confirmation code to lyft to seal the deal. The code can be obtained through the use of [getLyftAuthorizationUrl].
  Future<void> sendLyftAuthorizationCode(String code) async {
    _verifyIsLoggedIn();
    // FIXME: This endpoint doesn't return a "classic" `response` when successful. Here is a sample of success response:
    //   {"has_taken_a_ride":true,"last_name":"Painchaud","id":"1169165473615850134","first_name":"Israël"}
    // Here is a sample of an error:
    //   {"response":{"pageNumber":0,"resultSize":0,"errorMessage":"Provider Error: invalid_grant: The supplied \"code\" is not valid.","hasMore":false,"messageCode":"","errorCode":"KN-SP-003","status":"FAILURE"}}
    // If this is ever fixed, it would be nice to use a call to `_httpPost` instead of directly using `_httpClient`.
    int traceId = _nextTraceId();
    Map<String, String> headers = await _getHeaders(traceId);
    Uri uri = Uri.https(_platformHost, '/api/lyft/oauth/redirect');
    http.Response response = await _httpClient.post(
      uri,
      body: jsonEncode({
        'userId': _userId,
        'authorizationCode': code,
      }),
      headers: headers,
    );
    if (response.statusCode != 200) {
      Map<String, dynamic> json = jsonDecode(response.body);
      throw PlatformLocalizedException(json['response']?['errorCode'], json['response']['errorMessage']);
    }
  }

  /// Unregisters LYFT from the user's account.
  Future<void> revokeLyftAuthorization() {
    _verifyIsLoggedIn();

    // This endpoint doesn't return a body when successful, but does return a classic body when there is an error:
    //   {"response":{"pageNumber":0,"resultSize":0,"errorMessage":"Invalid Param","hasMore":false,"messageCode":"","errorCode":"BIZ-GEN-001","status":"FAILURE"}}
    // No need to use [_httpClient.delete] directly.
    return _httpDelete('/api/user/services/provider/access', queryParameters: {
      'userId': _userId.toString(),
      'serviceName': 'LYFT',
    },);
  }

  /// Registers the device's push token so that it can receive push notifications.
  ///
  /// `token` is the Base64-encoded Apple Push Notification service (APNs) device token on iOS or the Firebase Cloud
  /// Messaging (FCM) registration token on Android. It can be obtained using the
  /// [`plain_notification_token`](https://pub.dev/packages/plain_notification_token) package.
  Future<void> registerPushToken(String token) async {
    _verifyIsLoggedIn();

    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      throw UnsupportedError('Unsupported platform');
    }

    String body = jsonEncode({
      'token': token,
      'type': Platform.isAndroid ? 'ANDROID' : 'IOS',
    });

    await _httpPost('/api/smartapp/token', body);
  }

  /// Requests Platform if there is an available Site Offer at the current position.
  ///
  /// Returns null if there is no Site Offer available or an `AccessOfferDetails` of the available offer if within
  /// geofence.
  ///
  /// WARNING! This function is Throttled to avoid overhead on the server side. If it is called more than every seconds,
  /// it will return the latest valid AccessOfferDetails. This is done to simplify the handling of the function as now,
  /// we only have to worry about nulls and valid AccessOfferDetails.
  Future<AccessOfferDetails?> inquireForGPSActivatedOffer(Position position) async {
    _verifyIsLoggedIn();

    if (shouldThrottlePositionUpdate) {
      // Same throttling delay as `KurrentoRoom.updateLocation`.
      return _lastAccessOfferUpdate;
    }

    String body = jsonEncode({
      'userId': _userId,
      'lt': position.latitude,
      'lg': position.longitude,
    });

    Map<String, dynamic> gpsResponse = await _httpPost('/api/user/location', body);
    Map<String, dynamic>? site = gpsResponse['site'];
    _lastAccessOfferUpdate = null == site ? null : AccessOfferDetails.fromJson(site);
    return _lastAccessOfferUpdate;
  }

  Future<Map<String, dynamic>> _httpSend(String method, String unencodedPath,
      {Map<String, String>? additionalHeaders, Map<String, String>? queryParameters, Object? body,}) async {
    try {
      Uri uri = Uri.https(_platformHost, unencodedPath, queryParameters);
      int traceId = _nextTraceId();
      Map<String, String> headers = await _getHeaders(traceId, additionalHeaders: additionalHeaders);

      _log.finest('trace_id=$traceId method=$method uri=$uri${body != null ? ' body=$body' : ''}');

      http.Response response;
      switch (method) {
        case 'DELETE':
          response = await _httpClient.delete(uri, headers: headers, body: body);
          break;
        case 'GET':
          response = await _httpClient.get(uri, headers: headers);
          break;
        case 'POST':
          response = await _httpClient.post(uri, headers: headers, body: body);
          break;
        case 'PUT':
          response = await _httpClient.put(uri, headers: headers, body: body);
          break;
        default:
          throw UnsupportedError(method);
      }
      return _parseResponse(response.statusCode, response.body);
    } on SocketException catch (e) {
      throw PlatformUnknownException(e.message);
    }
  }

  Future<Map<String, dynamic>> _httpDelete(
    String unencodedPath, {
    Map<String, String>? additionalHeaders,
    Object? body,
    Map<String, String>? queryParameters,
  }) async =>
      _httpSend(
        'DELETE',
        unencodedPath,
        additionalHeaders: additionalHeaders,
        body: body,
        queryParameters: queryParameters,
      );

  Future<Map<String, dynamic>> _httpGet(
    String unencodedPath, {
    Map<String, String>? additionalHeaders,
    Map<String, String>? queryParameters,
  }) async =>
      _httpSend('GET', unencodedPath, additionalHeaders: additionalHeaders, queryParameters: queryParameters);

  Future<Map<String, dynamic>> _httpPost(
    String unencodedPath,
    Object? body, {
    Map<String, String>? additionalHeaders,
  }) async =>
      _httpSend('POST', unencodedPath, additionalHeaders: additionalHeaders, body: body);

  Future<Map<String, dynamic>> _httpPut(
    String unencodedPath, {
    Object? body,
    Map<String, String>? additionalHeaders,
  }) async =>
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
      HttpHeaders.contentTypeHeader: 'application/json',
      'X-API-Key': _config.apiKey,
      'X-Client-Id': _config.clientId,
      'X-Trace-Id': traceId.toString(),
    };

    if (!kIsWeb) {
      // The http package does not automatically set the Accept-Language header on mobile.
      headers[HttpHeaders.acceptLanguageHeader] = Platform.localeName.replaceAll('_', '-');
    }

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
        'id': (await _deviceId) ?? '',
        'model': (await DeviceInfoPlugin().deviceInfo).data['model'],
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
      return (await const AndroidId().getId());
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

    Map<String, dynamic> json;
    try {
      json = jsonDecode(body);
    } catch (e) {
      json = {};
    }

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

  Future<void> _initMessagingClient() async {
    if (_config.messagingKeys != null) {
      // Initialize the PubNub client.
      String token = (await _httpPost('/api/pubnub/token', null))['payload'];
      _messagingClient = MessagingClientPubNub(_config.messagingKeys!, _userId, token);
    }
  }
}

/// The Platform environment.
enum PlatformEnvironment {
  dev,
  prod,
  ;

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

/// This extension is a way for us to expose and share location update timestamp functionality internally only.
extension LocationThrottling on PlatformClient {
  DateTime get lastLocationUpdateTimestamp => _lastLocationUpdateTimestamp;
  bool get shouldThrottlePositionUpdate {
    DateTime now = DateTime.now();
    if (now.difference(_lastLocationUpdateTimestamp).inMilliseconds < 1500) {
      // Same throttling delay as `KurrentoRoom.updateLocation`.
      return true;
    }
    _lastLocationUpdateTimestamp = now;
    return false;
  }
}