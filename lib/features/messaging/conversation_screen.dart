import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/shared_widgets.dart';
import '../../models/app_user.dart';
import '../../models/messaging_models.dart';
import '../../providers/feature_providers.dart';
import '../../providers/repository_providers.dart';

/// A single chat thread. Reads messages from the live stream, marks them read
/// on open, and sends new ones through the repository.
class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({required this.conversation, super.key});
  final Conversation conversation;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final me = ref.read(authControllerProvider).valueOrNull;
    if (me != null) {
      ref
          .read(messageRepositoryProvider)
          .markAsRead(widget.conversation.id, me.id);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final me = ref.read(authControllerProvider).valueOrNull;
    if (me == null) return;
    _controller.clear();
    await ref.read(messageRepositoryProvider).sendMessage(
          widget.conversation.id,
          me.id,
          text,
        );
    ref.invalidate(conversationsProvider);
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authControllerProvider).valueOrNull;
    final messages = ref.watch(messagesProvider(widget.conversation.id));

    return Scaffold(
      appBar: AppBar(
        title: widget.conversation.isGroup
            ? Text(widget.conversation.groupName ?? 'Group')
            : FutureBuilder<List<AppUser>>(
                future: ref.watch(allUsersProvider.future),
                builder: (context, snap) {
                  final all = snap.data ?? const <AppUser>[];
                  return Text(widget.conversation.getDisplayName(me?.id ?? '', all));
                },
              ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              data: (list) => list.isEmpty
                  ? const Center(
                      child: Text('No messages yet — say hello! 👋',
                          style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(12),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final m = list[i];
                        final mine = m.senderId == me?.id;
                        return Align(
                          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: mine
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!mine)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      m.senderName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                Text(
                                  m.getDisplayContent(),
                                  style: TextStyle(
                                    color: mine
                                        ? Theme.of(context).colorScheme.onPrimary
                                        : Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              loading: () => const LoadingView(),
              error: (_, __) => const ErrorView(message: 'Could not load this chat.'),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Message…',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                        filled: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
