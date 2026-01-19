import 'package:flutter/material.dart';

import '../services/auth_service.dart';

import 'group_list_page.dart';
import 'calendar_page.dart';
import 'ai_search_page.dart';
import 'health_page.dart';
import 'sport_page.dart';
import 'emergency_page.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  void _go(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem(
        title: 'Chat (Grupos)',
        icon: Icons.chat_bubble_outline,
        onTap: () => _go(context, const GroupListPage()),
      ),
      _MenuItem(
        title: 'Calendário',
        icon: Icons.calendar_month,
        onTap: () => _go(context, const CalendarPage()),
      ),
      _MenuItem(
        title: 'AI Search',
        icon: Icons.search,
        onTap: () => _go(context, const AiSearchPage()),
      ),
      _MenuItem(
        title: 'Saúde',
        icon: Icons.health_and_safety_outlined,
        onTap: () => _go(context, const HealthPage()),
      ),
      _MenuItem(
        title: 'Desporto',
        icon: Icons.sports_soccer,
        onTap: () => _go(context, const SportPage()),
      ),
      _MenuItem(
        title: 'Emergência',
        icon: Icons.emergency_outlined,
        onTap: () => _go(context, const EmergencyPage()),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/menu_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          Container(color: Colors.black.withAlpha(64)),
          SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final it = items[i];
                return Card(
                  color: Colors.white.withAlpha(230),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: Icon(it.icon),
                    title: Text(
                      it.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: it.onTap,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  _MenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}
