import 'package:flutter/material.dart';

import '../../core/widgets/role_nav_shell.dart';
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
      tabs: const [
        NavTab(icon: Icons.point_of_sale_outlined, label: 'Collect', screen: PaymentEntryScreen()),
        NavTab(icon: Icons.receipt_long_outlined, label: 'Transactions', screen: TransactionHistoryScreen()),
      ],
    );
  }
}
