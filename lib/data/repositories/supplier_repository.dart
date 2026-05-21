import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/supplier.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/constants/app_constants.dart';

class SupplierRepository {
  Future<List<Supplier>> getAll(
    String organizationId, {
    int page = 0,
    String? search,
  }) async {
    var query = supabase
        .from('suppliers')
        .select()
        .eq('organization_id', organizationId);

    if (search != null && search.trim().isNotEmpty) {
      final s = search.trim();
      query = query.or('name.ilike.%$s%,document.ilike.%$s%');
    }

    final offset = page * AppConstants.defaultPageSize;
    final response = await query
        .order('name')
        .range(offset, offset + AppConstants.defaultPageSize - 1);

    return (response as List)
        .map((json) => Supplier.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Supplier?> getById(String id) async {
    final response = await supabase
        .from('suppliers')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Supplier.fromJson(response);
  }

  Future<Supplier> create(Map<String, dynamic> data) async {
    final response = await supabase
        .from('suppliers')
        .insert(data)
        .select()
        .single();
    return Supplier.fromJson(response);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await supabase.from('suppliers').update(data).eq('id', id);
  }

  Future<void> delete(String id) async {
    await supabase.from('suppliers').delete().eq('id', id);
  }
}

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  return SupplierRepository();
});
