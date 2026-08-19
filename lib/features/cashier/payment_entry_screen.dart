import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/validators.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/app_user.dart';
import '../../models/financial_models.dart';
import '../../providers/feature_providers.dart';
import '../../providers/repository_providers.dart';
import 'receipt_transaction_screens.dart';

class PaymentEntryScreen extends ConsumerStatefulWidget {
  const PaymentEntryScreen({super.key});

  @override
  ConsumerState<PaymentEntryScreen> createState() => _PaymentEntryScreenState();
}

class _PaymentEntryScreenState extends ConsumerState<PaymentEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _searchController = TextEditingController();
  AppUser? _selectedStudent;
  PaymentMethod _method = PaymentMethod.cash;
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a student first.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final cashier = ref.read(authControllerProvider).valueOrNull;
    final result = await ref.read(cashierRepositoryProvider).recordPayment(
          studentId: _selectedStudent!.id,
          studentName: _selectedStudent!.name,
          amount: double.parse(_amountController.text.trim()),
          method: _method,
          recordedBy: cashier?.name ?? 'Cashier',
        );

    if (!context.mounted) return;
    setState(() => _submitting = false);

    result.when(
      ok: (payment) {
        ref.invalidate(transactionHistoryProvider);
        ref.invalidate(dailyCollectionTotalProvider);
        ref.invalidate(studentLedgerProvider(_selectedStudent!.id));
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ReceiptScreen(payment: payment)),
        );
        setState(() {
          _selectedStudent = null;
          _searchController.clear();
          _amountController.clear();
        });
      },
      error: (message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))),
    );
  }

  void _showPaymentMethodHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => const HelpDialog(
        title: 'Payment methods explained',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HelpRow(
              icon: Icons.payments_outlined,
              text: 'Cash — Record a physical cash payment at the counter.',
            ),
            HelpRow(
              icon: Icons.credit_card_outlined,
              text: 'Card / Bank Transfer — Record a payment made via bank deposit, online banking, or card terminal. You enter the reference number manually.',
            ),
            HelpRow(
              icon: Icons.phone_android_outlined,
              text: 'GCash / Maya (manual) — Record that the student paid via the app. You verify the reference number against the cashier portal. The app does not yet integrate live checkout; see the README for PayMongo setup.',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(studentSearchProvider(_searchController.text));
    final scheme = Theme.of(context).colorScheme;

    return FormWidthLimiter(
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Collect a Payment', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            if (_selectedStudent == null) ...[
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search student by name or number',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              if (_searchController.text.isNotEmpty)
                searchResults.when(
                  data: (list) => Column(
                    children: list
                        .take(6)
                        .map(
                          (s) => ListTile(
                            leading: InitialsAvatar(name: s.name),
                            title: Text(s.name),
                            subtitle: Text(s.loginId),
                            onTap: () => setState(() => _selectedStudent = s),
                          ),
                        )
                        .toList(),
                  ),
                  loading: () => const LoadingView(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
            ] else ...[
              Card(
                elevation: 0,
                color: scheme.secondaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: InitialsAvatar(name: _selectedStudent!.name),
                  title: Text(_selectedStudent!.name),
                  subtitle: Text(_selectedStudent!.loginId),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedStudent = null),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount (₱)', prefixIcon: Icon(Icons.payments_outlined)),
                validator: Validators.amount,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text('Payment method', style: Theme.of(context).textTheme.labelLarge),
                  const Spacer(),
                  HelpIconButton(
                    onPressed: () => _showPaymentMethodHelp(context),
                    tooltip: 'Payment method help',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PaymentMethod.values
                    .map(
                      (m) => ChoiceChip(
                        label: Text(m.label),
                        selected: _method == m,
                        onSelected: (_) => setState(() => _method = m),
                      ),
                    )
                    .toList(),
              ),
              if (_method == PaymentMethod.gcash || _method == PaymentMethod.maya) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Recording a manual ${_method.label} payment. For live in-app GCash/Maya '
                          'checkout instead of manual entry, wire up PayMongo — see the README.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Record Payment'),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}
