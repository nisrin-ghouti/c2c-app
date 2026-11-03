import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../domain/entities/option_list_item.dart';
import '../../domain/entities/option_list_type.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._remote);

  final AdminRemoteDataSource _remote;

  @override
  Future<List<OptionListItem>> listOptions(OptionListType type) async {
    try {
      final rows = await _remote.listOptions(type.dbValue);
      return rows.map(_optionFromRow).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  OptionListItem _optionFromRow(Map<String, dynamic> row) {
    return OptionListItem(
      id: row['id'] as String,
      type: OptionListType.fromDbValue(row['list_type'] as String),
      label: row['label'] as String,
      labelAr: row['label_ar'] as String?,
      labelHe: row['label_he'] as String?,
      sortOrder: (row['sort_order'] as int?) ?? 0,
      active: row['active'] as bool? ?? true,
    );
  }
}
