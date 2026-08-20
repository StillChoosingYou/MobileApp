import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/shared_widgets.dart';
import '../../models/academic_models.dart';
import '../../providers/feature_providers.dart';

/// Faculty/Admin view: per-student attendance for a section, with at-risk
/// students floated to the top so intervention happens early.
class AttendanceAnalyticsScreen extends ConsumerWidget {
  const AttendanceAnalyticsScreen({required this.section, super.key});
  final Section section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(sectionAttendanceSummaryProvider(section.id));
    final atRisk = ref.watch(atRiskStudentsProvider(
      (sectionId: section.id, threshold: 0.75),
    ));

    return Scaffold(
      appBar: AppBar(title: Text('${section.subjectCode} — ${section.sectionLabel}')),
      body: Column(
        children: [
          atRisk.when(
            data: (list) => list.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${list.length} student${list.length == 1 ? '' : 's'} below 75% '
                            'attendance — flag for counseling or parent notice.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.red.shade800,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Expanded(
            child: summary.when(
              data: (rows) {
                if (rows.isEmpty) {
                  return const EmptyState(
                    icon: Icons.analytics_outlined,
                    title: 'No attendance yet',
                    message: 'Start a session and mark students to build the summary.',
                  );
                }
                final sorted = [...rows]
                  ..sort((a, b) => a.attendanceRate.compareTo(b.attendanceRate));
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: sorted.length,
                  itemBuilder: (context, i) {
                    final s = sorted[i];
                    final rate = s.attendanceRate;
                    final color = switch (s.statusLabel) {
                      'Excellent' => Colors.green,
                      'Good' => Colors.blue,
                      'At Risk' => Colors.orange,
                      _ => Colors.red,
                    };
                    return Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: InitialsAvatar(name: s.studentName),
                        title: Text(s.studentName),
                        subtitle: Text(
                          'Present ${s.presentCount} • Late ${s.lateCount} '
                          '• Excused ${s.excusedCount} • Absent ${s.absentCount}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${rate.toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            StatusPill(label: s.statusLabel, color: color),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const LoadingView(),
              error: (_, __) => const ErrorView(message: 'Could not load attendance summary.'),
            ),
          ),
        ],
      ),
    );
  }
}
