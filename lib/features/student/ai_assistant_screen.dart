import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/shared_widgets.dart';
import '../../providers/feature_providers.dart';
import '../../providers/repository_providers.dart';

class _ChatMessage {
  const _ChatMessage({required this.text, required this.fromUser});
  final String text;
  final bool fromUser;
}

/// Backed by [StudentRepository.askAssistant] — a small keyword-matched
/// responder today. Swap that one method for a real LLM call (the Claude
/// API works well here) once you're ready to move past canned answers.
class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      fromUser: false,
      text: "Hi! I'm your PGPC academic assistant. Ask me about your schedule, "
          'tuition balance, enrollment requirements, or school policies.',
    ),
  ];
  bool _thinking = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, fromUser: true));
      _controller.clear();
      _thinking = true;
    });
    _scrollToEnd();

    final reply = await ref.read(studentRepositoryProvider).askAssistant(user.id, text);

    if (!context.mounted) return;
    setState(() {
      _messages.add(_ChatMessage(text: reply, fromUser: false));
      _thinking = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('AI Academic Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_thinking ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final m = _messages[i];
                return FadeSlideIn(
                  index: i,
                  child: Align(
                    alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: m.fromUser ? scheme.primary : scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: m.fromUser ? null : Border.all(color: scheme.outlineVariant),
                      ),
                      child: Text(
                        m.text,
                        style: TextStyle(color: m.fromUser ? scheme.onPrimary : scheme.onSurface),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Ask a question…'),
                      onSubmitted: (_) => _send(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _thinking ? null : _send,
                    icon: const Icon(Icons.send),
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
