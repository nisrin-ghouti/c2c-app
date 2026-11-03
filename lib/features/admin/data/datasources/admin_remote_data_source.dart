import 'package:supabase_flutter/supabase_flutter.dart';

/// Raw Supabase call backing the shared option-list lookup (categories,
/// faculties, hobbies, etc. — translated display labels used app-wide).
/// Despite the folder name, this is no longer an admin-management feature;
/// all admin CRUD for these lists now lives in the separate c2c-admin panel.
class AdminRemoteDataSource {
  const AdminRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> listOptions(String listType) async {
    final rows = await _client
        .from('option_lists')
        .select('id, list_type, label, label_ar, label_he, sort_order, active')
        .eq('list_type', listType)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(rows);
  }
}
