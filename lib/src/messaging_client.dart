import 'dart:async';

import 'package:flutter_aira/src/models/sent_file_info.dart';
import 'package:flutter_aira/src/platform_client.dart';
import 'package:flutter_aira/src/platform_exceptions.dart';
import 'package:logging/logging.dart';
import 'package:pubnub/pubnub.dart' as pn;

import 'models/message.dart';

/// Room independent class to handle all messaging.
abstract class MessagingClient {
  /// The ID of the service request.
  set serviceRequestId(int id);

  /// A broadcast stream of messages sent and received.
  ///
  /// If the application does not support messaging, this will throw an exception.
  Stream<Message> get messageStream;

  /// Sends the provided message to the Agent.
  ///
  /// If the application does not support messaging, this will throw an exception.
  Future<void> sendMessage(String text);

  /// Sends the provided message to the Agent.
  ///
  /// If the application does not support messaging, this will throw an exception.
  Future<SentFileInfo> sendFile(String fileName, List<int> file, {String? text});

  Uri getFileUrl(String fileId, String fileName);

  /// Leaves the room and discards any resources used.
  ///
  /// After this is called, the object is not in a usable state and should be discarded.
  Future<void> dispose();
}

class MessagingClientPubNub implements MessagingClient {
  MessagingClientPubNub(PlatformMessagingKeys messagingKeys, int userId, String token) : _userId = userId {
    _pubnub = pn.PubNub(
      defaultKeyset: pn.Keyset(
        // TODO: Setting the `authKey` shouldn't be necessary, but there is a bug in the PubNub SDK where
        // [PubNub.files.getFileUrl] does not use the value configured with [PubNub.setToken]
        // (https://github.com/pubnub/dart/issues/103).
        authKey: token,
        // Eventually, instead of passing the publish and subscribe keys through configuration, we should return them
        // from Platform when logging in so: 1) we don't have to provide them to partners; and 2) they can be rotated.
        publishKey: messagingKeys.sendKey,
        subscribeKey: messagingKeys.receiveKey,
        userId: pn.UserId(userId.toString()),
      ),
    );
    _pubnub.setToken(token);

    _messageSubscription = _pubnub.subscribe(channels: {_messageChannel});
  }

  final Logger _log = Logger('MessagingClientPubNub');

  late final pn.PubNub _pubnub;
  late final pn.Subscription? _messageSubscription;

  final int _userId;
  int? _serviceRequestId;

  String get _messageChannel => 'user-room-$_userId';

  @override
  set serviceRequestId(int id) => _serviceRequestId = id;

  @override
  Stream<Message> get messageStream {
    /* the Envelope is not filled the same way for both types of messages...
content={senderId: 6187, serviceId: 88697, text: with one picture} 16549118932702816 1654911893270
content={message: {senderId: 6187, serviceId: 88697, text: with one picture}, file: {id: f548dd3e-4c15-41dd-85da-0e4a27254252, name: crab.jpg}} 16549116914626095
   */
    return _messageSubscription!.messages
        .where((pn.Envelope envelope) => envelope.content['start'] != true)
        .map((pn.Envelope envelope) {
      Map<String, dynamic> content;
      Map<String, dynamic> fileInfo = {};
      if (envelope.messageType == pn.MessageType.file) {
        content = envelope.content['message'];
        fileInfo = envelope.content['file'];
      } else {
        content = envelope.content;
      }
      _log.finest('received message content=${envelope.content}');

      return Message(
        isLocal: content['senderId'] == _userId,
        sentAt: envelope.publishedAt.toDateTime().millisecondsSinceEpoch,
        text: content['text'] ?? '',
        userId: content['senderId'],
        fileId: fileInfo['id'],
        fileName: fileInfo['name'],
      );
    });
  }

  Future<void> sendStart() async {
    return _sendMessage({
      'senderId': _userId,
      'start': true,
    });
  }

  @override
  Future<void> sendMessage(String text) async {
    return _sendMessage({
      'senderId': _userId,
      'serviceId': _serviceRequestId,
      'text': text,
    });
  }

  Future<void> _sendMessage(Map<String, dynamic> message) async {
    pn.PublishResult result = await _pubnub.publish(_messageChannel, message);
    if (result.isError) {
      throw PlatformUnknownException(result.description);
    }

    _log.finest('sent message=$message');
  }

  @override
  Future<SentFileInfo> sendFile(String fileName, List<int> file, {String? text}) async {
    Map<String, dynamic> content = {
      'senderId': _userId,
      'serviceId': _serviceRequestId,
      'text': text,
    };

    // TODO add cipher key for more privacy
    pn.PublishFileMessageResult result =
        await _pubnub.files.sendFile(_messageChannel, fileName, file, fileMessage: content);
    if (true == result.isError) {
      throw PlatformUnknownException(result.description ?? 'No provided error detail');
    }

    _log.finest('sent file $fileName with message: $content');
    return SentFileInfo(result.fileInfo!.id, url: result.fileInfo!.url, name: result.fileInfo!.name);
  }

  @override
  Uri getFileUrl(String fileId, String fileName) {
    return _pubnub.files.getFileUrl(_messageChannel, fileId, fileName);
  }

  @override
  Future<void> dispose() async {
    await _messageSubscription?.dispose();
  }
}
