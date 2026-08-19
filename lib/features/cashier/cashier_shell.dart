import 'package:flutter/material.dart';

import '../../core/widgets/role_nav_shell.dart';
import '../../features/onboarding/role_tutorial_steps.dart';
import 'payment_entry_screen.dart';
import 'receipt_transaction_screens.dart';

class CashierShell extends StatefulWidget {
  const CashierShell({super.key});

  @override
  State<CashierShell> createState() => _CashierShellState();
}

class _CashierShellState extends State<CashierShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return RoleNavShell(
      title: 'Cashier',
      currentIndex: _index,
      onTabSelected: (i) => setState(() => _index = i),
      tabs: [
        NavTab(
          icon: Icons.point_of_sale_outlined,
          label: 'Collect',
          screen: const PaymentEntryScreen(),
          coachMarkKey: RoleTutorialKeys.cashierPaymentEntryKey,
        ),
        NavTab(
          icon: Icons.receipt_long_outlined,
          label: 'Receipts',
          screen: const TransactionHistoryScreen(),
          coachMarkKey: RoleTutorialKeys.cashierReceiptsTabKey,
        ),
        NavTab(
          icon: Icons.summarize_outlined,
          label: 'Summary',
          screen: const TransactionHistoryScreen(),
          coachMarkKey: RoleTutorialKeys.cashierSummaryTabKey,
        ),
      ],
    );
  }
}