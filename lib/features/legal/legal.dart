import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show SupabaseClient, PostgrestException;

import '../../main.dart' show supabase;

/// The two editable legal documents. Their string value is the DB `kind`.
enum LegalDocumentKind {
  privacy('privacy'),
  terms('terms');

  const LegalDocumentKind(this.dbValue);
  final String dbValue;
}

/// One editable legal document (Privacy Policy or Terms & Conditions).
class LegalDocument {
  const LegalDocument({
    required this.kind,
    required this.title,
    required this.body,
    this.updatedAt,
  });

  final LegalDocumentKind kind;
  final String title;
  final String body;
  final DateTime? updatedAt;
}

/// Thin Supabase wrapper for the two `legal_documents` RPCs. Kept in one file
/// since the feature is small — a read used by everyone and a super-admin-only
/// write.
class LegalRepository {
  const LegalRepository(this._client);

  final SupabaseClient _client;

  Future<LegalDocument?> getDocument(LegalDocumentKind kind) async {
    final result = await _client.rpc(
      'get_legal_document',
      params: {'_kind': kind.dbValue},
    );
    if (result == null) return null;
    final map = Map<String, dynamic>.from(result as Map);
    return LegalDocument(
      kind: kind,
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.tryParse(map['updated_at'] as String),
    );
  }

  /// Super-admin only (enforced server-side). Throws [LegalEditDenied] if the
  /// caller isn't the super admin, so the UI can show a clear message rather
  /// than a raw Postgres error.
  Future<void> saveDocument(
    LegalDocumentKind kind,
    String title,
    String body,
  ) async {
    try {
      await _client.rpc(
        'upsert_legal_document',
        params: {'_kind': kind.dbValue, '_title': title, '_body': body},
      );
    } on PostgrestException catch (e) {
      // 42501 = insufficient_privilege, raised by the RPC's super-admin guard.
      if (e.code == '42501') throw const LegalEditDenied();
      rethrow;
    }
  }
}

class LegalEditDenied implements Exception {
  const LegalEditDenied();
}

final _legalClientProvider = Provider<SupabaseClient>((ref) => supabase);

final legalRepositoryProvider = Provider<LegalRepository>((ref) {
  return LegalRepository(ref.watch(_legalClientProvider));
});

/// The current content of one document. Auto-disposes so re-opening after an
/// edit re-fetches.
final legalDocumentProvider = FutureProvider.autoDispose
    .family<LegalDocument?, LegalDocumentKind>((ref, kind) {
      return ref.watch(legalRepositoryProvider).getDocument(kind);
    });
