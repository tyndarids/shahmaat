import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'playfield.dart';

const protocolVersion = "0.1.0";
const protocol = "shahmaat_protocol_$protocolVersion";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(Shahmaat(packageInfo: await PackageInfo.fromPlatform()));
}

class Shahmaat extends StatelessWidget {
  const Shahmaat({super.key, required this.packageInfo});

  final PackageInfo packageInfo;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: "Shahmaat",
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      textTheme: GoogleFonts.interTextTheme(),
    ),
    home: Stack(
      children: [
        const MyHomePage(),
        kDebugMode
            ? Positioned(
              bottom: 8,
              right: 8,
              child: Text(
                "${packageInfo.appName} client\nversion ${packageInfo.version}\nshahmaat_protocol_$protocolVersion",
                style: GoogleFonts.jetBrainsMono().copyWith(
                  fontSize: 14,
                  color: Colors.black54,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.right,
              ),
            )
            : SizedBox.shrink(),
      ],
    ),
  );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static WebSocketChannel _establishConnection() => IOWebSocketChannel.connect(
    Uri.parse("ws://localhost:2617"),
    protocols: [protocol],
    pingInterval: Duration(seconds: 10),
  );

  WebSocketChannel? _channel = _establishConnection();

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
            if (_channel == null || snapshot.hasError) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      "$_channel\n${snapshot.error}",
                      style: GoogleFonts.jetBrainsMono(),
                    ),
                  ),
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
              );
            } else {
              if (_channel!.protocol == protocol) {
                debugPrint(
                  "Successfully negotiated a matching protocol with the server",
                );
              } else {
                debugPrint(
                  "WARNING: Protocol negotiation failed, server sent ${_channel?.protocol}",
                );
              }

              return Stack(
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
            }
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
