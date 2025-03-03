import 'package:flutter/material.dart';
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
  static WebSocketChannel _establishConnection() => WebSocketChannel.connect(
    Uri.parse("ws://localhost:8080"),
    protocols: ["shahmaat_protocol_$protocolVersion"],
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
            if (snapshot.hasError) throw snapshot.error!;

            return Stack(
              children: [
                Playfield(channel: _channel!),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.close),
                    label: Text("Close connection"),
                    onPressed: () async {
                      _channel?.sink.close();
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
                      padding: const EdgeInsets.all(16),
                      child: Icon(Icons.power_off, size: 48),
                    ),
                    Text(
                      "Disconnected",
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        Icons.power_off,
                        size: 48,
                        color: Color(0x00000000),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: FilledButton.icon(
                    icon: Icon(Icons.power, size: 30),
                    label: Text("Connect", style: TextStyle(fontSize: 30)),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(200, 80),
                    ),
                    onPressed: () async {
                      _channel?.sink.close();
                      setState(() => _channel = _establishConnection());
                    },
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
