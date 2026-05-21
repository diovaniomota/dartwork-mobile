import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/supabase_constants.dart';
import '../models/purchase.dart';

class PurchaseRepository {
  Future<List<Purchase>> getAll(
    String organizationId, {
    int page = 0,
    String? search,
  }) async {
    int offset = page * AppConstants.defaultPageSize;
    var query = supabase
        .from('purchases')
        .select()
        .eq('organization_id', organizationId);

    if (search != null && search.isNotEmpty) {
      // Filtrar pelo nome do fornecedor ou numero
      query = query.or(
        'fornecedor_nome.ilike.%$search%,numero.ilike.%$search%',
      );
    }

    final response = await query
        .order('data_entrada', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + AppConstants.defaultPageSize - 1);

    return (response as List)
        .map((json) => Purchase.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Purchase?> getById(String id) async {
    final response = await supabase
        .from('purchases')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Purchase.fromJson(response);
  }

  Future<Purchase> create(Purchase purchase) async {
    final response = await supabase
        .from('purchases')
        .insert(purchase.toJson())
        .select()
        .single();
    return Purchase.fromJson(response);
  }

  Future<Purchase> update(String id, Purchase purchase) async {
    final response = await supabase
        .from('purchases')
        .update(purchase.toJson())
        .eq('id', id)
        .select()
        .single();
    return Purchase.fromJson(response);
  }

  Future<void> delete(String id) async {
    await supabase.from('purchases').delete().eq('id', id);
  }
}

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository();
});
