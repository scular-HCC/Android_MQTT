import 'package:flutter/material.dart';
import 'mqtt_service.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MqttHomePage(),
    );
  }
}

class MqttHomePage extends StatefulWidget {
  const MqttHomePage({super.key});

  @override
  State<MqttHomePage> createState() => _MqttHomePageState();
}


class _ReceivedMessage {
  final DateTime timestamp;
  final String payload;

  _ReceivedMessage({
    required this.timestamp,
    required this.payload,
  });
}

// Setup for the chart if received message is a number
class _NumericSample {
  final DateTime timestamp;
  final double value;

  _NumericSample({
    required this.timestamp,
    required this.value,
  });
}


class _MqttHomePageState extends State<MqttHomePage> {
  late MqttService mqttService;

  final TextEditingController messageController =
      TextEditingController();
  final TextEditingController hostController =
      TextEditingController(
        text:
            '04c777e55e2347da8ed690083f8fdea4.s1.eu.hivemq.cloud',
      );
  final TextEditingController clientIdController =
      TextEditingController(text: 'BRB');
  final TextEditingController usernameController =
      TextEditingController();
  final TextEditingController passwordController =
      TextEditingController();

  static const String topic = 'test/flutter';

  final List<_ReceivedMessage> receivedMessages = [];

  final List<_NumericSample> numericSamples = []; // required for the chart

  String _formatTimestamp(DateTime time) {
    return '${time.year.toString().padLeft(4, '0')}-'
          '${time.month.toString().padLeft(2, '0')}-'
          '${time.day.toString().padLeft(2, '0')} '
          '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}:'
          '${time.second.toString().padLeft(2, '0')}';
  }

  String receivedMessage = 'Waiting for messages...';
  String activeClientId = '';

  MqttStatus connectionStatus = MqttStatus.disconnected;
  String connectionError = '';

  bool get isWeb => identical(0, 0.0);

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    final uniqueClientId =
        '${clientIdController.text}_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      activeClientId = uniqueClientId;
    });

    
    mqttService = MqttService(
      broker: hostController.text,
      clientIdentifier: uniqueClientId,
      topic: topic,
      username: usernameController.text,
      password: passwordController.text,
    );



    mqttService.connect(
      (message) {
        setState(() {
          receivedMessage = message;
          
          final now = DateTime.now();

            receivedMessages.add(
              _ReceivedMessage(
                timestamp: now,
                payload: message,
              ),
            );

            // Try to parse numeric payloads
            final parsedValue = double.tryParse(message.trim());
            if (parsedValue != null) {
              numericSamples.add(
                _NumericSample(
                  timestamp: now,
                  value: parsedValue,
                ),
              );
            }
        });
      },
      (status, error) {
        setState(() {
          connectionStatus = status;
          connectionError = error;
        });
      },
    );
  }

  void _reconnect() {
    mqttService.disconnect();
    _connect();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    mqttService.disconnect();
    messageController.dispose();
    hostController.dispose();
    clientIdController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

Widget _messageTable() {
  if (receivedMessages.isEmpty) {
    return const SizedBox.shrink();
  }

  return Card(
    child: SizedBox(
      height: receivedMessages.length >= 5 ? 220 : null,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Timestamp')),
            DataColumn(label: Text('Payload')),
          ],
          rows: List.generate(
            receivedMessages.length,
            (index) {
              final msg = receivedMessages[index];
              return DataRow(
                cells: [
                  DataCell(Text('${index + 1}')),
                  DataCell(
                    SelectableText(
                      _formatTimestamp(msg.timestamp),
                    ),
                  ),
                  DataCell(
                    SelectableText(msg.payload),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

Widget _statusWidget() {
  Color color;
  String text;

  switch (connectionStatus) {
    case MqttStatus.connected:
      color = Colors.green;
      text = 'Connected';
      break;
    case MqttStatus.connecting:
      color = Colors.orange;
      text = 'Connecting...';
      break;
    case MqttStatus.error:
      color = Colors.red;
      text = 'Error: $connectionError';
      break;
    default:
      color = Colors.grey;
      text = 'Disconnected';
  }

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.circle, color: color, size: 12),
      const SizedBox(width: 8),
      Flexible(
        child: SelectableText(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );
}


  Widget _connectionInfoWidget() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Connection',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText('Host: ${hostController.text}'),
            SelectableText('Client ID: $activeClientId'),
            SelectableText('Topic: $topic'),
          ],
        ),
      ),
    );
  }


  Widget _numericPlot() {
    if (numericSamples.length < 2) {
      return const SizedBox.shrink();
    }

    final spots = numericSamples.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.value,
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Numeric Payload Plot',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BedRockBeach MQTT'),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Text(
                'MQTT Settings',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: hostController,
                decoration:
                    const InputDecoration(labelText: 'Broker Host'),
              ),
              TextField(
                controller: clientIdController,
                decoration:
                    const InputDecoration(labelText: 'Client ID'),
              ),
              TextField(
                controller: usernameController,
                decoration:
                    const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: passwordController,
                decoration:
                    const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _reconnect,
                child: const Text('Reconnect'),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.asset(
              'assets/images/SC_Logo_Blue.png',
              height: 80,
            ),
            const SizedBox(height: 12),
            const Text(
              'Made for:\n'
              'Howard Community College\n'
              'Department of Engineering and Technology',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _statusWidget(),
            const SizedBox(height: 12),
            Text(
              isWeb
                  ? 'Transport: Secure WebSocket (wss : 8884)'
                  : 'Transport: Secure MQTT (TLS : 8883)',
              style:
                  const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _connectionInfoWidget(),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  receivedMessage,
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          _messageTable(), // List of all received messages
          
          _messageTable(), 
          const SizedBox(height: 16),
          _numericPlot(),

          // Button to clear list of messages
          ElevatedButton(
            onPressed: () {
              setState(() {
                receivedMessages.clear();
                receivedMessage = 'Waiting for messages...';
              });
            },
            child: const Text('Clear Messages'),
          ), 


            const SizedBox(height: 20),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message to Publish',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                mqttService.publish(messageController.text);
                messageController.clear();
              },
              child: const Text('Publish'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                mqttService.publish('TEST_MESSAGE_FROM_FLUTTER');
              },
              child: const SelectableText('Test MQTT Connection'),
            ),
          ],
        ),
      ),
    );
  }
}