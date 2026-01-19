import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatGroupPage extends StatefulWidget {
  final String groupId;
  const ChatGroupPage({super.key, required this.groupId});

  @override
  State<ChatGroupPage> createState() => _ChatGroupPageState();
}

class _ChatGroupPageState extends State<ChatGroupPage> {
  final _auth = FirebaseAuth.instance;
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  late final DatabaseReference _chatRef;
  late final DatabaseReference _typingRef;
  late final Query _messagesQuery;

  StreamSubscription<DatabaseEvent>? _msgSub;
  StreamSubscription<DatabaseEvent>? _typingSub;

  final List<_ChatMsg> _messages = [];
  final Set<String> _typingUsers = {}; // uids a escrever (exclui o próprio)

  bool _sending = false;

  Timer? _typingDebounce;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();

    _chatRef = FirebaseDatabase.instance.ref('chats/${widget.groupId}');
    _typingRef = FirebaseDatabase.instance.ref('typing/${widget.groupId}');
    _messagesQuery = _chatRef.orderByChild('ts').limitToLast(200); // eficiência (listas grandes)

    _listenMessages();
    _listenTyping();

    // remover typing ao fechar/crash
    final myTypingNode = _typingRef.child(_auth.currentUser!.uid);
    myTypingNode.onDisconnect().remove();
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _msgSub?.cancel();
    _typingSub?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _listenMessages() {
    _msgSub = _messagesQuery.onChildAdded.listen((event) {
      final value = event.snapshot.value;
      if (value is! Map) return;

      final map = Map<String, dynamic>.from(value as Map);

      final msg = _ChatMsg(
        id: event.snapshot.key ?? '',
        text: (map['text'] ?? '').toString(),
        senderUid: (map['senderUid'] ?? '').toString(),
        ts: (map['ts'] is int) ? map['ts'] as int : 0,
      );

      setState(() {
        _messages.add(msg);
        _messages.sort((a, b) => a.ts.compareTo(b.ts));
      });

      _autoScrollToBottom();
    });
  }

  void _listenTyping() {
    final myUid = _auth.currentUser!.uid;

    _typingSub = _typingRef.onValue.listen((event) {
      final value = event.snapshot.value;

      final next = <String>{};

      if (value is Map) {
        final map = Map<String, dynamic>.from(value as Map);
        for (final e in map.entries) {
          final uid = e.key;
          final isTyping = e.value == true;
          if (uid != myUid && isTyping) next.add(uid);
        }
      }

      setState(() {
        _typingUsers
          ..clear()
          ..addAll(next);
      });
    });
  }

  void _autoScrollToBottom() {
    // Requisito: ScrollController.animateTo(...)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);

    final uid = _auth.currentUser!.uid;

    // schema correto + ts server-side
    await _chatRef.push().set({
      'text': text,
      'senderUid': uid,
      'ts': ServerValue.timestamp,
    });

    _controller.clear();
    _setTyping(false);

    setState(() => _sending = false);
    _autoScrollToBottom();
  }

  void _setTyping(bool value) {
    if (_isTyping == value) return;
    _isTyping = value;

    final uid = _auth.currentUser!.uid;
    _typingRef.child(uid).set(value);

    if (!value) {
      _typingRef.child(uid).remove();
    }
  }

  void _onChanged(String _) {
    // “a escrever…” com debounce
    _setTyping(true);

    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 900), () {
      _setTyping(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat: ${widget.groupId}'),
      ),
      body: Column(
        children: [
          if (_typingUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _typingUsers.length == 1
                      ? 'Alguém está a escrever…'
                      : '${_typingUsers.length} pessoas estão a escrever…',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ),

          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                final isMe = msg.senderUid == myUid;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 520),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: _onChanged,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Mensagem (texto + emoji)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sending ? null : _send,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMsg {
  final String id;
  final String text;
  final String senderUid;
  final int ts;

  _ChatMsg({
    required this.id,
    required this.text,
    required this.senderUid,
    required this.ts,
  });
}
