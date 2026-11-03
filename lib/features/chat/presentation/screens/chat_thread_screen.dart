import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/inline_banner.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../onboarding/domain/entities/demo_key.dart';
import '../../../onboarding/presentation/controllers/demo_flags_controller.dart';
import '../../../onboarding/presentation/widgets/contextual_showcase.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/send_message_result.dart';
import '../controllers/chat_thread_controller.dart';
import '../providers/chat_providers.dart';
import '../widgets/meeting_proposal_card.dart';
import '../widgets/propose_meeting_sheet.dart';
import '../widgets/report_user_sheet.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherFullName,
    required this.otherAvatarHue,
    this.otherAvatarUrl,
  });

  final String chatId;
  final String otherUserId;
  final String otherFullName;
  final int otherAvatarHue;
  final String? otherAvatarUrl;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _messageController = TextEditingController();
  final _blockButtonShowcaseKey = GlobalKey();
  final _reportButtonShowcaseKey = GlobalKey();
  final _meetingButtonShowcaseKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Opening the thread is "read" — same convention as the notifications
    // screen marking itself seen on open. Invalidate the list afterward so
    // its unread badge clears once the user navigates back.
    Future.microtask(() async {
      await ref.read(markChatReadProvider)(widget.chatId);
      ref.invalidate(myChatsProvider);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send(AppLocalizations l10n) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    final result = await ref
        .read(chatThreadControllerProvider(widget.otherUserId).notifier)
        .send(widget.chatId, text);
    if (!mounted || result == SendMessageResult.ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == SendMessageResult.blocked
              ? l10n.chatBlockedByOtherBanner
              : l10n.chatsLoadError,
        ),
      ),
    );
  }

  Future<void> _toggleBlock(
    AppLocalizations l10n,
    bool currentlyBlocked,
  ) async {
    if (!currentlyBlocked) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.chatBlockConfirmTitle),
          content: Text(l10n.chatBlockConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.chatBlockAction),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await ref
        .read(chatThreadControllerProvider(widget.otherUserId).notifier)
        .toggleBlock(currentlyBlocked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final iBlocked =
        ref.watch(haveIBlockedProvider(widget.otherUserId)).valueOrNull ??
        false;
    final viewerId = ref.watch(currentAuthSessionProvider).userId ?? '';

    if (!ref.watch(hasSeenDemoProvider(DemoKey.chatControls))) {
      startContextualDemoOnce(
        context: context,
        ref: ref,
        key: DemoKey.chatControls,
        showcaseKeys: [
          _blockButtonShowcaseKey,
          _reportButtonShowcaseKey,
          _meetingButtonShowcaseKey,
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            InitialsAvatar(
              initials: widget.otherFullName.isEmpty
                  ? '?'
                  : widget.otherFullName[0],
              hue: widget.otherAvatarHue,
              imageUrl: widget.otherAvatarUrl,
              size: 36,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.otherFullName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ContextualShowcase(
            isLastStep: false,
            showcaseKey: _blockButtonShowcaseKey,
            title: l10n.demoChatBlockTitle,
            description: l10n.demoChatBlockMessage,
            child: IconButton(
              icon: Icon(iBlocked ? Icons.block : Icons.block_outlined),
              tooltip: iBlocked ? l10n.chatUnblockAction : l10n.chatBlockAction,
              onPressed: () => _toggleBlock(l10n, iBlocked),
            ),
          ),
          ContextualShowcase(
            isLastStep: false,
            showcaseKey: _reportButtonShowcaseKey,
            title: l10n.demoReportUserTitle,
            description: l10n.demoReportUserMessage,
            child: IconButton(
              icon: const Icon(Icons.flag_outlined),
              tooltip: l10n.reportUserAction,
              onPressed: () => showReportUserSheet(
                context,
                widget.otherUserId,
                widget.otherFullName,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (iBlocked)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: InlineBanner(
                  message: l10n.chatBlockedBanner,
                  tone: BannerTone.neutral,
                ),
              ),
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(child: Text(l10n.chatsLoadError)),
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.chatEmptyThread,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    );
                  }
                  final items = _buildThreadItems(messages);
                  return ListView.builder(
                    // Standard messaging behaviour: newest message at the
                    // bottom, with the viewport anchored there so an arriving
                    // message is visible without scrolling (and older history
                    // stays put when the user has scrolled up).
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      // `reverse` makes index 0 the BOTTOM row, so walk the
                      // oldest-first list backwards.
                      final item = items[items.length - 1 - index];
                      switch (item) {
                        case _DateSeparatorItem(:final day):
                          return _DateSeparator(day: day);
                        case _MessageItem(:final message):
                          if (message.type == ChatMessageType.meetingProposal &&
                              message.proposalId != null) {
                            return Align(
                              alignment: message.senderId == viewerId
                                  ? AlignmentDirectional.centerEnd
                                  : AlignmentDirectional.centerStart,
                              child: MeetingProposalCard(
                                proposalId: message.proposalId!,
                                viewerId: viewerId,
                                otherName: widget.otherFullName,
                              ),
                            );
                          }
                          return _MessageBubble(
                            message: message,
                            isMine: message.senderId == viewerId,
                          );
                      }
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  ContextualShowcase(
                    showcaseKey: _meetingButtonShowcaseKey,
                    title: l10n.demoChatMeetingTitle,
                    description: l10n.demoChatMeetingMessage,
                    child: IconButton(
                      onPressed: iBlocked
                          ? null
                          : () =>
                                showProposeMeetingSheet(context, widget.chatId),
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: l10n.proposeMeetingTitle,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !iBlocked,
                      decoration: InputDecoration(
                        hintText: l10n.chatMessageHint,
                      ),
                      onSubmitted: (_) => _send(l10n),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: iBlocked ? null : () => _send(l10n),
                    icon: const Icon(Icons.send),
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

/// One row in the thread: either a centered date separator or a message.
sealed class _ThreadItem {
  const _ThreadItem();
}

class _DateSeparatorItem extends _ThreadItem {
  const _DateSeparatorItem(this.day);

  /// Local midnight of the day the following messages were sent on.
  final DateTime day;
}

class _MessageItem extends _ThreadItem {
  const _MessageItem(this.message);

  final ChatMessage message;
}

/// Groups an oldest-first message list into rows, inserting a date separator
/// ahead of the first message of each new day (WhatsApp-style).
///
/// `created_at` arrives as UTC, so days are bucketed on the LOCAL date —
/// otherwise a late-evening message would be filed under tomorrow.
List<_ThreadItem> _buildThreadItems(List<ChatMessage> messages) {
  final items = <_ThreadItem>[];
  DateTime? lastDay;
  for (final message in messages) {
    final local = message.createdAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    if (lastDay == null || day != lastDay) {
      items.add(_DateSeparatorItem(day));
      lastDay = day;
    }
    items.add(_MessageItem(message));
  }
  return items;
}

/// "Today" / "Yesterday" / a localized date. Uses [MaterialLocalizations]
/// rather than `intl`'s DateFormat, which would need `initializeDateFormatting`
/// for he/ar — flutter_localizations already ships these locales.
String _dateSeparatorLabel(BuildContext context, DateTime day) {
  final l10n = AppLocalizations.of(context);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  if (day == today) return l10n.chatDateToday;
  if (day == today.subtract(const Duration(days: 1))) {
    return l10n.chatDateYesterday;
  }

  final materialL10n = MaterialLocalizations.of(context);
  // Same year reads fine without it; older messages need the year for context.
  return day.year == today.year
      ? materialL10n.formatMediumDate(day)
      : materialL10n.formatFullDate(day);
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          _dateSeparatorLabel(context, day),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final local = message.createdAt.toLocal();
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMine ? AppGradients.primary : null,
                color: isMine ? null : AppColors.muted,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                // Trailing edge — flips automatically for RTL locales.
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: isMine
                          ? AppColors.primaryForeground
                          : AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMine
                          ? AppColors.primaryForeground.withValues(alpha: 0.75)
                          : AppColors.mutedForeground,
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
