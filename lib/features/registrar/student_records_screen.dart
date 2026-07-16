import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/shared_widgets.dart';
import '../../providers/feature_providers.dart';
import 'student_detail_screen.dart';

class StudentRecordsScreen extends ConsumerStatefulWidget {
  const StudentRecordsScreen({super.key});

  @override
  ConsumerState<StudentRecordsScreen> createState() => _StudentRecordsScreenState();
}

class _StudentRecordsScreenState extends ConsumerState<StudentRecordsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(studentSearchProvider(_query));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search by name or student number',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: results.when(
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.person_search_outlined,
                  title: 'No matching students',
                  message: 'Try a different name or student number.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final s = list[i];
                  return Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: InitialsAvatar(name: s.name),
                      title: Text(s.name),
                      subtitle: Text(s.loginId),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => StudentDetailScreen(student: s)),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const LoadingView(),
            error: (_, __) => const ErrorView(message: 'Could not search students right now.'),
          ),
        ),
      ],
    );
  }
}
