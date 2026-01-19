import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'chat_group_page.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();
  final _groupIdController = TextEditingController();

  @override
  void dispose() {
    _groupIdController.dispose();
    super.dispose();
  }

  Future<void> _joinGroup(String groupId) async {
    final uid = _auth.currentUser!.uid;

    // Marca membership (cumpre regras)
    await _db.child('members/$groupId/$uid').set(true);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatGroupPage(groupId: groupId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser!.uid;
    final myGroupsRef = _db.child('members');

    return Scaffold(
      appBar: AppBar(title: const Text('Salas / Grupos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Entrar/Cria grupo rapidamente
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _groupIdController,
                    decoration: const InputDecoration(
                      labelText: 'Group ID (ex: turmaA)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final id = _groupIdController.text.trim();
                    if (id.isEmpty) return;
                    _joinGroup(id);
                  },
                  child: const Text('Entrar'),
                )
              ],
            ),
            const SizedBox(height: 16),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Os meus grupos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: myGroupsRef.onValue,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final val = snapshot.data!.snapshot.value;
                  if (val is! Map) {
                    return const Center(child: Text('Ainda não estás em grupos.'));
                  }

                  // filtra grupos onde members[groupId][uid] == true
                  final map = Map<String, dynamic>.from(val as Map);
                  final groups = <String>[];

                  for (final entry in map.entries) {
                    final groupId = entry.key;
                    final membersMap = entry.value;
                    if (membersMap is Map && membersMap[uid] == true) {
                      groups.add(groupId);
                    }
                  }

                  if (groups.isEmpty) {
                    return const Center(child: Text('Ainda não estás em grupos.'));
                  }

                  groups.sort();

                  return ListView.separated(
                    itemCount: groups.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final groupId = groups[i];
                      return ListTile(
                        title: Text(groupId),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _joinGroup(groupId),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
