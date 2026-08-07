import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_utils.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../providers/feature_providers.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(analyticsSummaryProvider);
    final trend = ref.watch(enrollmentTrendProvider);
    final auditLog = ref.watch(auditLogProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(analyticsSummaryProvider);
        ref.invalidate(enrollmentTrendProvider);
        ref.invalidate(auditLogProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Analytics Dashboard', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          summary.when(
            data: (s) => GridView.count(
              crossAxisCount: Responsive.gridCrossAxisCount(context),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: Responsive.isCompactHeight(context) ? 1.65 : 1.5,
              children: [
                FadeSlideIn(
                  index: 0,
                  child: StatCard(
                    icon: Icons.school_outlined,
                    label: 'Total Students',
                    value: '${s['totalStudents']}',
                  ),
                ),
                FadeSlideIn(
                  index: 1,
                  child: StatCard(
                    icon: Icons.co_present_outlined,
                    label: 'Total Faculty',
                    value: '${s['totalFaculty']}',
                  ),
                ),
                FadeSlideIn(
                  index: 2,
                  child: StatCard(
                    icon: Icons.pending_actions_outlined,
                    label: 'Pending Enrollments',
                    value: '${s['pendingEnrollments']}',
                  ),
                ),
                FadeSlideIn(
                  index: 3,
                  child: StatCard(
                    icon: Icons.payments_outlined,
                    label: "Today's Collections",
                    value: '₱${(s['todaysCollections'] as num).toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),
            loading: () => const LoadingView(),
            error: (_, __) => const ErrorView(message: 'Could not load analytics.'),
          ),
          const SizedBox(height: 24),
          Text('Enrollment Trend', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          trend.when(
            data: (data) => _EnrollmentTrendBars(data: data),
            loading: () => const LoadingView(),
            error: (_, __) => const ErrorView(message: 'Could not load the enrollment trend.'),
          ),
          const SizedBox(height: 24),
          Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          auditLog.when(
            data: (list) => Column(
              children: list
                  .take(8)
                  .map(
                    (log) => Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.history_outlined),
                        title: Text('${log.actor} — ${log.action}'),
                        subtitle: Text('${log.target} • ${AppDateUtils.relative(log.timestamp)}'),
                      ),
                    ),
                  )
                  .toList(),
            ),
            loading: () => const LoadingView(),
            error: (_, __) => const ErrorView(message: 'Could not load the audit log.'),
          ),
        ],
      ),
    );
  }
}

/// A deliberately simple, dependency-free bar chart — swap for `fl_chart`
/// (already in pubspec.yaml) if you want animation, tooltips, or axis
/// labels beyond what's needed here.
class _EnrollmentTrendBars extends StatelessWidget {
  const _EnrollmentTrendBars({required this.data});
  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxValue = data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: SizedBox(
        height: 160,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.entries.map((entry) {
            final heightFraction = maxValue == 0 ? 0.0 : entry.value / maxValue;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${entry.value}', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Container(
                      height: 100 * heightFraction,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(entry.key, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
