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
      final value = event.snapshot.value;
      if (value is! Map) return;

      final data = Map<String, dynamic>.from(value as Map);

      setState(() {
        messages.add(Message.fromMap(data));
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/chat_bg.png',
            fit: BoxFit.cover,
          ),

          // Overlay para legibilidade (ajusta 0.25 a 0.60 conforme o fundo)
          Container(
            color: Colors.black.withOpacity(0.20),
          ),

          // Conteúdo do chat
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
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
                          color: isMe
                              ? Colors.white.withOpacity(0.85)
                              : Colors.white.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(
                                msg.email,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                            Text(
                              msg.text,
                              style: const TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Mensagem",
                            hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.7)),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.35),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.90),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: send,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
