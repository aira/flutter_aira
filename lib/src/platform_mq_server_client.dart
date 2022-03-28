import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

// See https://github.com/shamblett/mqtt_client/blob/1b014e8ea793415bb0e8ed37d29ac9a763a009db/example/mqtt_client_universal.dart.
MqttClient setup(String server, String clientIdentifier) {
  var client = MqttServerClient.withPort(server, clientIdentifier, 443);
  client.useWebSocket = true;
  return client;
}
