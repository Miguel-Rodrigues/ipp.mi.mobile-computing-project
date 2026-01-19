import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'chat_page.dart';
import '../services/auth_service.dart';

class GroupListPage extends StatefulWidget {
  const GroupListPage({super.key});

  @override
  State<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance;

  bool _loading = true;

  // groupId -> groupName
  final Map<String, String> _groups = {};

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _loading = true;
      _groups.clear();
    });

    try {
      final userGroupsSnap = await _db.ref('userGroups/$uid').get();

      if (!userGroupsSnap.exists) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final Map<dynamic, dynamic> userGroups =
      userGroupsSnap.value as Map<dynamic, dynamic>;

      final groupIds = userGroups.entries
          .where((e) => e.value == true)
          .map((e) => e.key.toString())
          .toList();

      for (final groupId in groupIds) {
        final nameSnap = await _db.ref('groups/$groupId/name').get();
        final name = (nameSnap.value as String?) ?? groupId;
        _groups[groupId] = name;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _loading = false);
  }

  String _genGroupId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random.secure();
    final code = List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
    return 'g_$code';
  }

  Future<void> _createGroup(String name) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final groupId = _genGroupId();

    await _db.ref('groups/$groupId').set({'name': name});
    await _db.ref('members/$groupId/$uid').set(true);
    await _db.ref('userGroups/$uid/$groupId').set(true);

    await _loadGroups();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Grupo criado'),
        content: Text('Código do grupo:\n$groupId'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinGroup(String groupId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final existsSnap = await _db.ref('groups/$groupId/name').get();
      if (!existsSnap.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grupo não existe.')),
        );
        return;
      }

      await _db.ref('members/$groupId/$uid').set(true);
      await _db.ref('userGroups/$uid/$groupId').set(true);

      await _loadGroups();
    } catch (_) {}
  }

  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Criar grupo'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(hintText: 'Nome do grupo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    final name = nameCtrl.text.trim();
    if (ok == true && name.isNotEmpty) {
      await _createGroup(name);
    }
  }

  Future<void> _showJoinDialog() async {
    final idCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Entrar num grupo'),
        content: TextField(
          controller: idCtrl,
          decoration: const InputDecoration(hintText: 'Código (ex: g_a1b2c3)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Entrar'),
          ),
        ],
      ),
    );

    final groupId = idCtrl.text.trim();
    if (ok == true && groupId.isNotEmpty) {
      await _joinGroup(groupId);
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService().logout();
      // AuthWrapper (main.dart) deve mandar para LoginPage automaticamente
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao fazer logout.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final entries = _groups.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grupos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          IconButton(
            icon: const Icon(Icons.login),
            tooltip: 'Entrar por código',
            onPressed: _showJoinDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar',
            onPressed: _loadGroups,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: entries.isEmpty
          ? const Center(child: Text('Não tens grupos.'))
          : ListView.builder(
        itemCount: entries.length,
        itemBuilder: (_, i) {
          final groupId = entries[i].key;
          final name = entries[i].value;

          return ListTile(
            title: Text(name),
            subtitle: Text(groupId),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(groupId: groupId),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
