import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:segment_display/segment_display.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class CanMessage {
  final String timestamp;
  final int id;
  final bool isExtended;
  final int dlc;
  final List<int> data;

  CanMessage({
    required this.timestamp,
    required this.id,
    required this.isExtended,
    required this.dlc,
    required this.data,
  });

  factory CanMessage.fromJson(Map<String, dynamic> json) {
    return CanMessage(
      timestamp: json['timestamp'] as String,
      id: json['id'] as int,
      isExtended: json['is_extended'] as bool,
      dlc: json['dlc'] as int,
      data: List<int>.from(json['data'] as List),
    );
  }

  String get dataHex => data
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join(' ')
      .toUpperCase();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final FocusNode _focusNode = FocusNode();
  WebSocketChannel? _channel;
  CanMessage? _lastCanMessage;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  static const String _wsUrl = 'ws://0.0.0.0:8765';

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _subscription = _channel!.stream.listen(
        (message) {
          try {
            final jsonData =
                jsonDecode(message as String) as Map<String, dynamic>;
            final canMsg = CanMessage.fromJson(jsonData);
            if (canMsg.id == 0x7A2) {
              if (canMsg.data[0] == 0x00) {
                _counter = canMsg.data[2];
              }
            }
            if (mounted) {
              setState(() {
                _lastCanMessage = canMsg;
                _isConnected = true;
              });
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _isConnected = false;
              });
            }
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isConnected = false;
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isConnected = false;
            });
          }
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _connectWebSocket();
            }
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    _focusNode.dispose();
    super.dispose();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _decrementCounter() {
    setState(() {
      if (_counter > 0) {
        _counter--;
      }
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.add ||
          event.logicalKey == LogicalKeyboardKey.equal) {
        _incrementCounter();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.minus) {
        _decrementCounter();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        _incrementCounter();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Transform(
                    transform: Matrix4.skewX(-0.2),
                    alignment: Alignment.center,
                    child: SevenSegmentDisplay(
                      value: _counter.toString(),
                      segmentStyle: HexSegmentStyle(
                        disabledColor: Colors.greenAccent.withOpacity(0.1),
                        enabledColor: Colors.green,
                        segmentBaseSize: const Size(1.0, 2.0),
                        segmentSpacing: 1.0,
                      ),
                      backgroundColor: Colors.transparent,
                      characterCount: 3,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 30),
                  Transform(
                    transform: Matrix4.skewX(-0.2),
                    alignment: Alignment.center,
                    child: FourteenSegmentDisplay(
                      value: 'km/h',
                      segmentStyle: HexSegmentStyle(
                        disabledColor: Colors.greenAccent.withOpacity(0.1),
                        enabledColor: Colors.green,
                        //segmentBaseSize: const Size(1.0, 2.0),
                      ),
                      backgroundColor: Colors.transparent,
                      //characterCount: 5,
                      size: 8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              /*if (_lastCanMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isConnected ? Colors.green : Colors.red,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isConnected ? Icons.check_circle : Icons.error,
                            color: _isConnected ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isConnected ? 'Conectado' : 'Desconectado',
                            style: TextStyle(
                              color: _isConnected ? Colors.green : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildCanInfoRow(
                        'ID',
                        '0x${_lastCanMessage!.id.toRadixString(16).toUpperCase().padLeft(3, '0')}',
                      ),
                      _buildCanInfoRow(
                        'Extended',
                        _lastCanMessage!.isExtended ? 'Sí' : 'No',
                      ),
                      _buildCanInfoRow('DLC', '${_lastCanMessage!.dlc}'),
                      _buildCanInfoRow('Data', _lastCanMessage!.dataHex),
                      const SizedBox(height: 8),
                      Text(
                        'Timestamp: ${_lastCanMessage!.timestamp}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        color: Colors.orange,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Esperando mensajes CAN...',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],*/
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCanInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
