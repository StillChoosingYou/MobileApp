import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_utils.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/academic_models.dart';
import '../../models/attendance_models.dart';
import '../../providers/feature_providers.dart';
import '../../providers/repository_providers.dart';
import '../common/qr_scanner_screen.dart';

/// Student attendance hub: scan a faculty session QR to self-mark present,
/// and review a running history of past sessions.
class StudentAttendanceScreen extends ConsumerWidget {
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(authControllerProvider).valueOrNull;
    if (student == null) return const LoadingView();

    final history = ref.watch(studentAttendanceProvider(
      (studentId: student.id, sectionId: null, from: null, to: null),
    ));
    final sections = ref.watch(studentSectionsProvider(student.id));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: () => _scan(context, ref, student.id),
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan Attendance QR'),
        ),
        const SizedBox(height: 10),
        Text(
          'Open the camera, then point it at your instructor\'s session QR. '
          'The code refreshes every few seconds — scan it while it\'s on screen.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        if (sections is AsyncData<List<Section>> && sections.value.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Your classes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...sections.value.map(
            (s) => Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.class_outlined),
                title: Text('${s.subjectCode} — ${s.sectionLabel}'),
                subtitle: Text('${s.dayPattern} ${s.startTime}–${s.endTime} • ${s.room}'),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('Attendance history', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        history.when(
          data: (records) {
            if (records.isEmpty) {
              return const EmptyState(
                icon: Icons.how_to_reg_outlined,
                title: 'No records yet',
                message: 'Scanned sessions will appear here once you mark attendance.',
              );
            }
            return Column(
              children: records.map((r) => _HistoryTile(record: r)).toList(),
            );
          },
          loading: () => const LoadingView(),
          error: (_, __) => const ErrorView(message: 'Could not load your attendance.'),
        ),
      ],
    );
  }

  Future<void> _scan(BuildContext context, WidgetRef ref, String studentId) async {
    final value = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen(title: 'Scan Attendance QR')),
    );
    if (!context.mounted) return;
    if (value == null) return;

    if (!value.startsWith('PGPC_ATTENDANCE|')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That QR code is not an attendance session.')),
      );
      return;
    }

    final result = await ref
        .read(attendanceRepositoryProvider)
        .submitAttendance(studentId, value);
    if (!context.mounted) return;

    result.when(
      ok: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance marked — present! 🎉')),
      ),
      error: (msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      ),
    );

    // Refresh the history list.
    ref.invalidate(studentAttendanceProvider);
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record});
  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (record.status) {
      AttendanceStatus.present => Colors.green,
      AttendanceStatus.late => Colors.orange,
      AttendanceStatus.excused => Colors.blue,
      AttendanceStatus.absent => Colors.red,
    };
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(record.status.icon, style: const TextStyle(fontSize: 16)),
        ),
        title: Text(record.sectionId),
        subtitle: Text(AppDateUtils.dateTime(record.recordedAt)),
        trailing: StatusPill(label: record.status.label, color: color),
      ),
    );
  }
}
