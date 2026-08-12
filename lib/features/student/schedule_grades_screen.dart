import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/gpa_calculator.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/academic_models.dart';
import '../../providers/feature_providers.dart';

class ScheduleGradesScreen extends ConsumerWidget {
  const ScheduleGradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user == null) return const LoadingView();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: const TabBar(tabs: [Tab(text: 'Schedule'), Tab(text: 'Grades')]),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ScheduleTab(studentId: user.id),
                _GradesTab(studentId: user.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTab extends ConsumerWidget {
  const _ScheduleTab({required this.studentId});
  final String studentId;

  static const _dayColors = {
    'M': Colors.indigo,
    'T': Colors.teal,
    'W': Colors.deepPurple,
    'h': Colors.teal,
    'F': Colors.orange,
    'S': Colors.brown,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(studentSectionsProvider(studentId));
    return sections.when(
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.event_busy_outlined,
            title: 'No enrolled subjects yet',
            message: 'Once your enrollment is approved, your class schedule will show up here.',
          );
        }
        final sorted = [...list]..sort((a, b) => a.startTime.compareTo(b.startTime));
        return ListView.builder(
          padding: Responsive.scrollPadding(context),
          itemCount: sorted.length,
          itemBuilder: (context, i) {
            final s = sorted[i];
            return Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  backgroundColor: (_dayColors[s.dayPattern[0]] ?? Colors.blueGrey).withValues(alpha: 0.15),
                  child: Text(
                    s.dayPattern,
                    style: TextStyle(fontSize: 11, color: _dayColors[s.dayPattern[0]] ?? Colors.blueGrey),
                  ),
                ),
                title: Text('${s.subjectCode} — ${s.sectionLabel}'),
                subtitle: Text('${s.startTime}–${s.endTime} • ${s.room} • ${s.facultyName}'),
              ),
            );
          },
        );
      },
      loading: () => const LoadingView(),
      error: (_, __) => const ErrorView(message: 'Could not load your schedule.'),
    );
  }
}

class _GradesTab extends ConsumerWidget {
  const _GradesTab({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grades = ref.watch(studentGradesProvider(studentId));
    return grades.when(
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.grade_outlined,
            title: 'No grades posted yet',
            message: 'Grades appear here once faculty encode them for the term.',
          );
        }
        final gpa = GpaCalculator.compute(list);
        return ListView(
          padding: Responsive.scrollPadding(context),
          children: [
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: EdgeInsets.all(Responsive.spacing(context, normal: 16, compact: 12)),
                child: Responsive.isCompactHeight(context) || Responsive.sizeOf(context).width < 360
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.grade, color: Theme.of(context).colorScheme.onPrimaryContainer),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Overall GPA: ${gpa?.toStringAsFixed(2) ?? '—'}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '1.00 highest • 5.00 failing',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Icon(Icons.grade, color: Theme.of(context).colorScheme.onPrimaryContainer),
                          const SizedBox(width: 12),
                          Text(
                            'Overall GPA: ${gpa?.toStringAsFixed(2) ?? '—'}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '1.00 highest • 5.00 failing',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            ...list.map((g) => _GradeRow(grade: g)),
          ],
        );
      },
      loading: () => const LoadingView(),
      error: (_, __) => const ErrorView(message: 'Could not load your grades.'),
    );
  }
}

class _GradeRow extends StatelessWidget {
  const _GradeRow({required this.grade});
  final Grade grade;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final passed = grade.isIncomplete ? null : (grade.numericGrade ?? 5) <= 3.0;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(grade.subjectTitle),
        subtitle: Text('${grade.subjectCode} • ${grade.units.toStringAsFixed(0)} units • ${grade.term}'),
        trailing: StatusPill(
          label: grade.display,
          color: passed == null ? Colors.orange : (passed ? Colors.green : scheme.error),
        ),
      ),
    );
  }
}
