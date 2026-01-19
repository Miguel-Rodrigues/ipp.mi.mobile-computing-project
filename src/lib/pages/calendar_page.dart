import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final ValueNotifier<List<String>> _selectedEvents;

  CalendarFormat _format = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // Eventos de exemplo (podes depois trocar por Firebase/DB)
  late final LinkedHashMap<DateTime, List<String>> _events;

  @override
  void initState() {
    super.initState();

    _events = LinkedHashMap<DateTime, List<String>>(
      equals: isSameDay,
      hashCode: _getHashCode,
    )..addAll({
      DateTime.now(): ['Treino às 18:00', 'Beber água'],
      DateTime.now().add(const Duration(days: 2)): ['Consulta às 10:30'],
      DateTime.now().add(const Duration(days: 5)): ['Jogo / Desporto 20:00'],
    });

    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  int _getHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
  }

  List<String> _getEventsForDay(DateTime day) {
    return _events[day] ?? const [];
  }

  void _addQuickEvent() {
    // Exemplo simples: adiciona um evento “rápido” ao dia selecionado
    final dayKey = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);

    final list = List<String>.from(_events[dayKey] ?? const []);
    list.add('Novo evento (${TimeOfDay.now().format(context)})');

    setState(() {
      _events[dayKey] = list;
      _selectedEvents.value = _getEventsForDay(_selectedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário'),
        actions: [
          IconButton(
            tooltip: 'Adicionar evento (exemplo)',
            icon: const Icon(Icons.add),
            onPressed: _addQuickEvent,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 1,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TableCalendar<String>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,

                  calendarFormat: _format,
                  availableGestures: AvailableGestures.all,

                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

                  eventLoader: _getEventsForDay, // marca dias com eventos :contentReference[oaicite:2]{index=2}

                  onDaySelected: (selectedDay, focusedDay) {
                    if (!isSameDay(_selectedDay, selectedDay)) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      _selectedEvents.value = _getEventsForDay(selectedDay);
                    }
                  },

                  onFormatChanged: (format) {
                    if (_format != format) {
                      setState(() => _format = format);
                    }
                  },

                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },

                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: true,
                    formatButtonShowsNext: false,
                    formatButtonDecoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    formatButtonTextStyle: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    titleTextStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    leftChevronIcon: const Icon(Icons.chevron_left),
                    rightChevronIcon: const Icon(Icons.chevron_right),
                  ),

                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(fontWeight: FontWeight.w700),
                    weekendStyle: TextStyle(fontWeight: FontWeight.w700),
                  ),

                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    isTodayHighlighted: true,

                    selectedDecoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),

                    todayDecoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),

                    markerDecoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                  ),

                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return null;

                      // Dots “bonitos” alinhados
                      return Positioned(
                        bottom: 6,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            events.length > 3 ? 3 : events.length,
                                (_) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Eventos do dia',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ValueListenableBuilder<List<String>>(
                valueListenable: _selectedEvents,
                builder: (context, value, _) {
                  if (value.isEmpty) {
                    return const Center(
                      child: Text(
                        'Sem eventos neste dia.\nCarrega no + para adicionar um exemplo.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: value.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final text = value[index];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant.withOpacity(0.6),
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(Icons.event, color: theme.colorScheme.primary),
                          title: Text(
                            text,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
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
