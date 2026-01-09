import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/auth_service.dart';
import '../message.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final auth = FirebaseAuth.instance;
  final db = FirebaseDatabase.instance.ref('messages');
  final controller = TextEditingController();
  final List<Message> messages = [];

  @override
  void initState() {
    super.initState();
    messages.clear();

    db.onChildAdded.listen((event) {
      final data = Map<String, dynamic>.from(
        event.snapshot.value as Map,
      );
      setState(() {
        messages.add(Message.fromMap(data));
      });
    });
  }

  void send() {
    if (controller.text.trim().isEmpty) return;

    final user = auth.currentUser!;
    db.push().set(
      Message(
        text: controller.text.trim(),
        userId: user.uid,
        email: user.email ?? 'anon',
      ).toMap(),
    );

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final msg = messages[i];
                final isMe = msg.userId == user.uid;

                return Align(
                  alignment:
                  isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                      isMe ? Colors.blue : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe)
                          Text(msg.email,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70)),
                        Text(msg.text),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration:
                    const InputDecoration(hintText: "Mensagem"),
                    onSubmitted: (_) => send(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: send,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
