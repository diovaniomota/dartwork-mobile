import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pdv_sale.dart';
import '../../core/constants/supabase_constants.dart';

/// Repositório de PDV — alinhado com tabelas reais `sales` e `sale_items`.
class PdvRepository {
  /// Cria uma nova venda.
  Future<PdvSale> createSale(
    Map<String, dynamic> saleData,
    List<Map<String, dynamic>> items,
  ) async {
    // Mapear para colunas reais da tabela `sales`
    final salesRow = {
      'organization_id': saleData['organization_id'],
      'total': saleData['total_value'] ?? saleData['total'] ?? 0,
      'subtotal': saleData['total_value'] ?? saleData['subtotal'] ?? 0,
      'discount': saleData['discount'] ?? 0,
      'payment_method': saleData['payment_method'],
      'status': saleData['status'] ?? 'completed',
      'seller_name': saleData['seller_name'],
      'client_id': saleData['client_id'],
      'client_name': saleData['client_name'],
      'cash_register_id': saleData['cash_register_id'],
    };

    // Remove campos nulos
    salesRow.removeWhere((key, value) => value == null);

    // Cria a venda
    final saleResponse = await supabase
        .from('sales')
        .insert(salesRow)
        .select()
        .single();

    final saleId = saleResponse['id'];

    // Adiciona os itens da venda
    if (items.isNotEmpty) {
      final saleItems = items
          .map(
            (item) => {
              'sale_id': saleId,
              'product_id': item['product_id'],
              'product_name': item['name'] ?? item['product_name'] ?? '',
              'quantity': item['quantity'] ?? 1,
              'unit_price': item['unit_price'] ?? 0,
              'discount': item['discount'] ?? 0,
              'subtotal': item['total_price'] ?? item['subtotal'] ?? 0,
            },
          )
          .toList();
      await supabase.from('sale_items').insert(saleItems);
    }

    return PdvSale.fromJson(saleResponse);
  }

  /// Lista vendas recentes.
  Future<List<PdvSale>> getRecentSales(
    String organizationId, {
    int limit = 20,
  }) async {
    final response = await supabase
        .from('sales')
        .select('*, sale_items(*)')
        .eq('organization_id', organizationId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => PdvSale.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

final pdvRepositoryProvider = Provider<PdvRepository>((ref) {
  return PdvRepository();
});
