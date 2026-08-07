import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/role_nav_shell.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/utils/date_utils.dart';
import '../../models/app_user.dart';
import '../../models/campus_models.dart';
import '../../models/financial_models.dart';
import '../../providers/feature_providers.dart';

class _MenuEntry {
  const _MenuEntry({required this.icon, required this.label, this.builder});
  final IconData icon;
  final String label;
  final WidgetBuilder? builder;
}

/// Accounting, Guidance, Department Head, and Dean share this dashboard
/// shell rather than each getting a bespoke bottom-nav Shell — their
/// feature lists are shorter and don't (yet) need dedicated tabs. One real
/// screen is wired per role below; the rest are placeholders that show how
/// to extend `CampusServicesRepository` / a new repository the same way.
class GenericRoleDashboard extends StatelessWidget {
  const GenericRoleDashboard({super.key, required this.role});
  final UserRole role;

  List<_MenuEntry> get _entries {
    switch (role) {
      case UserRole.accounting:
        return [
          _MenuEntry(
            icon: Icons.receipt_long_outlined,
            label: 'Billing & Ledger',
            builder: (_) => const AccountingBillingScreen(),
          ),
          const _MenuEntry(icon: Icons.card_giftcard_outlined, label: 'Scholarships & Discounts'),
          const _MenuEntry(icon: Icons.science_outlined, label: 'Laboratory Fees'),
          const _MenuEntry(icon: Icons.summarize_outlined, label: 'Financial Reports'),
          const _MenuEntry(icon: Icons.calendar_view_month_outlined, label: 'Installment Plans'),
        ];
      case UserRole.guidance:
        return [
          _MenuEntry(
            icon: Icons.event_available_outlined,
            label: 'Appointments',
            builder: (_) => const StaffAppointmentsScreen(office: AppointmentOffice.guidance),
          ),
          const _MenuEntry(icon: Icons.favorite_outline, label: 'Counseling Records'),
          const _MenuEntry(icon: Icons.fact_check_outlined, label: 'Clearance Sign-off'),
        ];
      case UserRole.deptHead:
        return [
          const _MenuEntry(icon: Icons.groups_2_outlined, label: 'Department Faculty'),
          const _MenuEntry(icon: Icons.bar_chart_outlined, label: 'Department Performance'),
          const _MenuEntry(icon: Icons.rule_folder_outlined, label: 'Curriculum Review'),
        ];
      case UserRole.dean:
        return [
          const _MenuEntry(icon: Icons.school_outlined, label: 'College Overview'),
          _MenuEntry(
            icon: Icons.event_available_outlined,
            label: 'Appointments',
            builder: (_) => const StaffAppointmentsScreen(office: AppointmentOffice.dean),
          ),
          const _MenuEntry(icon: Icons.verified_outlined, label: 'Graduation Evaluation'),
        ];
      default:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(role.label), actions: const [LogoutButton()]),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Responsive.gridCrossAxisCount(context),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: Responsive.gridChildAspectRatio(context),
        ),
        itemCount: _entries.length,
        itemBuilder: (context, i) {
          final entry = _entries[i];
          return Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (entry.builder != null) {
                  Navigator.of(context).push(MaterialPageRoute(builder: entry.builder!));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${entry.label} follows the same repository pattern — not wired up yet.')),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(entry.icon, color: scheme.primary),
                    Text(entry.label, style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A read-only oversight view over the same payments Cashier records —
/// Accounting doesn't collect money directly but reports on it.
class AccountingBillingScreen extends ConsumerWidget {
  const AccountingBillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionHistoryProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Billing & Ledger')),
      body: transactions.when(
        data: (list) {
          final total = list.fold<double>(0, (sum, p) => sum + p.amount);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                elevation: 0,
                color: scheme.primaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_outlined, color: scheme.onPrimaryContainer),
                      const SizedBox(width: 12),
                      Text(
                        'Total Collected: ₱${total.toStringAsFixed(2)}',
                        style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('All Recorded Payments', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              if (list.isEmpty)
                const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No payments yet',
                  message: 'Payments recorded by the Cashier will appear here for review.',
                )
              else
                ...list.map(
                  (p) => Card(
                    elevation: 0,
                    color: scheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: scheme.outlineVariant),
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text('${p.studentName} • ₱${p.amount.toStringAsFixed(2)}'),
                      subtitle: Text('${p.receiptNumber} • ${p.method.label} • ${AppDateUtils.date(p.timestamp)}'),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const LoadingView(),
        error: (_, __) => const ErrorView(message: 'Could not load payments.'),
      ),
    );
  }
}

/// Read-only appointment queue for a staff office (Guidance, Dean, ...).
/// Add a `updateAppointmentStatus` method to `CampusServicesRepository`
/// the same way other mutations are done here once you need staff to
/// confirm/complete appointments from this screen.
class StaffAppointmentsScreen extends ConsumerWidget {
  const StaffAppointmentsScreen({super.key, required this.office});
  final AppointmentOffice office;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(officeAppointmentsProvider(office));
    return Scaffold(
      appBar: AppBar(title: Text('${office.label} Appointments')),
      body: appointments.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.event_available_outlined,
              title: 'No appointments booked',
              message: 'Requests students book with your office will show up here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
                  title: Text(a.purpose),
                  subtitle: Text(AppDateUtils.dateTime(a.requestedFor)),
                  trailing: StatusPill(label: a.status.name, color: Colors.blueGrey),
                ),
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (_, __) => const ErrorView(message: 'Could not load appointments.'),
      ),
    );
  }
}
