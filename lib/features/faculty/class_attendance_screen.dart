import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/widgets/shared_widgets.dart';
import '../../models/academic_models.dart';
import '../../providers/feature_providers.dart';
import '../../providers/repository_providers.dart';
import '../common/qr_scanner_screen.dart';

class ClassAttendanceScreen extends ConsumerWidget {
  const ClassAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faculty = ref.watch(authControllerProvider).valueOrNull;
    if (faculty == null) return const LoadingView();
    final sections = ref.watch(facultySectionsProvider(faculty.name));

    return sections.when(
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.class_outlined,
            title: 'No classes assigned',
            message: 'Sections you teach this term will appear here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
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
                title: Text('${s.subjectCode} — ${s.sectionLabel}'),
                subtitle: Text('${s.dayPattern} ${s.startTime}–${s.endTime} • ${s.room}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AttendanceSessionScreen(section: s)),
                ),
              ),
            );
          },
        );
      },
      loading: () => const LoadingView(),
      error: (_, __) => const ErrorView(message: 'Could not load your classes.'),
    );
  }
}

class AttendanceSessionScreen extends ConsumerStatefulWidget {
  const AttendanceSessionScreen({super.key, required this.section});
  final Section section;

  @override
  ConsumerState<AttendanceSessionScreen> createState() => _AttendanceSessionScreenState();
}

class _AttendanceSessionScreenState extends ConsumerState<AttendanceSessionScreen> {
  final Map<String, AttendanceStatus> _statuses = {};
  bool _showQr = false;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final roster = ref.watch(sectionRosterProvider(widget.section.id));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.section.subjectCode} — ${widget.section.sectionLabel}')),
      body: roster.when(
        data: (students) {
          for (final s in students) {
            _statuses.putIfAbsent(s.id, () => AttendanceStatus.present);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final value = await Navigator.of(context).push<String>(
                    MaterialPageRoute(builder: (_) => const QrScannerScreen(title: 'Scan Student Digital ID')),
                  );
                  if (value == null || !mounted) return;
                  final parts = value.split('|');
                  if (parts.length < 3 || parts[0] != 'PGPC-ID') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('That QR code is not a PGPC Digital ID.')),
                    );
                    return;
                  }
                  final scannedStudentId = parts[2];
                  final match = students.where((s) => s.id == scannedStudentId);
                  if (match.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('That student is not on this section\'s roster.')),
                    );
                    return;
                  }
                  setState(() => _statuses[scannedStudentId] = AttendanceStatus.present);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${match.first.name} marked present.')),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan a student\'s Digital ID'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => setState(() => _showQr = !_showQr),
                icon: const Icon(Icons.qr_code_2),
                label: Text(_showQr ? 'Hide session QR' : 'Generate session QR for self-scan'),
              ),
              if (_showQr) ...[
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: QrImageView(
                      data: ref.read(facultyRepositoryProvider).generateSessionQrPayload(widget.section.id),
                      size: 160,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Students scan this with their Digital ID screen to self-mark present.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('Roster (${students.length})', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...students.map(
                (s) => Card(
                  elevation: 0,
                  color: scheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(child: ListTile(leading: InitialsAvatar(name: s.name), title: Text(s.name))),
                        DropdownButton<AttendanceStatus>(
                          value: _statuses[s.id],
                          underline: const SizedBox.shrink(),
                          items: AttendanceStatus.values
                              .map((st) => DropdownMenuItem(value: st, child: Text(st.name)))
                              .toList(),
                          onChanged: (v) => setState(() => _statuses[s.id] = v ?? AttendanceStatus.present),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _submitting
                    ? null
                    : () async {
                        setState(() => _submitting = true);
                        final records = students
                            .map((s) => AttendanceRecord(
                                  id: 'att_${s.id}_${DateTime.now().millisecondsSinceEpoch}',
                                  studentId: s.id,
                                  sectionId: widget.section.id,
                                  date: DateTime.now(),
                                  status: _statuses[s.id] ?? AttendanceStatus.present,
                                ))
                            .toList();
                        await ref.read(facultyRepositoryProvider).submitAttendance(records);
                        if (!mounted) return;
                        setState(() => _submitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Attendance submitted.')),
                        );
                      },
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit Attendance'),
              ),
            ],
          );
        },
        loading: () => const LoadingView(),
        error: (_, __) => const ErrorView(message: 'Could not load the class roster.'),
      ),
    );
  }
}
