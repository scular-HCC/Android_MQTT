
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mqtt_client/mqtt_client.dart';
//import 'package:mqtt_client/mqtt_browser_client.dart'; // For web/browser only
import 'package:mqtt_client/mqtt_server_client.dart';
//import 'package:flutter/foundation.dart';

enum MqttStatus { disconnected, connecting, connected, error }

class MqttService {
  MqttClient? client;

  final String broker;
  final String clientIdentifier;
  final String topic;
  final String username;
  final String password;

  MqttStatus status = MqttStatus.disconnected;
  String lastError = '';

  MqttService({
    required this.broker,
    required this.clientIdentifier,
    required this.topic,
    required this.username,
    required this.password,
  });

  Future<void> connect(
    void Function(String message) onMessage,
    void Function(MqttStatus status, String error) onStatus,
  ) async {
    
//debugPrint('MQTT CONNECT DEBUG');
//debugPrint('Broker: $broker');
//debugPrint('Client ID: $clientIdentifier');
//debugPrint('Username length: ${username.length}');
//debugPrint('Password length: ${password.length}');
//debugPrint('Username trimmed: "${username.trim()}"');
//debugPrint('Password trimmed length: ${password.trim().length}');

    status = MqttStatus.connecting;
    onStatus(status, '');

    try {
      
      if (username.trim().isEmpty || password.trim().isEmpty) {
        throw Exception('HiveMQ Cloud requires a username and password.');
      }


      if (kIsWeb) {
        final Client = MqttServerClient(
          'wss://$broker:8884/mqtt',
          clientIdentifier,
        );

        // ✅ REQUIRED FOR HIVE MQ CLOUD
        Client.websocketProtocols = ['mqtt'];

        client = Client;
      } else {
        client = MqttServerClient(broker, clientIdentifier)
          ..port = 8883
          ..secure = true;
      }

      client!
        ..keepAlivePeriod = 20
        ..autoReconnect = false
        ..logging(on: false)
        ..onConnected = () {
          status = MqttStatus.connected;
          onStatus(status, '');
        }
        ..onDisconnected = () {
          status = MqttStatus.disconnected;
          onStatus(status, lastError);
        }
        ..connectionMessage = MqttConnectMessage()
            .withClientIdentifier(clientIdentifier)
            .authenticateAs(username.trim(), password.trim())
            .startClean()
            .withWillQos(MqttQos.atMostOnce);

      await client!.connect();

      if (client!.connectionStatus?.state !=
          MqttConnectionState.connected) {
        throw Exception(
          'Connection rejected: ${client!.connectionStatus}',
        );
      }

      client!.subscribe(topic, MqttQos.atMostOnce);

      client!.updates?.listen((events) {
        final payload = MqttPublishPayload.bytesToStringAsString(
          (events.first.payload as MqttPublishMessage)
              .payload
              .message,
        );
        onMessage(payload);
      });
    } catch (e) {
      lastError = e.toString();
      status = MqttStatus.error;
      onStatus(status, lastError);
      client = null;
    }
  }

  void publish(String message) {
    if (client == null || status != MqttStatus.connected) return;

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client!.publishMessage(
        topic, MqttQos.atMostOnce, builder.payload!);
  }

  void disconnect() {
    client?.disconnect();
    client = null;
    status = MqttStatus.disconnected;
  }
}