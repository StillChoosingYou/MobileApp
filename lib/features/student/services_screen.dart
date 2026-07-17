import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_utils.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/campus_models.dart';
import '../../providers/feature_providers.dart';
import '../../providers/repository_providers.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user == null) return const LoadingView();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Student Services'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Documents'),
              Tab(text: 'Clearance'),
              Tab(text: 'Queue'),
              Tab(text: 'Appointments'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DocumentsTab(studentId: user.id),
            _ClearanceTab(studentId: user.id),
            _QueueTab(studentId: user.id, studentName: user.name),
            _AppointmentsTab(studentId: user.id),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Documents
// ---------------------------------------------------------------------------

class _DocumentsTab extends ConsumerWidget {
  const _DocumentsTab({required this.studentId});
  final String studentId;

  Future<void> _openNewRequest(BuildContext context, WidgetRef ref) async {
    DocumentType selected = DocumentType.certificateOfEnrollment;
    final purposeController = TextEditingController();

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Request a document', style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<DocumentType>(
                initialValue: selected,
                decoration: const InputDecoration(labelText: 'Document type'),
                items: DocumentType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                    .toList(),
                onChanged: (v) => setSheetState(() => selected = v ?? selected),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: purposeController,
                decoration: const InputDecoration(labelText: 'Purpose'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(true),
                child: const Text('Submit request'),
              ),
            ],
          ),
        ),
      ),
    );

    if (submitted == true) {
      await ref
          .read(campusServicesRepositoryProvider)
          .submitDocumentRequest(studentId, selected, purposeController.text.trim());
      ref.invalidate(documentRequestsProvider(studentId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(documentRequestsProvider(studentId));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewRequest(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New request'),
      ),
      body: requests.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.description_outlined,
              title: 'No document requests yet',
              message: 'Request your TOR, COE, Good Moral, or diploma copy here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final r = list[i];
              return Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(r.type.label),
                  subtitle: Text('${r.purpose} • ${AppDateUtils.date(r.requestedAt)}'),
                  trailing: StatusPill(label: r.status.label, color: _statusColor(r.status)),
                ),
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (_, __) => const ErrorView(message: 'Could not load your document requests.'),
      ),
    );
  }

  Color _statusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.submitted:
        return Colors.blueGrey;
      case RequestStatus.processing:
        return Colors.orange;
      case RequestStatus.ready:
        return Colors.green;
      case RequestStatus.released:
        return Colors.teal;
    }
  }
}

// ---------------------------------------------------------------------------
// Clearance
// ---------------------------------------------------------------------------

class _ClearanceTab extends ConsumerWidget {
  const _ClearanceTab({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clearance = ref.watch(clearanceProvider(studentId));
    return clearance.when(
      data: (c) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          LinearProgressIndicator(
            value: c.steps.isEmpty ? 0 : c.clearedCount / c.steps.length,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 8),
          Text(
            c.isComplete
                ? 'All offices cleared for ${c.term}'
                : '${c.clearedCount} of ${c.steps.length} offices cleared',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ...c.steps.map(
            (step) => Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  step.cleared ? Icons.check_circle : Icons.hourglass_empty,
                  color: step.cleared ? Colors.green : Colors.orange,
                ),
                title: Text(step.office),
                subtitle: step.clearedBy != null ? Text('Cleared by ${step.clearedBy}') : null,
              ),
            ),
          ),
        ],
      ),
      loading: () => const LoadingView(),
      error: (_, __) => const ErrorView(message: 'Could not load your clearance status.'),
    );
  }
}

// ---------------------------------------------------------------------------
// Queue
// ---------------------------------------------------------------------------

class _QueueTab extends ConsumerStatefulWidget {
  const _QueueTab({required this.studentId, required this.studentName});
  final String studentId;
  final String studentName;

  @override
  ConsumerState<_QueueTab> createState() => _QueueTabState();
}

class _QueueTabState extends ConsumerState<_QueueTab> {
  QueueTicket? _myTicket;
  bool _issuing = false;

  Future<void> _getNumber(QueueOffice office) async {
    setState(() => _issuing = true);
    final ticket = await ref
        .read(campusServicesRepositoryProvider)
        .issueQueueTicket(widget.studentId, widget.studentName, office);
    if (!mounted) return;
    setState(() {
      _myTicket = ticket;
      _issuing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_myTicket != null) _MyTicketCard(ticket: _myTicket!),
        if (_myTicket != null) const SizedBox(height: 20),
        Text('Get a queue number', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Reserve your place at an office without waiting in line physically.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: QueueOffice.values
              .map(
                (o) => OutlinedButton.icon(
                  onPressed: _issuing ? null : () => _getNumber(o),
                  icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                  label: Text(o.label),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _MyTicketCard extends ConsumerWidget {
  const _MyTicketCard({required this.ticket});
  final QueueTicket ticket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(queueStreamProvider(ticket.office));
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: scheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your number — ${ticket.office.label}', style: TextStyle(color: scheme.onPrimaryContainer)),
            const SizedBox(height: 6),
            Text(
              ticket.displayNumber,
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            queue.when(
              data: (tickets) {
                final waitingAhead = tickets
                    .where((t) => t.status == QueueStatus.waiting && t.number < ticket.number)
                    .length;
                final nowServing = tickets.where((t) => t.status == QueueStatus.called).toList()
                  ..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
                return Text(
                  nowServing.isEmpty
                      ? '$waitingAhead ahead of you • no one called yet'
                      : 'Now serving ${nowServing.first.displayNumber} • $waitingAhead ahead of you',
                  style: TextStyle(color: scheme.onPrimaryContainer),
                );
              },
              loading: () => Text('Checking queue…', style: TextStyle(color: scheme.onPrimaryContainer)),
              error: (_, __) => Text('Live queue unavailable', style: TextStyle(color: scheme.onPrimaryContainer)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Appointments
// ---------------------------------------------------------------------------

class _AppointmentsTab extends ConsumerWidget {
  const _AppointmentsTab({required this.studentId});
  final String studentId;

  Future<void> _bookAppointment(BuildContext context, WidgetRef ref) async {
    AppointmentOffice office = AppointmentOffice.registrar;
    final purposeController = TextEditingController();
    DateTime? when;

    final booked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Book an appointment', style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<AppointmentOffice>(
                initialValue: office,
                decoration: const InputDecoration(labelText: 'Office'),
                items: AppointmentOffice.values
                    .map((o) => DropdownMenuItem(value: o, child: Text(o.label)))
                    .toList(),
                onChanged: (v) => setSheetState(() => office = v ?? office),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: purposeController,
                decoration: const InputDecoration(labelText: 'Purpose'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(when == null ? 'Pick date & time' : AppDateUtils.dateTime(when!)),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: sheetContext,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (date == null) return;
                  if (!sheetContext.mounted) return;
                  final time = await showTimePicker(
                    context: sheetContext,
                    initialTime: const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (time == null) return;
                  setSheetState(() {
                    when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  });
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: when == null
                    ? null
                    : () => Navigator.of(sheetContext).pop(true),
                child: const Text('Book appointment'),
              ),
            ],
          ),
        ),
      ),
    );

    if (booked == true && when != null) {
      await ref
          .read(campusServicesRepositoryProvider)
          .bookAppointment(studentId, office, purposeController.text.trim(), when!);
      ref.invalidate(appointmentsProvider(studentId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(appointmentsProvider(studentId));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bookAppointment(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Book'),
      ),
      body: appointments.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.event_available_outlined,
              title: 'No appointments booked',
              message: 'Book time with the Registrar, Accounting, Guidance, or Dean.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final a = list[i];
              return Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text('${a.office.label} — ${a.purpose}'),
                  subtitle: Text(AppDateUtils.dateTime(a.requestedFor)),
                  trailing: StatusPill(label: a.status.name, color: Colors.blueGrey),
                ),
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (_, __) => const ErrorView(message: 'Could not load your appointments.'),
      ),
    );
  }
}
