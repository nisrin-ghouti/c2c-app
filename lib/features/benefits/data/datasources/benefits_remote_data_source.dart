import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around the raw Supabase table/RPC calls the benefits
/// feature needs. Only file in the feature allowed to reference
/// `supabase_flutter` types directly.
class BenefitsRemoteDataSource {
  const BenefitsRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> listBenefits() async {
    final rows = await _client
        .from('benefits')
        .select()
        .eq('active', true)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> listMyDigitalCards() async {
    final result = await _client.rpc('list_my_digital_cards');
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<Map<String, dynamic>> redeemBenefit(String benefitId) async {
    final result = await _client.rpc(
      'redeem_benefit',
      params: {'_benefit_id': benefitId},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<List<Map<String, dynamic>>> adminListBenefits() async {
    final result = await _client.rpc('admin_list_benefits');
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<Map<String, dynamic>> createBenefit(
    Map<String, dynamic> benefit,
  ) async {
    final result = await _client.rpc(
      'create_benefit',
      params: {'_benefit': benefit},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> updateBenefit(
    String id,
    Map<String, dynamic> benefit,
  ) async {
    final result = await _client.rpc(
      'update_benefit',
      params: {'_id': id, '_benefit': benefit},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  /// Uploads a benefit image to the public `benefit-images` bucket and returns
  /// its public URL. Bucket policy restricts writes to admins.
  Future<String> uploadBenefitImage(File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    final path =
        'benefit-${DateTime.now().millisecondsSinceEpoch}'
        '.${extension.isEmpty ? 'jpg' : extension}';

    await _client.storage
        .from('benefit-images')
        .upload(path, file, fileOptions: const FileOptions(upsert: true));
    return _client.storage.from('benefit-images').getPublicUrl(path);
  }

  Future<Map<String, dynamic>> setBenefitActive(String id, bool active) async {
    final result = await _client.rpc(
      'set_benefit_active',
      params: {'_id': id, '_active': active},
    );
    return Map<String, dynamic>.from(result as Map);
  }
}
