import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/role_nav_shell.dart';
import '../../features/onboarding/coach_mark_overlay.dart';
import '../../features/onboarding/role_tutorial_steps.dart';
import '../../features/onboarding/tutorial_providers.dart';
import '../../models/app_user.dart';
import '../../providers/feature_providers.dart';
import 'payment_entry_screen.dart';
import 'receipt_transaction_screens.dart';

class CashierShell extends ConsumerStatefulWidget {
  const CashierShell({super.key});

  @override
  ConsumerState<CashierShell> createState() => _CashierShellState();
}

class _CashierShellState extends ConsumerState<CashierShell> {
  int _index = 0;
  bool _tutorialStarted = false;

  @override
  void initState() {
    super.initState();
    _checkAndStartTutorial();
  }

  Future<void> _checkAndStartTutorial() async {
    final authState = ref.read(authControllerProvider);
    final user = authState.value;
    if (user == null) return;

    final completed = await ref.read(roleTutorialCompletedProvider(
      (userId: user.id, role: user.role),
    ).future);

    if (!completed && mounted && !_tutorialStarted) {
      _tutorialStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startTutorial();
        }
      });
    }
  }

  void _startTutorial() {
    final steps = RoleTutorialSteps.getStepsForRole(UserRole.cashier);
    CoachMarkOverlay.show(
      context: context,
      steps: steps,
      onComplete: () async {
        final authState = ref.read(authControllerProvider);
        final user = authState.value;
        if (user != null) {
          await ref.read(markRoleTutorialCompletedProvider)(
            user.id,
            user.role,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      NavTab(
        icon: Icons.point_of_sale_outlined,
        label: 'Collect',
        screen: CoachMarkTarget(key: RoleTutorialKeys.cashierPaymentEntryKey, child: const PaymentEntryScreen()),
        coachMarkKey: RoleTutorialKeys.cashierPaymentEntryKey,
      ),
      NavTab(
        icon: Icons.receipt_long_outlined,
        label: 'Receipts',
        screen: CoachMarkTarget(key: RoleTutorialKeys.cashierReceiptsTabKey, child: const TransactionHistoryScreen()),
        coachMarkKey: RoleTutorialKeys.cashierReceiptsTabKey,
      ),
      NavTab(
        icon: Icons.summarize_outlined,
        label: 'Summary',
        screen: CoachMarkTarget(key: RoleTutorialKeys.cashierSummaryTabKey, child: const TransactionHistoryScreen()),
        coachMarkKey: RoleTutorialKeys.cashierSummaryTabKey,
      ),
    ];

    return RoleNavShell(
      title: 'Cashier',
      currentIndex: _index,
      onTabSelected: (i) => setState(() => _index = i),
      tabs: tabs,
    );
  }
}