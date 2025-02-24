import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const protocolVersion = "0.1.1";

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Shahmaat',
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
  WebSocketChannel _establishConnection() => WebSocketChannel.connect(
    Uri.parse("ws://localhost:8080"),
    protocols: ["shahmaat_protocol_$protocolVersion"],
  );

  late var _channel = _establishConnection();

  @override
  void dispose() async {
    await _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text("Shahmaat Server Ping"),
    ),
    body: Center(
      child: StreamBuilder(
        stream: _channel.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data.runtimeType == String) {
            debugPrint("Data contents: ${snapshot.data}");
          }

          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close, size: 78, color: Colors.red),
                    Text(
                      "Connection closed",
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: FilledButton.icon(
                    icon: Icon(Icons.refresh, size: 30),
                    label: Text("Retry", style: TextStyle(fontSize: 30)),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(220, 80),
                    ),
                    onPressed: () async {
                      await _channel.sink.close();
                      setState(() => _channel = _establishConnection());
                    },
                  ),
                ),
              ],
            );
          } else if (snapshot.connectionState != ConnectionState.none) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: FloatingActionButton.extended(
                    icon: Icon(Icons.cable),
                    label: Text("Ping server"),
                    onPressed: () async {
                      _channel.sink.add("Hello from Flutter!");
                      debugPrint("Sent message");
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.close),
                    label: Text("Close connection"),
                    onPressed: () async {
                      await _channel.sink.close();
                      setState(() {});
                    },
                  ),
                ),
              ],
            );
          } else {
            return Container();
          }
        },
      ),
    ),
  );
}
