import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/send_message_result.dart';
import '../providers/chat_providers.dart';

/// Drives one chat thread's mutating actions (send, block/unblock) — the
/// message list itself comes from the realtime `chatMessagesProvider`, this
/// controller doesn't hold message state.
class ChatThreadController extends StateNotifier<AsyncValue<void>> {
  ChatThreadController(this._ref, this._otherUserId)
    : super(const AsyncData(null));

  final Ref _ref;
  final String _otherUserId;

  Future<SendMessageResult> send(String chatId, String body) async {
    final result = await _ref.read(sendMessageProvider)(chatId, body);
    if (result == SendMessageResult.ok) {
      _ref.invalidate(myChatsProvider);
    }
    return result;
  }

  Future<void> toggleBlock(bool currentlyBlocked) async {
    if (currentlyBlocked) {
      await _ref.read(unblockUserProvider)(_otherUserId);
    } else {
      await _ref.read(blockUserProvider)(_otherUserId);
    }
    _ref.invalidate(haveIBlockedProvider(_otherUserId));
  }
}

final chatThreadControllerProvider = StateNotifierProvider.autoDispose
    .family<ChatThreadController, AsyncValue<void>, String>((ref, otherUserId) {
      return ChatThreadController(ref, otherUserId);
    });
