import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/shared_widgets.dart';
import '../../models/app_user.dart';
import '../../providers/feature_providers.dart';
import 'conversation_screen.dart';
import 'new_message_screen.dart';

/// Lists the current user's conversations with unread badges and lets them
/// start a new chat. Resolves 1:1 peer names from the shared user directory.
class MessageListScreen extends ConsumerWidget {
  const MessageListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider).valueOrNull;
    if (me == null) return const LoadingView();

    final conversations = ref.watch(conversationsProvider(me.id));
    final users = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NewMessageScreen()),
        ),
        tooltip: 'New message',
        child: const Icon(Icons.add_comment_outlined),
      ),
      body: conversations.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.chat_outlined,
              title: 'No conversations yet',
              message: 'Tap the + button to message a classmate or faculty member.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final conv = list[i];
              final allUsers = users.valueOrNull ?? const <AppUser>[];
              final unread = conv.getUnreadCount(me.id);
              final title = conv.getDisplayName(me.id, allUsers);
              final subtitle = conv.lastMessage?.getDisplayContent() ??
                  (conv.isGroup ? 'Group created' : 'No messages yet');

              return Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: conv.isGroup
                      ? CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.group),
                        )
                      : InitialsAvatar(name: title),
                  title: Row(
                    children: [
                      Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
                      if (unread > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$unread',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ConversationScreen(conversation: conv)),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (_, __) => const ErrorView(message: 'Could not load messages.'),
      ),
    );
  }
}
