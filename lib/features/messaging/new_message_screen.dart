import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/shared_widgets.dart';
import '../../providers/feature_providers.dart';
import '../../providers/repository_providers.dart';
import 'conversation_screen.dart';

/// Pick a person to start a chat with. Resolves the recipient's name from the
/// shared directory and opens (or creates) a 1:1 conversation.
class NewMessageScreen extends ConsumerWidget {
  const NewMessageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider).valueOrNull;
    if (me == null) return const LoadingView();

    final partners = ref.watch(potentialChatPartnersProvider(me.id));

    return Scaffold(
      appBar: AppBar(title: const Text('New Message')),
      body: partners.when(
        data: (users) {
          if (users.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: 'No contacts',
              message: 'There\'s no one available to message right now.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, i) {
              final u = users[i];
              return Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: InitialsAvatar(name: u.name),
                  title: Text(u.name),
                  subtitle: Text(u.role.label),
                  onTap: () async {
                    final result = await ref
                        .read(messageRepositoryProvider)
                        .getOrCreateConversation([me.id, u.id]);
                    if (!context.mounted) return;
                    result.when(
                      ok: (conv) => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => ConversationScreen(conversation: conv)),
                      ),
                      error: (msg) => ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(msg))),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (_, __) => const ErrorView(message: 'Could not load contacts.'),
      ),
    );
  }
}
