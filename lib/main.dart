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
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text("Shahmaat test"),
    ),
    body: Center(
      child: OutlinedButton.icon(
        icon: Icon(Icons.start),
        label: Text("Connect to server"),

        onPressed: () async {
          final channel = WebSocketChannel.connect(
            Uri.parse("wss://localhost:8080"),
            protocols: ["shahmaat_protocol_$protocolVersion"],
          );
          debugPrint("Sent message");
          channel.sink.add("Hello from Flutter!");
          final String message = await channel.stream.first;
          debugPrint("Received: $message");
          channel.sink.close();
        },
      ),
    ),
  );
}
