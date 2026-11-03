import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../../../main.dart' show supabase;
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/meeting_proposal.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/chat_usecases.dart';

final _supabaseClientProvider = Provider<SupabaseClient>((ref) => supabase);

final _chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource(ref.watch(_supabaseClientProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ref.watch(_chatRemoteDataSourceProvider));
});

final listMyChatsProvider = Provider(
  (ref) => ListMyChats(ref.watch(chatRepositoryProvider)),
);
final getOrCreateChatProvider = Provider(
  (ref) => GetOrCreateChat(ref.watch(chatRepositoryProvider)),
);
final markChatReadProvider = Provider(
  (ref) => MarkChatRead(ref.watch(chatRepositoryProvider)),
);
final sendMessageProvider = Provider(
  (ref) => SendMessage(ref.watch(chatRepositoryProvider)),
);
final blockUserProvider = Provider(
  (ref) => BlockUser(ref.watch(chatRepositoryProvider)),
);
final unblockUserProvider = Provider(
  (ref) => UnblockUser(ref.watch(chatRepositoryProvider)),
);
final proposeMeetingProvider = Provider(
  (ref) => ProposeMeeting(ref.watch(chatRepositoryProvider)),
);
final respondToProposalProvider = Provider(
  (ref) => RespondToProposal(ref.watch(chatRepositoryProvider)),
);
final watchProposalProvider = Provider(
  (ref) => WatchProposal(ref.watch(chatRepositoryProvider)),
);
final submitReportProvider = Provider(
  (ref) => SubmitReport(ref.watch(chatRepositoryProvider)),
);
final uploadReportImageProvider = Provider(
  (ref) => UploadReportImage(ref.watch(chatRepositoryProvider)),
);

final myChatsProvider = FutureProvider.autoDispose<List<Chat>>((ref) {
  return ref.watch(listMyChatsProvider)();
});

/// Badge count for `AppHeaderBar`'s chat icon — total unread messages across
/// every conversation, derived from the same list the Chats screen already
/// fetches (each `Chat` already carries its own `unreadCount`).
final unreadChatsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final chats = await ref.watch(myChatsProvider.future);
  return chats.fold<int>(0, (sum, chat) => sum + chat.unreadCount);
});

/// Realtime message feed for one chat thread.
final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, chatId) {
      return ref.watch(chatRepositoryProvider).watchMessages(chatId);
    });

/// Whether the viewer has blocked the other participant.
final haveIBlockedProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  otherUserId,
) {
  return ref.watch(chatRepositoryProvider).haveIBlocked(otherUserId);
});

/// A single meeting proposal's live details, for the inline chat card.
///
/// A realtime stream, not a one-shot read. The row is written by whichever
/// participant did NOT create it, so the proposer's card has to follow a
/// status it didn't set: with a `FutureProvider` here, only the responder's
/// own `ref.invalidate` ever refetched, and the proposer's card stayed on
/// "waiting for a response" until the thread was closed and reopened. Both
/// sides now render whatever the row currently says.
final meetingProposalProvider = StreamProvider.autoDispose
    .family<MeetingProposal?, String>((ref, proposalId) {
      return ref.watch(watchProposalProvider)(proposalId);
    });
