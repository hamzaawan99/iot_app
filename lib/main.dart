import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
//import 'package:iot_app/mqtt_client.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter MQTT Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter MQTT Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late MqttClient client;
  var topic = "Temperature";
  String _temperature = "0";
  dynamic payload = "0";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_temperature),
            ElevatedButton(
              child: const Text('Connect'),
              onPressed: () => {
                connect().then((value) {
                  client = value;
                })
              },
            ),
            ElevatedButton(
              child: const Text('Subscribe'),
              onPressed: () {
                client.subscribe(topic, MqttQos.atLeastOnce);
                /*setState(() {
                  _temperature = updateTemperature(client);
                });*/
              },
            ),
            ElevatedButton(
              child: const Text('Unsubscribe'),
              onPressed: () => {client.unsubscribe(topic)},
            ),
            ElevatedButton(
              child: const Text('Disconnect'),
              onPressed: () => {client.disconnect()},
            ),
          ],
        ),
      ),
    );
  }

  Future<MqttClient> connect() async {
  
  MqttServerClient client =
      MqttServerClient.withPort('tailor.cloudmqtt.com', 'flutter_client', 13188);
  client.logging(on: true);
  client.onConnected = onConnected;
  client.onDisconnected = onDisconnected;
  //client.onUnsubscribed = onUnsubscribed;
  client.onSubscribed = onSubscribed;
  client.onSubscribeFail = onSubscribeFail;
  client.pongCallback = pong;

  final connMess = MqttConnectMessage()
      .withClientIdentifier("flutter_client")
      .authenticateAs("qbcaqkil", "eYlPO88NSC9o")
      .withWillTopic('willtopic')
      .withWillMessage('My Will message')
      .startClean()
      .withWillQos(MqttQos.atLeastOnce);
  client.connectionMessage = connMess;
  try {
    print('Connecting');
    await client.connect();
  } catch (e) {
    print('Exception: $e');
    client.disconnect();
  }

  if (client.connectionStatus?.state == MqttConnectionState.connected) {
    print('EMQX client connected');
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);
      setState(() {
        _temperature = payload;
      });

      print('Received message:$payload from topic: ${c[0].topic}>');
    });
  } else {
    print(
        'EMQX client connection failed - disconnecting, status is ${client.connectionStatus}');
    client.disconnect();
    //exit(-1);
  }

  return client;
}

void onConnected() {
  print('Connected');
}

void onDisconnected() {
  print('Disconnected');
}

void onSubscribed(String topic) {
  print('Subscribed topic: $topic');
}

void onSubscribeFail(String topic) {
  print('Failed to subscribe topic: $topic');
}

void onUnsubscribed(String topic) {
  print('Unsubscribed topic: $topic');
}

void pong() {
  print('Ping response client callback invoked');
}
}