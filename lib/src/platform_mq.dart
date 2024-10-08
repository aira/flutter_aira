import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'models/session.dart';
import 'platform_client.dart';
import 'platform_exceptions.dart';
import 'platform_mq_server_client.dart'
    if (dart.library.html) 'platform_mq_browser_client.dart' as mqttsetup;

typedef MessageCallback = Future<void> Function(String message);

abstract class PlatformMQ {
  bool get isConnected;

  Future<void> subscribe(
    String topic,
    MqttQos qosLevel,
    MessageCallback onMessage,
  );

  Future<void> unsubscribe(String topic);

  Future<int> publish(String topic, MqttQos qosLevel, String message);

  void dispose();
}

class PlatformMQImpl implements PlatformMQ {
  final _log = Logger('PlatformMQImpl');

  final Session _session;
  late final MqttClient _client;
  final Map<String, List<MessageCallback>> _callbacksByTopic = {};
  Completer<void> _connectCompleter = Completer<void>();

  PlatformMQImpl._(this._session);

  Future<void> _init(
    PlatformEnvironment env, {
    String? lastWillMessage,
    String? lastWillTopic,
  }) async {
    _client = mqttsetup.setup(
      'wss://${_getEnvPrefix(env)}mqtt.aira.io/ws',
      _clientId,
    )
      ..autoReconnect = true
      ..keepAlivePeriod = 30
      ..setProtocolV311()
      ..websocketProtocols = ['mqtt']
      ..onAutoReconnect = _handleAutoReconnect
      ..onConnected = _handleConnected
      ..onSubscribed = _handleSubscribed
      ..onSubscribeFail = _handleSubscribeFail
      ..onUnsubscribed = _handleUnsubscribed;

    if (lastWillMessage != null && lastWillTopic != null) {
      _client.connectionMessage = MqttConnectMessage()
        ..startClean()
        ..withWillMessage(lastWillMessage)
        ..withWillQos(MqttQos.atLeastOnce)
        ..withWillTopic(lastWillTopic);
    }

    // Connect to the server (the connect happens asynchronously, so we'll complete _isConnected in _onConnected)
    // TODO: How should we handle connection errors?
    await _client.connect(
      'Token-${_session.token}',
      'x',
    ); // The password can be any non-empty string

    // Register our message handler (this needs to be done after calling `connect` to avoid a null value)
    _client.published!.listen(_handleData);
  }

  static Future<PlatformMQ> create(
    PlatformEnvironment env,
    Session session, {
    String? lastWillMessage,
    String? lastWillTopic,
  }) async {
    PlatformMQImpl instance = PlatformMQImpl._(session);
    await instance._init(
      env,
      lastWillMessage: lastWillMessage,
      lastWillTopic: lastWillTopic,
    );
    return instance;
  }

  String get _clientId {
    // Right now, we're using a client ID with a random suffix because we don't need the broker to persist state
    // across sessions. But, is there a use case where persisting state would be useful? For instance, what if the
    // Explorer had to shut down the mobile app (or reload the web app) because of an error and we wanted to resume
    // the session on launch? If so, maybe we should use a device ID instead of a random suffix.
    return '${_session.userId}_${Random().nextInt(10000)}';
  }

  void _handleData(MqttPublishMessage message) {
    String topic = message.variableHeader!.topicName;
    String decoded = utf8.decode(message.payload.message);
    _log.finest(
      'received message client_id=${_client.clientIdentifier} topic=$topic message=$decoded',
    );

    for (final MessageCallback callback in _callbacksByTopic[topic] ?? []) {
      callback(decoded).catchError(
        (e) => _log.shout('failed to handle message topic=$topic', e),
      );
    }
  }

  @override
  bool get isConnected => _connectCompleter.isCompleted;

  @override
  Future<void> subscribe(
    String topic,
    MqttQos qosLevel,
    MessageCallback onMessage,
  ) async {
    await _connectCompleter.future;

    _log.info(
      'subscribe client_id=${_client.clientIdentifier} topic=$topic qosLevel=$qosLevel',
    );

    Subscription? subscription = _client.subscribe(topic, qosLevel);
    if (subscription == null) {
      throw const PlatformUnknownException('Topic subscription failed');
    }

    List<MessageCallback> callbacks =
        _callbacksByTopic.putIfAbsent(topic, () => []);
    callbacks.add(onMessage);

    // REVIEW: If the subscription fails, the caller will not know. That's probably okay for now (we'll have the logs)
    // but may be something to address in the future. We could return a Completer<void> and complete it in
    // _onSubscribed and _onSubscribeFail, but we need to make sure to handle race conditions and re-subscribes.
  }

  @override
  Future<void> unsubscribe(String topic) async {
    await _connectCompleter.future;

    _log.info('unsubscribe client_id=${_client.clientIdentifier} topic=$topic');

    _client.unsubscribe(topic);
    _callbacksByTopic.remove(topic);
  }

  @override
  Future<int> publish(String topic, MqttQos qosLevel, String message) async {
    await _connectCompleter.future;

    _log.finest(
      'publishing message client_id=${_client.clientIdentifier} topic=$topic message=$message',
    );

    MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);

    return _client.publishMessage(topic, qosLevel, builder.payload!);
  }

  void _handleAutoReconnect() {
    _log.warning('reconnecting client_id=${_client.clientIdentifier}');
    _connectCompleter = Completer<void>();
  }

  void _handleConnected() {
    _log.info('connected client_id=${_client.clientIdentifier}');
    _connectCompleter.complete();
  }

  void _handleSubscribed(String topic) {
    _log.info('subscribed client_id=${_client.clientIdentifier} topic=$topic');
  }

  void _handleSubscribeFail(String topic) {
    _log.shout(
      'subscribe failed client_id=${_client.clientIdentifier} topic=$topic',
    );
  }

  void _handleUnsubscribed(String? topic) {
    _log.info(
      'unsubscribed client_id=${_client.clientIdentifier} topic=$topic',
    );
  }

  @override
  void dispose() async {
    _log.info('disconnecting client_id=${_client.clientIdentifier}');
    _client.disconnect();
    _callbacksByTopic.clear();
  }

  String _getEnvPrefix(PlatformEnvironment env) {
    switch (env) {
      case PlatformEnvironment.staging:
        return 'staging-';
      case PlatformEnvironment.dev:
        return 'dev-';
      case PlatformEnvironment.prod:
        return '';
    }
  }
}
