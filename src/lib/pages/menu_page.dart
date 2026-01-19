import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'chat_page.dart';
import 'calendar_page.dart';
import 'sport_page.dart';
import 'emergency_page.dart';
import 'health_page.dart';
import 'ai_search_page.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  void _go(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItemData>[
      _MenuItemData(
        icon: Icons.chat_bubble_outline,
        label: 'Chat',
        onTap: () => _go(context, const ChatPage()),
      ),
      _MenuItemData(
        icon: Icons.calendar_month,
        label: 'Calendário',
        onTap: () => _go(context, const CalendarPage()),
      ),
      _MenuItemData(
        icon: Icons.sports_soccer,
        label: 'Desporto',
        onTap: () => _go(context, const SportPage()),
      ),
      _MenuItemData(
        icon: Icons.emergency,
        label: 'Emergência',
        onTap: () => _go(context, const EmergencyPage()),
      ),
      _MenuItemData(
        icon: Icons.health_and_safety,
        label: 'Saúde',
        onTap: () => _go(context, const HealthPage()),
      ),
      _MenuItemData(
        icon: Icons.psychology,
        label: 'Pesquisa IA',
        onTap: () => _go(context, const AiSearchPage()),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          IconButton(
            tooltip: 'Terminar sessão',
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
          // 1) Background image (ajusta o caminho conforme o teu asset)
          Image.asset(
            'assets/menu_bg.png',
            fit: BoxFit.cover,
          ),

          // 2) Overlay para legibilidade (ajusta 0.25–0.60)
          Container(
            color: Colors.black.withOpacity(0.35),
          ),

          // 3) Conteúdo do menu
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 2, // 2 colunas x 3 linhas
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.10,
              children: [
                for (final item in items)
                  _MenuTile(
                    icon: item.icon,
                    label: item.label,
                    onTap: item.onTap,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _MenuItemData({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Ajuste para ficar legível em cima do fundo
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black.withOpacity(0.35),
          border: Border.all(
            color: Colors.white.withOpacity(0.18),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 46, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

