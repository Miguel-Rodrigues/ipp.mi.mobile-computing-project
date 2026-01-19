import 'package:flutter/material.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  // Perfil simples
  int _age = 18;

  // Batimento cardíaco (BPM)
  final _bpmController = TextEditingController();
  final List<_BpmEntry> _bpmHistory = [
    _BpmEntry(bpm: 72, when: DateTime.now().subtract(const Duration(hours: 6))),
    _BpmEntry(bpm: 80, when: DateTime.now().subtract(const Duration(days: 1))),
  ];

  // Sono
  double _sleepHours = 7.5;
  String _sleepQuality = 'Boa'; // Fraca / Média / Boa

  @override
  void dispose() {
    _bpmController.dispose();
    super.dispose();
  }

  int get _maxHeartRate => 220 - _age;

  // Zona alvo simplificada (50%–85% HRmax)
  int get _targetLow => (_maxHeartRate * 0.50).round();
  int get _targetHigh => (_maxHeartRate * 0.85).round();

  void _addBpm() {
    final raw = _bpmController.text.trim();
    final bpm = int.tryParse(raw);
    if (bpm == null || bpm < 30 || bpm > 220) return;

    setState(() {
      _bpmHistory.insert(0, _BpmEntry(bpm: bpm, when: DateTime.now()));
    });

    _bpmController.clear();
  }

  String _sleepTip() {
    if (_sleepHours < 6) {
      return 'Poucas horas. Tenta antecipar o sono e reduzir ecrãs 30–60 min antes de dormir.';
    }
    if (_sleepHours < 7) {
      return 'Razoável, mas para a maioria das pessoas 7–9h é o ideal.';
    }
    if (_sleepHours <= 9) {
      return 'Boa duração. Mantém horário consistente (mesma hora para deitar/acordar).';
    }
    return 'Muito sono pode indicar cansaço acumulado. Observa como te sentes ao acordar.';
  }

  Color _bpmColor(int bpm) {
    if (bpm < 60) return Colors.blueGrey;
    if (bpm <= 100) return Colors.green;
    if (bpm <= 130) return Colors.orange;
    return Colors.red;
  }

  String _formatDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return "${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latestBpm = _bpmHistory.isNotEmpty ? _bpmHistory.first.bpm : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saúde'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // BACKGROUND IMAGE (muda para o teu asset)
          Image.asset(
            'assets/health_bg.png',
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
                  title: 'Perfil',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'A idade ajuda a calcular uma zona alvo de treino (estimativa).',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const SizedBox(
                            width: 90,
                            child: Text('Idade',
                                style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                          Expanded(
                            child: Slider(
                              value: _age.toDouble(),
                              min: 12,
                              max: 65,
                              divisions: 53,
                              label: '$_age',
                              onChanged: (v) => setState(() => _age = v.round()),
                            ),
                          ),
                          SizedBox(
                            width: 44,
                            child: Text('$_age', textAlign: TextAlign.end),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Zona alvo (estimativa): $_targetLow–$_targetHigh bpm (HRmax ~ $_maxHeartRate)',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                _Section(
                  title: 'Batimento cardíaco (BPM)',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (latestBpm != null)
                        Row(
                          children: [
                            const Text(
                              'Último:',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 10),
                            Chip(
                              label: Text(
                                '$latestBpm bpm',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: _bpmColor(latestBpm),
                            ),
                            const Spacer(),
                            Text(
                              latestBpm >= _targetLow && latestBpm <= _targetHigh
                                  ? 'Dentro da zona alvo'
                                  : 'Fora da zona alvo',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        )
                      else
                        const Text('Sem registos ainda.'),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _bpmController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Inserir BPM (ex: 78)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onSubmitted: (_) => _addBpm(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _addBpm,
                            icon: const Icon(Icons.add),
                            label: const Text('Adicionar'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'Histórico',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),

                      if (_bpmHistory.isEmpty)
                        const Text('Ainda não registaste BPM.')
                      else
                        Column(
                          children: [
                            for (final entry in _bpmHistory.take(6))
                              Card(
                                elevation: 0,
                                color: Colors.white.withAlpha(235),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: theme.colorScheme.outlineVariant
                                        .withAlpha(153),
                                  ),
                                ),
                                child: ListTile(
                                  leading: Icon(Icons.favorite,
                                      color: _bpmColor(entry.bpm)),
                                  title: Text(
                                    '${entry.bpm} bpm',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800),
                                  ),
                                  subtitle: Text(_formatDateTime(entry.when)),
                                ),
                              ),
                          ],
                        ),

                      const SizedBox(height: 8),
                      const Text(
                        'Nota: valores muito altos em repouso ou sintomas devem ser avaliados por um profissional.',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                _Section(
                  title: 'Sono',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Regista as horas e a qualidade para criares consistência.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const SizedBox(
                            width: 90,
                            child: Text('Horas',
                                style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                          Expanded(
                            child: Slider(
                              value: _sleepHours,
                              min: 3,
                              max: 12,
                              divisions: 18,
                              label: _sleepHours.toStringAsFixed(1),
                              onChanged: (v) => setState(() => _sleepHours = v),
                            ),
                          ),
                          SizedBox(
                            width: 52,
                            child: Text(
                              _sleepHours.toStringAsFixed(1),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        children: [
                          _ChoiceChip(
                            label: 'Fraca',
                            selected: _sleepQuality == 'Fraca',
                            onTap: () => setState(() => _sleepQuality = 'Fraca'),
                          ),
                          _ChoiceChip(
                            label: 'Média',
                            selected: _sleepQuality == 'Média',
                            onTap: () => setState(() => _sleepQuality = 'Média'),
                          ),
                          _ChoiceChip(
                            label: 'Boa',
                            selected: _sleepQuality == 'Boa',
                            onTap: () => setState(() => _sleepQuality = 'Boa'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Card(
                        elevation: 0,
                        color: theme.colorScheme.surfaceVariant.withAlpha(140),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          leading: const Icon(Icons.nightlight_round),
                          title: Text(
                            'Dica',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            '${_sleepTip()}\nQualidade registada: $_sleepQuality',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                _Section(
                  title: 'Mais opções úteis (para jovens)',
                  child: Column(
                    children: const [
                      _OptionTile(
                        icon: Icons.water_drop_outlined,
                        title: 'Hidratação',
                        desc: 'Registar copos de água / lembretes.',
                      ),
                      _OptionTile(
                        icon: Icons.sentiment_satisfied_alt,
                        title: 'Humor',
                        desc: 'Check-in diário (1–5) para perceber padrões.',
                      ),
                      _OptionTile(
                        icon: Icons.spa,
                        title: 'Stress / respiração',
                        desc: 'Exercícios de 1–3 minutos para acalmar.',
                      ),
                      _OptionTile(
                        icon: Icons.medication_outlined,
                        title: 'Medicação e lembretes',
                        desc: 'Rotina simples com alertas.',
                      ),
                      _OptionTile(
                        icon: Icons.local_hospital_outlined,
                        title: 'Consultas e vacinas',
                        desc: 'Calendário de saúde e histórico.',
                      ),
                      _OptionTile(
                        icon: Icons.directions_walk,
                        title: 'Passos / atividade diária',
                        desc: 'Metas de passos e streak semanal.',
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

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({
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

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(desc),
    );
  }
}

class _BpmEntry {
  final int bpm;
  final DateTime when;

  _BpmEntry({required this.bpm, required this.when});
}
