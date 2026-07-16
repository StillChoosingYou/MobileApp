import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/gpa_calculator.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/app_user.dart';
import '../../providers/feature_providers.dart';

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({super.key, required this.student});
  final AppUser student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(studentProfileProvider(student.id));
    final grades = ref.watch(studentGradesProvider(student.id));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(student.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              InitialsAvatar(name: student.name, radius: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name, style: Theme.of(context).textTheme.titleLarge),
                    Text(student.loginId, style: Theme.of(context).textTheme.bodyMedium),
                    profile.when(
                      data: (p) => p == null
                          ? const SizedBox.shrink()
                          : Text(
                              '${p.program} • Year ${p.yearLevel} • ${p.blockSection}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (profile.value?.scholarshipLabel != null) ...[
            const SizedBox(height: 12),
            StatusPill(label: profile.value!.scholarshipLabel!, color: scheme.primary),
          ],
          const SizedBox(height: 24),
          Text('Academic Record', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          grades.when(
            data: (list) {
              final gpa = GpaCalculator.compute(list);
              return Column(
                children: [
                  Card(
                    elevation: 0,
                    color: scheme.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(Icons.grade, color: scheme.onPrimaryContainer),
                          const SizedBox(width: 10),
                          Text(
                            'GPA: ${gpa?.toStringAsFixed(2) ?? '—'}',
                            style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...list.map(
                    (g) => Card(
                      elevation: 0,
                      color: scheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(g.subjectTitle),
                        subtitle: Text('${g.subjectCode} • ${g.term}'),
                        trailing: Text(g.display, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const LoadingView(),
            error: (_, __) => const ErrorView(message: 'Could not load academic records.'),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generates a PDF COR — wire this to the pdf skill / a Cloud Function.')),
                ),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Issue COR'),
              ),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generates a Transcript of Records request.')),
                ),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Transcript Request'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
