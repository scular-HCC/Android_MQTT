# Android_MQTT

> A starter project for students: a minimal working MQTT client to build on, not a finished product.

A Flutter app (Android) that connects to a HiveMQ Cloud MQTT broker over TLS, subscribes to a topic, lists every received message with a timestamp, plots numeric payloads on a line chart, and publishes messages of your own.

## Features
- Connects to a broker with a host, client ID, username and password you enter in the app (HiveMQ Cloud requires a username and password).
- Transport: secure MQTT (TLS, port 8883) on Android; secure WebSocket (wss, port 8884) when run in a browser.
- Subscribes to and publishes on the topic `test/flutter` (QoS 0).
- Scrollable table of received messages (number, timestamp, payload).
- "Numeric Payload Plot": payloads that parse as numbers are charted with `fl_chart`.
- Message box and **Publish** button, **Clear Messages**, **Reconnect**, and a **Test MQTT Connection** button.

## Build and run
Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK ^3.11.4) and an Android device or emulator.

```
cd mqtt_app
flutter clean
flutter pub get
flutter run                      # run on a connected device or emulator
flutter build apk --release      # or build an installable APK
```

Then enter your HiveMQ Cloud host, a client ID, and the username and password of a HiveMQ Cloud credential, and tap **Reconnect**.

Use `MqttServerClient` for Android, iOS and desktop. `MqttBrowserClient` is web-only and breaks Android builds.

Source: `mqtt_app/lib/main.dart` (UI) and `mqtt_app/lib/mqtt_service.dart` (MQTT connection).

## Change log


## 2026-04-17 Added scrollable list and plot to main page.  Publish button text not selectable.  Reduced font size at top.

## 2026-04-16 Tested and working on Android OS 16 (API 36)
