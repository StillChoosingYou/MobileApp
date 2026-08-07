import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_utils.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/financial_models.dart';
import '../../providers/feature_providers.dart';

class TuitionWalletScreen extends ConsumerWidget {
  const TuitionWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user == null) return const LoadingView();

    final ledgerAsync = ref.watch(studentLedgerProvider(user.id));
    final paymentsAsync = ref.watch(studentPaymentHistoryProvider(user.id));
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(studentLedgerProvider(user.id));
        ref.invalidate(studentPaymentHistoryProvider(user.id));
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
            ledgerAsync.when(
              data: (ledger) => _LedgerCard(ledger: ledger),
              loading: () => const LoadingView(),
              error: (_, __) => const ErrorView(message: 'Could not load your tuition ledger.'),
            ),
            const SizedBox(height: 24),
            Text('Payment History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            paymentsAsync.when(
              data: (payments) {
                if (payments.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No payments recorded yet',
                    message: 'Payments you make at the Cashier or online will appear here.',
                  );
                }
                return Column(
                  children: payments.map((p) => _PaymentTile(payment: p)).toList(),
                );
              },
              loading: () => const LoadingView(),
              error: (_, __) => const ErrorView(message: 'Could not load payment history.'),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pay online through GCash or Maya once your Cashier office activates the '
                      'payment gateway — see the README for setup.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}

class _LedgerCard extends StatelessWidget {
  const _LedgerCard({required this.ledger});
  final TuitionLedger ledger;

  @override
  Widget build(BuildContext context) {
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
            Text(
              ledger.isFullyPaid ? 'Fully settled' : 'Outstanding balance',
              style: TextStyle(color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 4),
            Text(
              '₱${ledger.balance.toStringAsFixed(2)}',
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 28),
            _LedgerLine(label: 'Tuition fee', amount: ledger.tuitionFee, scheme: scheme),
            _LedgerLine(label: 'Miscellaneous fees', amount: ledger.miscFees, scheme: scheme),
            _LedgerLine(label: 'Laboratory fees', amount: ledger.labFees, scheme: scheme),
            if (ledger.scholarshipDiscount > 0)
              _LedgerLine(
                label: 'Scholarship discount',
                amount: -ledger.scholarshipDiscount,
                scheme: scheme,
              ),
            _LedgerLine(label: 'Total paid', amount: -ledger.totalPaid, scheme: scheme),
          ],
        ),
      ),
    );
  }
}

class _LedgerLine extends StatelessWidget {
  const _LedgerLine({required this.label, required this.amount, required this.scheme});
  final String label;
  final double amount;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final isNegative = amount < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: scheme.onPrimaryContainer))),
          Text(
            '${isNegative ? '-' : ''}₱${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});
  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
          backgroundColor: scheme.secondaryContainer,
          child: Icon(Icons.payments_outlined, color: scheme.onSecondaryContainer, size: 20),
        ),
        title: Text('₱${payment.amount.toStringAsFixed(2)} • ${payment.method.label}'),
        subtitle: Text('${payment.receiptNumber} • ${AppDateUtils.date(payment.timestamp)}'),
        trailing: StatusPill(
          label: payment.status.name,
          color: payment.status == PaymentStatus.verified ? Colors.green : Colors.orange,
        ),
      ),
    );
  }
}
