import 'package:flutter/cupertino.dart';
import 'package:test_chat_app/main.dart';

class ChatClientView extends StatefulWidget {
  final ChatClient client;
  const ChatClientView({super.key, required this.client});

  @override
  State<ChatClientView> createState() => _ChatClientViewState();
}

class _ChatClientViewState extends State<ChatClientView> {
  final TextEditingController controller = TextEditingController();
  final List<String> messages = [];

  @override
  void initState() {
    super.initState();
    widget.client.messages.listen((msg) {
      setState(() {
        messages.add(msg);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return Text(messages[index]);
            },
          ),
        ),
        Row(
          children: [
            Expanded(
              child: CupertinoTextField(
                controller: controller,
                placeholder: "Send a message...",
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  client.sendMessage(text);
                  controller.clear();
                }
              },
              child: const Icon(CupertinoIcons.arrow_up_circle_fill),
            ),
          ],
        ),
      ],
    );
  }
}
