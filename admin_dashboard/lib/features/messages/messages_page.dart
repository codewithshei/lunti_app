import 'package:flutter/material.dart';

import 'package:admin_dashboard/features/auth/services/auth_service.dart';
import 'package:admin_dashboard/models/support_chat.dart';
import 'package:admin_dashboard/services/admin_database.dart';
import 'package:admin_dashboard/theme.dart';
import 'package:admin_dashboard/widgets/admin_ui.dart';

/// Customer support inbox for the admin studio.
///
/// The left panel follows the live `support_chats` collection, and the right
/// panel follows `support_chats/{uid}/messages`, so customer messages and admin
/// replies appear without a refresh.
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final AdminDatabase _database = AdminDatabase();
  late final Stream<List<SupportThread>> _threadsStream = _database
      .watchSupportThreads();
  String? _selectedUid;

  SupportThread? _selectedThread(List<SupportThread> threads, bool wide) {
    if (threads.isEmpty) return null;
    final match = threads.where((thread) => thread.uid == _selectedUid);
    if (match.isNotEmpty) return match.first;
    return wide ? threads.first : null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SupportThread>>(
      stream: _threadsStream,
      builder: (context, snapshot) {
        final threads = snapshot.data ?? const <SupportThread>[];
        final loading =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        final unread = threads.fold<int>(
          0,
          (total, thread) => total + thread.adminUnread,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final selected = _selectedThread(threads, wide);

            return Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminPageHeader(
                    title: 'Messages',
                    subtitle: 'Reply to customers without leaving the studio.',
                    trailing: _UnreadPill(count: unread),
                  ),
                  const SizedBox(height: 20),
                  if (snapshot.hasError)
                    AdminCard(
                      child: Text(
                        'Could not load conversations.\n${snapshot.error}',
                        style: const TextStyle(color: AdminColors.danger),
                      ),
                    )
                  else
                    Expanded(
                      child: _buildBody(
                        threads: threads,
                        loading: loading,
                        wide: wide,
                        selected: selected,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBody({
    required List<SupportThread> threads,
    required bool loading,
    required bool wide,
    required SupportThread? selected,
  }) {
    final list = _ThreadList(
      threads: threads,
      loading: loading,
      selectedUid: selected?.uid,
      onSelected: (uid) => setState(() => _selectedUid = uid),
    );

    if (!wide) {
      if (selected != null) {
        return _ConversationPanel(
          key: ValueKey(selected.uid),
          database: _database,
          thread: selected,
          onBack: () => setState(() => _selectedUid = null),
        );
      }
      return list;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 320, child: list),
        const SizedBox(width: 16),
        Expanded(
          child: selected == null
              ? const _NoConversation()
              : _ConversationPanel(
                  key: ValueKey(selected.uid),
                  database: _database,
                  thread: selected,
                  onBack: null,
                ),
        ),
      ],
    );
  }
}

class _UnreadPill extends StatelessWidget {
  const _UnreadPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: count > 0 ? AdminColors.mint : AdminColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: count > 0 ? AdminColors.sageDeep : AdminColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            count > 0
                ? Icons.mark_chat_unread_outlined
                : Icons.mark_chat_read_outlined,
            size: 16,
            color: count > 0 ? AdminColors.forest : AdminColors.muted,
          ),
          const SizedBox(width: 7),
          Text(
            count == 0
                ? 'All caught up'
                : '$count unread message${count == 1 ? '' : 's'}',
            style: TextStyle(
              color: count > 0 ? AdminColors.forest : AdminColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadList extends StatelessWidget {
  const _ThreadList({
    required this.threads,
    required this.loading,
    required this.selectedUid,
    required this.onSelected,
  });

  final List<SupportThread> threads;
  final bool loading;
  final String? selectedUid;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Conversations',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${threads.length}',
                  style: const TextStyle(
                    color: AdminColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : threads.isEmpty
                ? const _EmptyThreads()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: threads.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 18, endIndent: 18),
                    itemBuilder: (context, index) {
                      final thread = threads[index];
                      return _ThreadTile(
                        thread: thread,
                        selected: thread.uid == selectedUid,
                        onTap: () => onSelected(thread.uid),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({
    required this.thread,
    required this.selected,
    required this.onTap,
  });

  final SupportThread thread;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected ? AdminColors.mint : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(label: thread.displayName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: thread.hasUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _threadTime(thread.lastMessageAt),
                        style: const TextStyle(
                          color: AdminColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    thread.displayEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AdminColors.muted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.lastMessage.isEmpty
                              ? 'No messages yet'
                              : thread.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: thread.hasUnread
                                ? AdminColors.text
                                : AdminColors.muted,
                            fontSize: 12,
                            fontWeight: thread.hasUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (thread.hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AdminColors.sage,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${thread.adminUnread}',
                            style: const TextStyle(
                              color: AdminColors.ink,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyThreads extends StatelessWidget {
  const _EmptyThreads();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.forum_outlined,
              size: 38,
              color: AdminColors.muted,
            ),
            const SizedBox(height: 14),
            const Text(
              'No conversations yet',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Messages sent from the LUNTI app appear here in real time.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AdminColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoConversation extends StatelessWidget {
  const _NoConversation();

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: AdminColors.muted,
            ),
            const SizedBox(height: 14),
            const Text(
              'Select a conversation',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose a customer on the left to read and reply.',
              style: TextStyle(color: AdminColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationPanel extends StatefulWidget {
  const _ConversationPanel({
    super.key,
    required this.database,
    required this.thread,
    required this.onBack,
  });

  final AdminDatabase database;
  final SupportThread thread;
  final VoidCallback? onBack;

  @override
  State<_ConversationPanel> createState() => _ConversationPanelState();
}

class _ConversationPanelState extends State<_ConversationPanel> {
  final TextEditingController _composer = TextEditingController();
  late Stream<List<SupportMessage>> _messagesStream;
  bool _sending = false;
  bool _markingRead = false;

  @override
  void initState() {
    super.initState();
    _messagesStream = widget.database.watchSupportMessages(widget.thread.uid);
    _composer.addListener(_onTextChanged);
    _markReadIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _ConversationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thread.uid != widget.thread.uid) {
      _messagesStream = widget.database.watchSupportMessages(widget.thread.uid);
      _composer.clear();
    }
    _markReadIfNeeded();
  }

  @override
  void dispose() {
    _composer
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  bool get _canSend => _composer.text.trim().isNotEmpty && !_sending;

  void _markReadIfNeeded() {
    if (!widget.thread.hasUnread || _markingRead) return;
    _markingRead = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await widget.database.markSupportThreadRead(widget.thread.uid);
      } catch (_) {
        // The badge is cosmetic; a failed reset must not block the chat.
      } finally {
        _markingRead = false;
      }
    });
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending) return;

    final adminId = AuthService.instance.currentUser?.uid;
    if (adminId == null) {
      _showMessage('Sign in again to reply.');
      return;
    }

    setState(() => _sending = true);
    try {
      await widget.database.sendSupportMessage(
        uid: widget.thread.uid,
        adminId: adminId,
        text: text,
      );
      if (!mounted) return;
      _composer.clear();
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not send the reply. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ConversationHeader(thread: widget.thread, onBack: widget.onBack),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<SupportMessage>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load this conversation.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AdminColors.danger),
                      ),
                    ),
                  );
                }
                final messages = snapshot.data ?? const <SupportMessage>[];
                if (snapshot.connectionState == ConnectionState.waiting &&
                    messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Say hello.',
                      style: TextStyle(color: AdminColors.muted),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(18),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    return _MessageBubble(message: message);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          _Composer(
            controller: _composer,
            sending: _sending,
            canSend: _canSend,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _ConversationHeader extends StatelessWidget {
  const _ConversationHeader({required this.thread, required this.onBack});

  final SupportThread thread;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 18, 12),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              tooltip: 'Back to conversations',
              icon: const Icon(Icons.arrow_back, size: 20),
            ),
          _Avatar(label: thread.displayName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thread.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  thread.displayEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AdminColors.surfaceAlt,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AdminColors.border),
            ),
            child: const Text(
              'CUSTOMER',
              style: TextStyle(
                color: AdminColors.muted,
                fontSize: 9,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final isAdmin = message.isAdmin;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: isAdmin
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            isAdmin ? 'LUNTI Support' : 'Customer',
            style: TextStyle(
              color: isAdmin ? AdminColors.forest : AdminColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: isAdmin
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isAdmin ? AdminColors.sage : AdminColors.surfaceAlt,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isAdmin ? 14 : 4),
                      bottomRight: Radius.circular(isAdmin ? 4 : 14),
                    ),
                    border: isAdmin
                        ? null
                        : Border.all(color: AdminColors.border),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isAdmin ? AdminColors.ink : AdminColors.text,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            _timeLabel(message.timestamp),
            style: const TextStyle(color: AdminColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.canSend,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Write a reply to the customer\u2026',
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: canSend ? onSend : null,
            icon: sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AdminColors.cream,
                    ),
                  )
                : const Icon(Icons.send, size: 17),
            label: Text(sending ? 'Sending' : 'Send'),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final initial = label.trim().isEmpty
        ? '?'
        : label.trim().substring(0, 1).toUpperCase();
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AdminColors.sage,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: AdminColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}

String _timeLabel(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

String _threadTime(DateTime? date) {
  if (date == null) return '';
  final now = DateTime.now();
  final sameDay =
      date.year == now.year && date.month == now.month && date.day == now.day;
  if (sameDay) return _timeLabel(date);
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}
