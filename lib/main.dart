import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'playfield.dart';

const protocolVersion = "0.1.0";

void main() => runApp(const Shahmaat());

class Shahmaat extends StatelessWidget {
  const Shahmaat({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: "Shahmaat",
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    ),
    home: const MyHomePage(),
  );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static WebSocketChannel _establishConnection() => IOWebSocketChannel.connect(
    Uri.parse("ws://localhost:8080"),
    protocols: ["shahmaat_protocol_$protocolVersion"],
    pingInterval: Duration(seconds: 10),
  );

  WebSocketChannel? _channel = _establishConnection();

  @override
  void dispose() async {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text("Shahmaat"),
    ),
    body: Center(
      child: FutureBuilder(
        future: _channel?.ready,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.connectionState == ConnectionState.done) {
            return snapshot.hasError
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Error: ${snapshot.error}"),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: FilledButton.icon(
                        icon: Icon(Icons.replay),
                        label: Text("Try again"),
                        onPressed: () async {
                          _channel?.sink.close();
                          setState(() => _channel = _establishConnection());
                        },
                      ),
                    ),
                  ],
                )
                : Stack(
                  children: [
                    StreamHandler(channel: _channel!),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.close),
                        label: Text("Close connection"),
                        onPressed: () async {
                          await _channel?.sink.close();
                          setState(() => _channel = null);
                        },
                      ),
                    ),
                  ],
                );
          } else {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.power_off),
                    ),
                    Text(
                      "Disconnected",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: FilledButton.icon(
                    icon: Icon(Icons.power),
                    label: Text("Connect"),
                    onPressed:
                        () => setState(() => _channel = _establishConnection()),
                  ),
                ),
              ],
            );
          }
        },
      ),
    ),
  );
}
