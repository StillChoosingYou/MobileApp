import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/date_utils.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/campus_models.dart';
import '../../providers/feature_providers.dart';
import '../../providers/repository_providers.dart';

// ---------------------------------------------------------------------------
// Emergency
// ---------------------------------------------------------------------------

class _EmergencyContact {
  const _EmergencyContact({
    required this.label,
    required this.number,
    required this.icon,
    this.isPlaceholder = false,
  });
  final String label;
  final String number;
  final IconData icon;

  /// True for campus-specific lines this scaffold can't know — PGPC needs
  /// to fill in its real security/clinic/guidance extensions.
  final bool isPlaceholder;
}

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  // The two real hotlines below are the Philippines' actual nationwide
  // numbers (911 for police/fire/medical, 117 as the PNP's direct line) —
  // verified, not placeholders. The three campus-specific lines need PGPC's
  // real extensions filled in before this ships; a wrong number in an
  // emergency screen is worse than no number, so they're clearly flagged.
  static const _contacts = [
    _EmergencyContact(
      label: 'Campus Security',
      number: 'Add PGPC security\'s number',
      icon: Icons.security_outlined,
      isPlaceholder: true,
    ),
    _EmergencyContact(
      label: 'Campus Clinic',
      number: 'Add PGPC clinic\'s number',
      icon: Icons.medical_services_outlined,
      isPlaceholder: true,
    ),
    _EmergencyContact(
      label: 'Guidance Office',
      number: 'Add PGPC guidance\'s number',
      icon: Icons.support_agent_outlined,
      isPlaceholder: true,
    ),
    _EmergencyContact(
      label: 'National Emergency Hotline',
      number: '911',
      icon: Icons.emergency_outlined,
    ),
    _EmergencyContact(
      label: 'PNP Direct Line',
      number: '117',
      icon: Icons.local_police_outlined,
    ),
  ];

  Future<void> _call(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start a call to $number on this device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _contacts.length,
        itemBuilder: (context, i) {
          final c = _contacts[i];
          return Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.errorContainer,
                child: Icon(c.icon, color: scheme.onErrorContainer),
              ),
              title: Text(c.label),
              subtitle: Text(c.number, style: c.isPlaceholder ? TextStyle(color: scheme.onSurfaceVariant, fontStyle: FontStyle.italic) : null),
              trailing: c.isPlaceholder
                  ? null
                  : FilledButton.icon(
                      onPressed: () => _call(context, c.number),
                      icon: const Icon(Icons.call, size: 16),
                      label: const Text('Call'),
                    ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Visitor Management
// ---------------------------------------------------------------------------

class VisitorPassScreen extends ConsumerStatefulWidget {
  const VisitorPassScreen({super.key});

  @override
  ConsumerState<VisitorPassScreen> createState() => _VisitorPassScreenState();
}

class _VisitorPassScreenState extends ConsumerState<VisitorPassScreen> {
  final _nameController = TextEditingController();
  final _purposeController = TextEditingController();
  final _hostController = TextEditingController();
  VisitorLog? _issuedPass;

  @override
  void dispose() {
    _nameController.dispose();
    _purposeController.dispose();
    _hostController.dispose();
    super.dispose();
  }

  Future<void> _checkIn() async {
    if (_nameController.text.trim().isEmpty || _hostController.text.trim().isEmpty) return;
    final result = await ref.read(campusServicesRepositoryProvider).checkInVisitor(
          _nameController.text.trim(),
          _purposeController.text.trim(),
          _hostController.text.trim(),
        );
    if (!context.mounted) return;
    result.when(
      ok: (log) {
        setState(() => _issuedPass = log);
        ref.invalidate(visitorLogsProvider);
        _nameController.clear();
        _purposeController.clear();
        _hostController.clear();
      },
      error: (message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(visitorLogsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Visitor Management')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_issuedPass != null) ...[
            Card(
              elevation: 0,
              color: scheme.primaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Visitor Pass Issued', style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: QrImageView(data: 'PGPC-VISITOR|${_issuedPass!.id}', size: 130),
                    ),
                    const SizedBox(height: 8),
                    Text(_issuedPass!.visitorName, style: TextStyle(color: scheme.onPrimaryContainer)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text('Check in a visitor', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Visitor name')),
          const SizedBox(height: 10),
          TextField(controller: _purposeController, decoration: const InputDecoration(labelText: 'Purpose of visit')),
          const SizedBox(height: 10),
          TextField(controller: _hostController, decoration: const InputDecoration(labelText: 'Person / office visiting')),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: _checkIn, icon: const Icon(Icons.login), label: const Text('Check in')),
          const SizedBox(height: 24),
          Text('On Campus Today', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          logs.when(
            data: (list) {
              final onCampus = list.where((v) => v.isOnCampus).toList();
              if (onCampus.isEmpty) {
                return const EmptyState(
                  icon: Icons.badge_outlined,
                  title: 'No visitors on campus',
                  message: 'Checked-in visitors will appear here until they check out.',
                );
              }
              return Column(
                children: onCampus
                    .map(
                      (v) => Card(
                        elevation: 0,
                        color: scheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: scheme.outlineVariant),
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(v.visitorName),
                          subtitle: Text('${v.purpose} • visiting ${v.hostName} • ${AppDateUtils.time(v.checkIn)}'),
                          trailing: OutlinedButton(
                            onPressed: () async {
                              await ref.read(campusServicesRepositoryProvider).checkOutVisitor(v.id);
                              ref.invalidate(visitorLogsProvider);
                            },
                            child: const Text('Check out'),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const LoadingView(),
            error: (_, __) => const ErrorView(message: 'Could not load visitor logs.'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lost & Found
// ---------------------------------------------------------------------------

class LostFoundScreen extends ConsumerWidget {
  const LostFoundScreen({super.key});

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    bool isFound = true;
    final itemController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    final reporterController = TextEditingController();

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
              Text('Report an item', style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Found it')),
                  ButtonSegment(value: false, label: Text('Lost it')),
                ],
                selected: {isFound},
                onSelectionChanged: (s) => setSheetState(() => isFound = s.first),
              ),
              const SizedBox(height: 12),
              TextField(controller: itemController, decoration: const InputDecoration(labelText: 'Item name')),
              const SizedBox(height: 10),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 10),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
              const SizedBox(height: 10),
              TextField(controller: reporterController, decoration: const InputDecoration(labelText: 'Your name')),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.of(sheetContext).pop(true), child: const Text('Submit report')),
            ],
          ),
        ),
      ),
    );

    if (submitted == true) {
      final item = LostFoundItem(
        id: 'lf_${DateTime.now().microsecondsSinceEpoch}',
        isFound: isFound,
        itemName: itemController.text.trim(),
        description: descController.text.trim(),
        location: locationController.text.trim(),
        reportedBy: reporterController.text.trim(),
        reportedAt: DateTime.now(),
      );
      await ref.read(campusServicesRepositoryProvider).reportLostFoundItem(item);
      ref.invalidate(lostFoundItemsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(lostFoundItemsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Lost & Found')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _report(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Report item'),
      ),
      body: items.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Nothing reported yet',
              message: 'Lost or found something on campus? Report it here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final item = list[i];
              return Card(
                elevation: 0,
                color: scheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: scheme.outlineVariant),
                ),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: StatusPill(
                    label: item.isFound ? 'Found' : 'Lost',
                    color: item.isFound ? Colors.green : Colors.orange,
                  ),
                  title: Text(item.itemName),
                  subtitle: Text('${item.location} • ${AppDateUtils.date(item.reportedAt)}'),
                  trailing: item.claimed
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : TextButton(
                          onPressed: () async {
                            await ref.read(campusServicesRepositoryProvider).markItemClaimed(item.id);
                            ref.invalidate(lostFoundItemsProvider);
                          },
                          child: const Text('Mark claimed'),
                        ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (_, __) => const ErrorView(message: 'Could not load lost & found items.'),
      ),
    );
  }
}
