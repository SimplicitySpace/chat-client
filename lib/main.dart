import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:test_chat_app/chat_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: MultiClientHome(),
    );
  }
}

class MultiClientHome extends StatefulWidget {
  const MultiClientHome({super.key});

  @override
  State<MultiClientHome> createState() => _MultiClientHomeState();
}

class _MultiClientHomeState extends State<MultiClientHome> {
  final List<ChatClient> clients = [];
  int selectedIndex = 0;
  final String host = "192.168.1.115";
  final int port = 8080;

  Future<void> createNewClient() async {
    print("Callling new client");
    try {
      final id = clients.length;
      final client = ChatClient(id: id, host: host, port: port);
      await client.connect();
      setState(() {
        clients.add(client);
        selectedIndex = clients.length - 1;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    for (final client in clients) {
      client.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasClients = clients.isNotEmpty;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('TCP Multi-Client Chat'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: createNewClient,
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: hasClients
            ? Column(
                children: [
                  // Client Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(clients.length, (index) {
                        final isSelected = selectedIndex == index;
                        return CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          onPressed: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          child: Text(
                            "Client ${clients[index].id}",
                            style: TextStyle(
                              color: isSelected
                                  ? CupertinoColors.activeBlue
                                  : CupertinoColors.inactiveGray,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  Expanded(
                    child: ChatClientView(client: clients[selectedIndex]),
                  ),
                ],
              )
            : Center(
                child: CupertinoButton.filled(
                  onPressed: createNewClient,
                  child: const Text("Create First Client"),
                ),
              ),
      ),
    );
  }
}

class ChatClient {
  final int id;
  final String host;
  final int port;
  Socket? _socket;
  final _messages = StreamController<String>.broadcast();

  ChatClient({required this.id, required this.host, required this.port});

  Stream<String> get messages => _messages.stream;

  Future<void> connect() async {
    _socket = await Socket.connect(host, port);
    print("Client $id connected");
    _socket!.write("100|$id|Hello from client $id\n");

    _socket!.listen((data) {
      final raw = String.fromCharCodes(data).trim();
      final parts = raw.split('|');

      // Expecting format: 100|senderId|message
      if (parts.length >= 3) {
        final senderId = parts[1];
        final msg = parts.sublist(2).join('|');

        final display = "Client $senderId: $msg";
        print(display);
        _messages.add(display);
      } else {
        print("Received malformed message: $raw");
      }
    });
  }

  void sendMessage(String msg) {
    final formatted = "100|$id|$msg\n";
    _socket?.write(formatted);
  }

  void close() {
    _socket?.destroy();
  }
}
