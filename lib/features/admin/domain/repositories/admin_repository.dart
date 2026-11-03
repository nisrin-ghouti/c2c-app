import '../entities/option_list_item.dart';
import '../entities/option_list_type.dart';

/// Read-only seam for the shared option-list lookup (categories, faculties,
/// hobbies, etc.) — the only piece of `features/admin` still used by the
/// mobile app. All admin CRUD/management now lives in the c2c-admin panel.
abstract interface class AdminRepository {
  Future<List<OptionListItem>> listOptions(OptionListType type);
}
