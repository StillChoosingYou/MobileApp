import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_utils.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/app_user.dart';
import '../../models/campus_models.dart';
import '../../providers/feature_providers.dart';
import '../../providers/repository_providers.dart';

/// Student-facing history of in-app notifications (grades, payments,
/// announcements, etc.). Tapping an item marks it read; a FAB/mark-all
/// action clears the unread state in bulk.
class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user == null) return const LoadingView();

    final notifications = ref.watch(studentNotificationsProvider(user.id));
    final unread = notifications.valueOrNull?.where((n) => !n.read).length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton.icon(
              onPressed: () => _markAllRead(ref, user),
              icon: const Icon(Icons.done_all),
              label: const Text('Mark all read'),
            ),
        ],
      ),
      body: notifications.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'No notifications',
              message: 'Updates about grades, payments, and announcements will appear here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentNotificationsProvider(user.id)),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = list[i];
                return _NotificationTile(
                  item: n,
                  onTap: () => _markRead(ref, user, n),
                );
              },
            ),
          );
        },
        loading: () => const LoadingView(),
        error: (_, __) => const ErrorView(message: 'Could not load notifications.'),
      ),
    );
  }

  Future<void> _markRead(WidgetRef ref, AppUser user, NotificationItem item) async {
    if (item.read) return;
    await ref
        .read(studentRepositoryProvider)
        .markNotificationRead(user.id, item.id);
    ref.invalidate(studentNotificationsProvider(user.id));
  }

  Future<void> _markAllRead(WidgetRef ref, AppUser user) async {
    final list = ref.read(studentNotificationsProvider(user.id)).valueOrNull ?? const [];
    for (final n in list.where((n) => !n.read)) {
      await ref
          .read(studentRepositoryProvider)
          .markNotificationRead(user.id, n.id);
    }
    ref.invalidate(studentNotificationsProvider(user.id));
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});
  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: item.read ? scheme.surfaceContainerLow : scheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.read ? scheme.surfaceContainerHighest : scheme.primary,
          child: Icon(
            Icons.notifications_outlined,
            color: item.read ? scheme.onSurfaceVariant : scheme.onPrimary,
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(fontWeight: item.read ? FontWeight.normal : FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(item.body),
            const SizedBox(height: 4),
            Text(
              AppDateUtils.relative(item.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: onTap,
      ),
    );
  }
}
