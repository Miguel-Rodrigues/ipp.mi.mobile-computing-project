import 'package:flutter/material.dart';

class SportPage extends StatefulWidget {
  const SportPage({super.key});

  @override
  State<SportPage> createState() => _SportPageState();
}

class _SportPageState extends State<SportPage> {
  // Preferências simples
  String _level = 'Iniciante';
  String _goal = 'Ficar em forma';

  // Tracker semanal (exemplo)
  int _sessionsThisWeek = 2;
  int _minutesThisWeek = 75;

  // Objetivos recomendados (podem ser ajustados por nível)
  int get _targetSessions {
    switch (_level) {
      case 'Intermédio':
        return 4;
      case 'Avançado':
        return 5;
      default:
        return 3;
    }
  }

  int get _targetMinutes {
    switch (_level) {
      case 'Intermédio':
        return 150;
      case 'Avançado':
        return 210;
      default:
        return 90;
    }
  }

  double get _progressSessions =>
      (_sessionsThisWeek / _targetSessions).clamp(0.0, 1.0);

  double get _progressMinutes =>
      (_minutesThisWeek / _targetMinutes).clamp(0.0, 1.0);

  void _addSession({int minutes = 25}) {
    setState(() {
      _sessionsThisWeek += 1;
      _minutesThisWeek += minutes;
    });
  }

  void _resetWeek() {
    setState(() {
      _sessionsThisWeek = 0;
      _minutesThisWeek = 0;
    });
  }

  List<_WorkoutDay> get _plan {
    final base = <_WorkoutDay>[
      _WorkoutDay('Seg', 'Full body', '30–40 min'),
      _WorkoutDay('Ter', 'Cardio leve', '20–30 min'),
      _WorkoutDay('Qua', 'Força (pernas)', '30–40 min'),
      _WorkoutDay('Qui', 'Mobilidade + core', '15–25 min'),
      _WorkoutDay('Sex', 'Força (tronco)', '30–40 min'),
      _WorkoutDay('Sáb', 'Atividade livre', '30–60 min'),
      _WorkoutDay('Dom', 'Descanso', 'Recuperação'),
    ];

    if (_goal == 'Ganhar músculo') {
      return <_WorkoutDay>[
        _WorkoutDay('Seg', 'Push (peito/ombro)', '35–50 min'),
        _WorkoutDay('Ter', 'Pull (costas/bíceps)', '35–50 min'),
        _WorkoutDay('Qua', 'Pernas', '40–55 min'),
        _WorkoutDay('Qui', 'Core + mobilidade', '20–30 min'),
        _WorkoutDay('Sex', 'Full body leve', '30–40 min'),
        _WorkoutDay('Sáb', 'Caminhada / cardio', '25–45 min'),
        _WorkoutDay('Dom', 'Descanso', 'Recuperação'),
      ];
    }

    if (_goal == 'Perder peso') {
      return <_WorkoutDay>[
        _WorkoutDay('Seg', 'Cardio + core', '30–45 min'),
        _WorkoutDay('Ter', 'Full body', '30–40 min'),
        _WorkoutDay('Qua', 'Cardio intervalado', '20–30 min'),
        _WorkoutDay('Qui', 'Mobilidade', '15–25 min'),
        _WorkoutDay('Sex', 'Full body', '30–45 min'),
        _WorkoutDay('Sáb', 'Atividade livre', '45–60 min'),
        _WorkoutDay('Dom', 'Descanso', 'Recuperação'),
      ];
    }

    return base;
  }

  List<_Challenge> get _challenges => const [
    _Challenge(
      title: '7 dias de movimento',
      desc: 'Faz 15–20 min por dia (caminhar conta).',
      icon: Icons.local_fire_department,
    ),
    _Challenge(
      title: 'Alongar antes de dormir',
      desc: '5 min de alongamentos durante 5 dias.',
      icon: Icons.self_improvement,
    ),
    _Challenge(
      title: 'Água + treino',
      desc: 'Bebe água antes e depois do treino.',
      icon: Icons.water_drop,
    ),
    _Challenge(
      title: 'Passeio sem ecrã',
      desc: '30 min a andar sem telemóvel.',
      icon: Icons.directions_walk,
    ),
  ];

  List<_Tip> get _tips {
    final tips = <_Tip>[
      const _Tip(
        title: 'Aquecimento rápido (3 min)',
        desc: 'Saltos leves + mobilidade de ombros/quadril. Reduz lesões.',
        icon: Icons.timer,
      ),
      const _Tip(
        title: 'Recuperação',
        desc: 'Dormir 7–9h ajuda performance, humor e foco.',
        icon: Icons.nightlight_round,
      ),
      const _Tip(
        title: 'Hidratação',
        desc: 'Se a urina estiver muito escura, bebe mais água.',
        icon: Icons.water_drop_outlined,
      ),
    ];

    if (_level == 'Avançado') {
      tips.add(
        const _Tip(
          title: 'Deload',
          desc: 'Uma semana mais leve a cada 4–6 semanas melhora consistência.',
          icon: Icons.trending_down,
        ),
      );
    }

    if (_goal == 'Ganhar músculo') {
      tips.add(
        const _Tip(
          title: 'Proteína e consistência',
          desc: 'Inclui proteína em 2–3 refeições e mantém o treino regular.',
          icon: Icons.fitness_center,
        ),
      );
    }

    if (_goal == 'Perder peso') {
      tips.add(
        const _Tip(
          title: 'Passos contam',
          desc: 'Aumentar passos diários é uma das estratégias mais fáceis.',
          icon: Icons.directions_walk,
        ),
      );
    }

    return tips;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Desporto'),
        actions: [
          IconButton(
            tooltip: 'Reiniciar semana',
            icon: const Icon(Icons.restart_alt),
            onPressed: _resetWeek,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // BACKGROUND IMAGE
          Image.asset(
            'assets/sports_bg.png',
            fit: BoxFit.cover,
          ),

          // OVERLAY para legibilidade
          Container(
            color: Colors.black.withAlpha(64),
          ),

          // CONTEÚDO
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Section(
                  title: 'Preferências',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Escolhe nível e objetivo para ajustar o plano.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ChipChoice(
                            label: 'Iniciante',
                            selected: _level == 'Iniciante',
                            onTap: () => setState(() => _level = 'Iniciante'),
                          ),
                          _ChipChoice(
                            label: 'Intermédio',
                            selected: _level == 'Intermédio',
                            onTap: () => setState(() => _level = 'Intermédio'),
                          ),
                          _ChipChoice(
                            label: 'Avançado',
                            selected: _level == 'Avançado',
                            onTap: () => setState(() => _level = 'Avançado'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ChipChoice(
                            label: 'Ficar em forma',
                            selected: _goal == 'Ficar em forma',
                            onTap: () => setState(() => _goal = 'Ficar em forma'),
                          ),
                          _ChipChoice(
                            label: 'Ganhar músculo',
                            selected: _goal == 'Ganhar músculo',
                            onTap: () => setState(() => _goal = 'Ganhar músculo'),
                          ),
                          _ChipChoice(
                            label: 'Perder peso',
                            selected: _goal == 'Perder peso',
                            onTap: () => setState(() => _goal = 'Perder peso'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                _Section(
                  title: 'Progresso da semana',
                  child: Column(
                    children: [
                      _ProgressRow(
                        label: 'Sessões',
                        valueText: '$_sessionsThisWeek / $_targetSessions',
                        progress: _progressSessions,
                      ),
                      const SizedBox(height: 10),
                      _ProgressRow(
                        label: 'Minutos',
                        valueText: '$_minutesThisWeek / $_targetMinutes',
                        progress: _progressMinutes,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _addSession(minutes: 25),
                              icon: const Icon(Icons.add),
                              label: const Text('Adicionar treino (25 min)'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                _Section(
                  title: 'Plano semanal',
                  child: Column(
                    children: [
                      for (final day in _plan)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer.withAlpha(230),
                            child: Text(
                              day.short,
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          title: Text(
                            day.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(day.duration),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                _Section(
                  title: 'Desafios para jovens',
                  child: Column(
                    children: [
                      for (final c in _challenges)
                        Card(
                          elevation: 0,
                          color: Colors.white.withAlpha(230),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant.withAlpha(153),
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(c.icon),
                            title: Text(
                              c.title,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(c.desc),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                _Section(
                  title: 'Dicas rápidas',
                  child: Column(
                    children: [
                      for (final t in _tips)
                        ListTile(
                          leading: Icon(t.icon),
                          title: Text(
                            t.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(t.desc),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.white.withAlpha(235),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChipChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChipChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final String valueText;
  final double progress;

  const _ProgressRow({
    required this.label,
    required this.valueText,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(valueText, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _WorkoutDay {
  final String short;
  final String title;
  final String duration;

  _WorkoutDay(this.short, this.title, this.duration);
}

class _Challenge {
  final String title;
  final String desc;
  final IconData icon;

  const _Challenge({
    required this.title,
    required this.desc,
    required this.icon,
  });
}

class _Tip {
  final String title;
  final String desc;
  final IconData icon;

  const _Tip({
    required this.title,
    required this.desc,
    required this.icon,
  });
}

