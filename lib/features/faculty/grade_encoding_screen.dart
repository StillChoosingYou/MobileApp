import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/shared_widgets.dart';
import '../../models/academic_models.dart';
import '../../models/app_user.dart';
import '../../providers/feature_providers.dart';
import '../../providers/repository_providers.dart';

class GradeEncodingScreen extends ConsumerStatefulWidget {
  const GradeEncodingScreen({super.key});

  @override
  ConsumerState<GradeEncodingScreen> createState() => _GradeEncodingScreenState();
}

class _GradeEncodingScreenState extends ConsumerState<GradeEncodingScreen> {
  Section? _selectedSection;
  AppUser? _selectedStudent;
  final _gradeController = TextEditingController();
  String? _feedback;
  bool _feedbackIsError = false;
  bool _submitting = false;

  @override
  void dispose() {
    _gradeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedSection == null || _selectedStudent == null) return;
    final grade = double.tryParse(_gradeController.text.trim());
    if (grade == null) {
      setState(() {
        _feedback = 'Enter a numeric grade.';
        _feedbackIsError = true;
      });
      return;
    }

    setState(() => _submitting = true);
    final result = await ref.read(facultyRepositoryProvider).encodeGrade(
          studentId: _selectedStudent!.id,
          sectionId: _selectedSection!.id,
          numericGrade: grade,
        );
    if (!context.mounted) return;
    setState(() {
      _submitting = false;
      _feedbackIsError = !result.isOk;
      _feedback = result.when(
        ok: (_) => 'Grade recorded for ${_selectedStudent!.name}.',
        error: (message) => message,
      );
      if (result.isOk) _gradeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final faculty = ref.watch(authControllerProvider).valueOrNull;
    if (faculty == null) return const LoadingView();
    final sections = ref.watch(facultySectionsProvider(faculty.name));
    final scheme = Theme.of(context).colorScheme;

    return FormWidthLimiter(
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Encode Grades', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          sections.when(
            data: (list) => DropdownButtonFormField<Section>(
              initialValue: _selectedSection,
              decoration: const InputDecoration(labelText: 'Section'),
              items: list
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('${s.subjectCode} — ${s.sectionLabel}'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedSection = v;
                _selectedStudent = null;
              }),
            ),
            loading: () => const LoadingView(),
            error: (_, __) => const ErrorView(message: 'Could not load your sections.'),
          ),
          if (_selectedSection != null) ...[
            const SizedBox(height: 14),
            Consumer(
              builder: (context, ref, _) {
                final roster = ref.watch(sectionRosterProvider(_selectedSection!.id));
                return roster.when(
                  data: (students) => DropdownButtonFormField<AppUser>(
                    initialValue: _selectedStudent,
                    decoration: const InputDecoration(labelText: 'Student'),
                    items: students
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedStudent = v),
                  ),
                  loading: () => const LoadingView(),
                  error: (_, __) => const ErrorView(message: 'Could not load the roster.'),
                );
              },
            ),
          ],
          if (_selectedStudent != null) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _gradeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Grade (1.00 highest – 5.00 failing)',
                prefixIcon: Icon(Icons.grade_outlined),
              ),
            ),
            if (_feedback != null) ...[
              const SizedBox(height: 8),
              Text(_feedback!, style: TextStyle(color: _feedbackIsError ? scheme.error : Colors.green)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Grade'),
            ),
          ],
        ],
      ),
      ),
    );
  }
}
