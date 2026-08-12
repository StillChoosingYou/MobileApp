import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/responsive.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/academic_models.dart';
import '../../providers/feature_providers.dart';
import '../../providers/repository_providers.dart';

class EnrollmentApprovalScreen extends ConsumerWidget {
  const EnrollmentApprovalScreen({super.key});

  Future<void> _reject(BuildContext context, WidgetRef ref, Enrollment e) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject enrollment'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, reasonController.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    await ref.read(registrarRepositoryProvider).rejectEnrollment(e.id, reason);
    ref.invalidate(pendingEnrollmentsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingEnrollmentsProvider);
    final students = ref.watch(studentSearchProvider(''));
    final sections = ref.watch(allSectionsProvider);

    return pending.when(
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.task_alt_outlined,
            title: 'No pending enrollments',
            message: 'New enrollment submissions will show up here for review.',
          );
        }
        return ListView.builder(
          padding: Responsive.scrollPadding(context),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final e = list[i];
            final matchingStudents =
                students.value?.where((s) => s.id == e.studentId).toList() ?? const [];
            final studentName = matchingStudents.isEmpty ? e.studentId : matchingStudents.first.name;
            final sectionLabels = sections.value
                    ?.where((s) => e.sectionIds.contains(s.id))
                    .map((s) => s.subjectCode)
                    .join(', ') ??
                '';

            return Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(studentName, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      sectionLabels.isEmpty ? e.term : '${e.term} • $sectionLabels',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _reject(context, ref, e),
                            child: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              await ref.read(registrarRepositoryProvider).approveEnrollment(e.id);
                              ref.invalidate(pendingEnrollmentsProvider);
                            },
                            child: const Text('Approve'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const LoadingView(),
      error: (_, __) => const ErrorView(message: 'Could not load pending enrollments.'),
    );
  }
}
