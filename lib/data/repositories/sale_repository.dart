import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale.dart';
import '../../providers/organization_provider.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/constants/app_constants.dart';

class SaleRepository {
  Future<List<Sale>> getAll(
    String organizationId, {
    int page = 0,
    String? search,
    String? status, // 'pending', 'completed', 'cancelled'
  }) async {
    var query = supabase
        .from('sales')
        .select('*, clients(name)') // Join p/ clientName
        .eq('organization_id', organizationId);

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }

    // Busca simplificada (para busca robusta em joins do Supabase geralmente usamos RPC ou views)
    if (search != null && search.trim().isNotEmpty) {
      // Como não tem ID string simples de buscar, busca exata por ID se parecer numérico ou data,
      // ou apenas usa o filtro de status na AppUI em vez do form search por conta da complexidade nativa.
    }

    final offset = page * AppConstants.defaultPageSize;
    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + AppConstants.defaultPageSize - 1);

    return (response as List)
        .map((json) => Sale.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Sale?> getById(String id) async {
    final response = await supabase
        .from('sales')
        .select('*, clients(name), sale_items(*, products(name))')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Sale.fromJson(response);
  }

  /// Salva uma transação de Venda contendo múltiplos itens.
  /// (Idealmente deveria utilizar uma database RPC transaction, mas usaremos Dart Promise chain pattern
  /// p/ retrocompatibilidade).
  Future<Sale> create(
    Map<String, dynamic> saleData,
    List<Map<String, dynamic>> itemsData,
  ) async {
    // 1. Inserir a venda Header
    final saleResponse = await supabase
        .from('sales')
        .insert(saleData)
        .select()
        .single();

    final saleId = saleResponse['id'] as String;

    // 2. Injetar o SaleID em cada item filho e disparar bulk insert
    if (itemsData.isNotEmpty) {
      final itemsWithId = itemsData.map((item) {
        return {...item, 'sale_id': saleId};
      }).toList();

      await supabase.from('sale_items').insert(itemsWithId);
    }

    return Sale.fromJson(saleResponse);
  }

  Future<void> update(
    String id,
    Map<String, dynamic> saleData,
    List<Map<String, dynamic>> itemsData,
  ) async {
    // 1. Atualizar Header
    await supabase.from('sales').update(saleData).eq('id', id);

    // 2. Refresh drástico nos itens (Delete all -> Insert all) padrão na edição mobile.
    await supabase.from('sale_items').delete().eq('sale_id', id);
    if (itemsData.isNotEmpty) {
      final itemsWithId = itemsData.map((item) {
        return {...item, 'sale_id': id};
      }).toList();
      await supabase.from('sale_items').insert(itemsWithId);
    }
  }

  Future<void> delete(String id) async {
    await supabase.from('sales').delete().eq('id', id);
  }
}

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepository();
});

final salesProvider = FutureProvider.family<List<Sale>, String?>((
  ref,
  status,
) async {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return [];
  final repo = ref.read(saleRepositoryProvider);
  return await repo.getAll(orgId, status: status);
});
