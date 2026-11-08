import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../app/router.dart';
import '../models/support_message.dart';
import '../services/chat_service.dart';
import '../widgets/brand_header.dart';
import '../widgets/lunti_skeleton.dart';
import 'auth/auth_widgets.dart';

/// Customer-to-admin support chat.
///
/// The conversation is a live `support_chats/{uid}/messages` stream. Admin
/// replies (written by the dashboard with `isAdmin: true`) appear on the left,
/// while the customer's messages sit on the right. Guests are asked to sign in
/// before a conversation is created.
class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key, this.uid});

  /// Optional uid when the caller already knows the signed-in account.
  final String? uid;

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return _ChatScaffold(uid: 'local-user');
    }
    if (widget.uid != null) {
      return _ChatScaffold(uid: widget.uid!);
    }
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user != null) return _ChatScaffold(uid: user.uid);
        return Scaffold(
          backgroundColor: context.lunti.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                BrandHeader(
                  onBack: () => Navigator.of(context).maybePop(),
                  onBagPressed: null,
                  showBadge: false,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(LuntiSpacing.gutter),
                    children: [
                      AuthRequiredCard(
                        title: 'Sign in to chat with us',
                        body: 'We can help with orders, engraving, delivery '
                            'and product questions once you are signed in.',
                        actionLabel: 'Sign in',
                        icon: Icons.support_agent,
                        onPressed: () => AppRouter.openSignIn(
                          context,
                          title: 'Sign in to chat',
                          subtitle: 'Our team replies inside the app.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChatScaffold extends StatefulWidget {
  const _ChatScaffold({required this.uid});

  final String uid;

  @override
  State<_ChatScaffold> createState() => _ChatScaffoldState();
}

class _ChatScaffoldState extends State<_ChatScaffold> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!mounted) return;
    setState(() {});
  }

  bool get _canSend => _controller.text.trim().isNotEmpty && !_sending;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    final error = await ChatService.instance.sendMessage(
      uid: widget.uid,
      senderId: widget.uid,
      text: text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.lunti.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BrandHeader(
              onBack: () => Navigator.of(context).maybePop(),
              onBagPressed: null,
              showBadge: false,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LuntiSpacing.gutter,
                LuntiSpacing.md,
                LuntiSpacing.gutter,
                LuntiSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chat with us', style: context.lunti.display),
                  const SizedBox(height: LuntiSpacing.xs),
                  Text(
                    'Questions about an order, engraving or delivery? '
                    'Send us a message.',
                    style: context.lunti.body,
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<SupportMessage>>(
                stream: ChatService.instance.watchMessages(widget.uid),
                builder: (context, snapshot) {
                  final messages =
                      snapshot.data ?? const <SupportMessage>[];
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      messages.isEmpty) {
                    return const _ChatSkeleton();
                  }
                  if (messages.isEmpty) {
                    return const _EmptyChat();
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(
                      LuntiSpacing.gutter,
                      LuntiSpacing.sm,
                      LuntiSpacing.gutter,
                      LuntiSpacing.sm,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 - index];
                      return _MessageBubble(message: message);
                    },
                  );
                },
              ),
            ),
            _Composer(
              controller: _controller,
              canSend: _canSend,
              sending: _sending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(LuntiSpacing.gutter),
      children: [
        Container(
          padding: const EdgeInsets.all(LuntiSpacing.lg),
          decoration: BoxDecoration(
            color: context.lunti.surface,
            borderRadius: BorderRadius.circular(LuntiRadii.md),
          ),
          child: Column(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: context.lunti.textFaint,
              ),
              const SizedBox(height: LuntiSpacing.sm),
              Text(
                'Start a conversation',
                style: context.lunti.sectionTitle.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: LuntiSpacing.xs),
              Text(
                'Ask us about an order, engraving, delivery or anything else. '
                'Our team replies here.',
                style: context.lunti.body,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
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
      padding: const EdgeInsets.only(bottom: LuntiSpacing.sm),
      child: Column(
        crossAxisAlignment:
            isAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          if (isAdmin) ...[
            Text(
              'LUNTI Support',
              style: context.lunti.caption.copyWith(
                color: context.lunti.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: LuntiSpacing.md,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isAdmin ? context.lunti.surfaceAlt : context.lunti.accent,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(LuntiRadii.md),
                topRight: const Radius.circular(LuntiRadii.md),
                bottomLeft: Radius.circular(isAdmin ? 4 : LuntiRadii.md),
                bottomRight: Radius.circular(isAdmin ? LuntiRadii.md : 4),
              ),
            ),
            child: Text(
              message.text,
              style: context.lunti.body.copyWith(
                color: isAdmin ? context.lunti.text : context.lunti.background,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _timeLabel(message.timestamp),
            style: context.lunti.caption,
          ),
        ],
      ),
    );
  }

  static String _timeLabel(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.canSend,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool canSend;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          LuntiSpacing.gutter,
          LuntiSpacing.sm,
          LuntiSpacing.gutter,
          LuntiSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.lunti.background,
          border: Border(top: BorderSide(color: context.lunti.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Write a message\u2026',
                  hintStyle: context.lunti.caption,
                  filled: true,
                  fillColor: context.lunti.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: LuntiSpacing.md,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(LuntiRadii.md),
                    borderSide: BorderSide(color: context.lunti.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(LuntiRadii.md),
                    borderSide: BorderSide(
                      color: context.lunti.accent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: LuntiSpacing.xs),
            SizedBox(
              width: 48,
              height: 48,
              child: FilledButton(
                onPressed: canSend ? onSend : null,
                style: FilledButton.styleFrom(
                  backgroundColor: context.lunti.accent,
                  foregroundColor: context.lunti.surface,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(LuntiRadii.md),
                  ),
                ),
                child: sending
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.lunti.surface,
                        ),
                      )
                    : const Icon(Icons.send, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chat bubble placeholders shown while the first page of messages loads.
class _ChatSkeleton extends StatelessWidget {
  const _ChatSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(LuntiSpacing.gutter),
      children: const [
        Align(
          alignment: Alignment.centerLeft,
          child: _SkeletonBubble(width: 210),
        ),
        SizedBox(height: LuntiSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: _SkeletonBubble(width: 150),
        ),
        SizedBox(height: LuntiSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: _SkeletonBubble(width: 240),
        ),
      ],
    );
  }
}

class _SkeletonBubble extends StatelessWidget {
  const _SkeletonBubble({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: const LuntiShimmer(
        child: SkeletonBox(
          width: double.infinity,
          height: 44,
          radius: 14,
        ),
      ),
    );
  }
}
