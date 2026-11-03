import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/initials.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../domain/entities/chat.dart';
import '../providers/chat_providers.dart';
import 'chat_thread_screen.dart';

/// Every 1:1 conversation the viewer is part of — reached from the chat
/// bubble icon on `AppHeaderBar`, present on every top-level tab screen.
class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chatsAsync = ref.watch(myChatsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatsTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AppSearchField(
              controller: _searchController,
              hintText: l10n.chatsSearchHint,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(myChatsProvider.future),
              child: chatsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => ListView(
                  children: [
                    const SizedBox(height: 120),
                    Center(child: Text(l10n.chatsLoadError)),
                  ],
                ),
                data: (chats) {
                  final filtered = _query.isEmpty
                      ? chats
                      : chats
                            .where(
                              (c) => c.otherFullName.toLowerCase().contains(
                                _query,
                              ),
                            )
                            .toList();

                  if (chats.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Text(
                            l10n.chatsEmpty,
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  if (filtered.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Text(
                            l10n.chatsSearchEmpty,
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final chat = filtered[index];
                      return _ChatRow(
                        chat: chat,
                        l10n: l10n,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatThreadScreen(
                              chatId: chat.id,
                              otherUserId: chat.otherUserId,
                              otherFullName: chat.otherFullName,
                              otherAvatarHue: chat.otherAvatarHue,
                              otherAvatarUrl: chat.otherAvatarUrl,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.chat, required this.l10n, required this.onTap});

  final Chat chat;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = chat.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InitialsAvatar(
              initials: initialsOf(chat.otherFullName),
              hue: chat.otherAvatarHue,
              imageUrl: chat.otherAvatarUrl,
              size: 48,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.otherFullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    chat.lastMessageBody ?? l10n.chatEmptyThread,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: unread
                          ? AppColors.foreground
                          : AppColors.mutedForeground,
                      fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (chat.lastMessageAt != null)
                  Text(
                    timeago.format(chat.lastMessageAt!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                if (unread) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    constraints: const BoxConstraints(minWidth: 20),
                    decoration: BoxDecoration(
                      color: AppColors.foreground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
