import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/utils/date_utils.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/financial_models.dart';
import '../../providers/feature_providers.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.payment});
  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Digital Receipt')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 12),
                Text('Payment Recorded', style: Theme.of(context).textTheme.titleLarge),
                Text(payment.receiptNumber, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                Text(
                  '₱${payment.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Divider(),
                _ReceiptLine(label: 'Student', value: payment.studentName),
                _ReceiptLine(label: 'Method', value: payment.method.label),
                _ReceiptLine(label: 'Recorded by', value: payment.recordedBy),
                _ReceiptLine(label: 'Date', value: AppDateUtils.dateTime(payment.timestamp)),
                const SizedBox(height: 16),
                QrImageView(
                  data: 'PGPC-OR|${payment.receiptNumber}|${payment.amount}',
                  size: 140,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Wire this to a real printer via a receipt-printing plugin.')),
                  ),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print physical receipt'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionHistoryProvider);
    final dailyTotal = ref.watch(dailyCollectionTotalProvider);
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(transactionHistoryProvider);
        ref.invalidate(dailyCollectionTotalProvider);
      },
      child: ListView(
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
                  Icon(Icons.today_outlined, color: scheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Text("Today's Collection: ", style: TextStyle(color: scheme.onPrimaryContainer)),
                  dailyTotal.when(
                    data: (t) => Text(
                      '₱${t.toStringAsFixed(2)}',
                      style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    loading: () => const Text('…'),
                    error: (_, __) => const Text('—'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Transaction History', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          transactions.when(
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No transactions yet',
                  message: 'Payments you collect will appear here.',
                );
              }
              return Column(children: list.map((p) => _TransactionTile(payment: p)).toList());
            },
            loading: () => const LoadingView(),
            error: (_, __) => const ErrorView(message: 'Could not load transaction history.'),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.payment});
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
          child: Icon(Icons.receipt_outlined, color: scheme.onSecondaryContainer, size: 20),
        ),
        title: Text('${payment.studentName} • ₱${payment.amount.toStringAsFixed(2)}'),
        subtitle: Text('${payment.receiptNumber} • ${payment.method.label} • ${AppDateUtils.dateTime(payment.timestamp)}'),
        trailing: StatusPill(
          label: payment.status.name,
          color: payment.status == PaymentStatus.verified ? Colors.green : Colors.orange,
        ),
      ),
    );
  }
}
