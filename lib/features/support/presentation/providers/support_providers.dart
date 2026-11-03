import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../main.dart' show supabase;

/// One of the two admin-editable "Technical Support" contacts.
class SupportContact {
  const SupportContact({
    required this.slot,
    required this.name,
    required this.phone,
  });

  final int slot;
  final String name;
  final String phone;
}

/// Thin wrapper over the read-only `get_support_contacts` RPC — kept as one
/// small self-contained repository since the feature is just a read, same
/// convention as `ScheduledMeetingRepository`.
class SupportRepository {
  const SupportRepository(this._client);

  final SupabaseClient _client;

  Future<List<SupportContact>> listContacts() async {
    final result = await _client.rpc('get_support_contacts');
    return List<Map<String, dynamic>>.from(result as List)
        .map(
          (row) => SupportContact(
            slot: row['slot'] as int,
            name: (row['name'] as String?) ?? '',
            phone: (row['phone'] as String?) ?? '',
          ),
        )
        .where((c) => c.name.isNotEmpty || c.phone.isNotEmpty)
        .toList();
  }
}

final _supportClientProvider = Provider<SupabaseClient>((ref) => supabase);

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.watch(_supportClientProvider));
});

final supportContactsProvider =
    FutureProvider.autoDispose<List<SupportContact>>((ref) {
      return ref.watch(supportRepositoryProvider).listContacts();
    });
