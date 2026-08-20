import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/advanced_models.dart';
import '../../providers/feature_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  CalendarViewMode _viewMode = CalendarViewMode.month;
  final Set<CalendarCategory> _activeFilters = {CalendarCategory.academic, CalendarCategory.exam, CalendarCategory.holiday, CalendarCategory.activity, CalendarCategory.deadline};

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(calendarEventsProvider(
      (from: DateTime.now().subtract(const Duration(days: 365)), to: DateTime.now().add(const Duration(days: 365))),
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_agenda_outlined),
            tooltip: 'Agenda',
            onPressed: () => setState(() => _viewMode = CalendarViewMode.agenda),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_view_month_outlined),
            tooltip: 'Month',
            onPressed: () => setState(() => _viewMode = CalendarViewMode.month),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_view_week_outlined),
            tooltip: 'Week',
            onPressed: () => setState(() => _viewMode = CalendarViewMode.week),
          ),
        ],
      ),
      body: Column(
        children: [
          _CategoryFilterChips(
            activeFilters: _activeFilters,
            onToggle: (category) {
              setState(() {
                if (_activeFilters.contains(category)) {
                  _activeFilters.remove(category);
                } else {
                  _activeFilters.add(category);
                }
              });
            },
          ),
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (events) {
                final filteredEvents = events.where((e) => _activeFilters.contains(e.category)).toList();
                switch (_viewMode) {
                  case CalendarViewMode.month:
                    return _MonthView(
                      selectedDate: _selectedDate,
                      events: filteredEvents,
                      onDateSelected: (date) => setState(() => _selectedDate = date),
                    );
                  case CalendarViewMode.week:
                    return _WeekView(
                      selectedDate: _selectedDate,
                      events: filteredEvents,
                      onDateSelected: (date) => setState(() => _selectedDate = date),
                    );
                  case CalendarViewMode.agenda:
                    return _AgendaView(events: filteredEvents);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum CalendarViewMode { month, week, agenda }

class _CategoryFilterChips extends StatelessWidget {
  const _CategoryFilterChips({required this.activeFilters, required this.onToggle});

  final Set<CalendarCategory> activeFilters;
  final void Function(CalendarCategory) onToggle;

  @override
  Widget build(BuildContext context) {
    const categories = CalendarCategory.values;
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isActive = activeFilters.contains(category);
          return Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: FilterChip(
              label: Text(category.label),
              selected: isActive,
              onSelected: (_) => onToggle(category),
              avatar: Icon(category.icon, size: 16),
              backgroundColor: category.color.withValues(alpha: 0.1),
              selectedColor: category.color.withValues(alpha: 0.3),
              labelStyle: TextStyle(color: isActive ? category.color : Theme.of(context).colorScheme.onSurface),
            ),
          );
        },
      ),
    );
  }
}

class _MonthView extends StatelessWidget {
  const _MonthView({required this.selectedDate, required this.events, required this.onDateSelected});

  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final void Function(DateTime) onDateSelected;

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month);
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    final weeks = ((daysInMonth + startWeekday) / 7).ceil();

    return Column(
      children: [
        _MonthHeader(selectedDate: selectedDate),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: weeks * 7,
            itemBuilder: (context, index) {
              final dayOffset = index - startWeekday;
              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                return const SizedBox.shrink();
              }
              final day = DateTime(selectedDate.year, selectedDate.month, dayOffset + 1);
              final dayEvents = events.where((e) => _isSameDay(e.date, day)).toList();
              final isSelected = _isSameDay(selectedDate, day);
              final isToday = _isSameDay(DateTime.now(), day);

              return GestureDetector(
                onTap: () => onDateSelected(day),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : null,
                        ),
                      ),
                      if (dayEvents.isNotEmpty)
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: dayEvents.length > 3 ? 3 : dayEvents.length,
                            itemBuilder: (context, eventIndex) {
                              final event = dayEvents[eventIndex];
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: event.category.color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _DayEventsList(date: selectedDate, events: events.where((e) => _isSameDay(e.date, selectedDate)).toList()),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final monthFormat = DateFormat('MMMM yyyy');
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {},
          ),
          Text(
            monthFormat.format(selectedDate),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _WeekView extends StatelessWidget {
  const _WeekView({required this.selectedDate, required this.events, required this.onDateSelected});

  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final void Function(DateTime) onDateSelected;

  @override
  Widget build(BuildContext context) {
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return Column(
      children: [
        _WeekHeader(selectedDate: selectedDate),
        Expanded(
          child: Row(
            children: days.map((day) {
              final dayEvents = events.where((e) => _isSameDay(e.date, day)).toList();
              final isSelected = _isSameDay(selectedDate, day);
              final isToday = _isSameDay(DateTime.now(), day);

              return Expanded(
                child: GestureDetector(
                  onTap: () => onDateSelected(day),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            DateFormat('E\nd').format(day),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : null,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: dayEvents.length,
                            itemBuilder: (context, index) {
                              final event = dayEvents[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: event.category.color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  event.title,
                                  style: const TextStyle(fontSize: 10),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final weekFormat = DateFormat('MMM d');
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {},
          ),
          Text(
            '${weekFormat.format(startOfWeek)} - ${weekFormat.format(endOfWeek)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _AgendaView extends StatelessWidget {
  const _AgendaView({required this.events});

  final List<CalendarEvent> events;

  @override
  Widget build(BuildContext context) {
    final sortedEvents = List<CalendarEvent>.from(events)
      ..sort((a, b) => a.date.compareTo(b.date));

    if (sortedEvents.isEmpty) {
      return const Center(child: Text('No events'));
    }

    return ListView.builder(
      itemCount: sortedEvents.length,
      itemBuilder: (context, index) {
        final event = sortedEvents[index];
        return _EventCard(event: event);
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(event.category.icon, color: event.category.color),
        title: Text(event.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.description),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(event.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Chip(
          label: Text(event.category.label),
          backgroundColor: event.category.color.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

class _DayEventsList extends StatelessWidget {
  const _DayEventsList({required this.date, required this.events});

  final DateTime date;
  final List<CalendarEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return _EventCard(event: event);
        },
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
