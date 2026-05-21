import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/constants/app_constants.dart';

/// Repositório de produtos — alinhado com tabela `products` real do Supabase.
class ProductRepository {
  /// Lista produtos da organização com paginação.
  Future<List<Product>> getAll(
    String organizationId, {
    int page = 0,
    String? search,
    String? category,
  }) async {
    var query = supabase
        .from('products')
        .select()
        .eq('organization_id', organizationId);

    if (search != null && search.trim().isNotEmpty) {
      final s = search.trim();
      query = query.or('name.ilike.%$s%,gtin.ilike.%$s%,sku.ilike.%$s%');
    }

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }

    final offset = page * AppConstants.defaultPageSize;

    final response = await query
        .order('name')
        .range(offset, offset + AppConstants.defaultPageSize - 1);

    return (response as List)
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Busca produto por ID.
  Future<Product?> getById(String id) async {
    final response = await supabase
        .from('products')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Product.fromJson(response);
  }

  /// Busca produto por código de barras (GTIN).
  Future<Product?> getByBarcode(String gtin, String organizationId) async {
    final response = await supabase
        .from('products')
        .select()
        .eq('organization_id', organizationId)
        .eq('gtin', gtin)
        .maybeSingle();

    if (response == null) return null;
    return Product.fromJson(response);
  }

  /// Cria um novo produto.
  Future<Product> create(Map<String, dynamic> data) async {
    final response = await supabase
        .from('products')
        .insert(data)
        .select()
        .single();

    return Product.fromJson(response);
  }

  /// Atualiza um produto.
  Future<void> update(String id, Map<String, dynamic> data) async {
    await supabase.from('products').update(data).eq('id', id);
  }

  /// Remove um produto.
  Future<void> delete(String id) async {
    await supabase.from('products').delete().eq('id', id);
  }

  /// Conta total de produtos da organização.
  Future<int> count(String organizationId) async {
    final response = await supabase
        .from('products')
        .select('id')
        .eq('organization_id', organizationId);
    return (response as List).length;
  }

  /// Lista categorias únicas.
  Future<List<String>> getCategories(String organizationId) async {
    final response = await supabase
        .from('products')
        .select('category')
        .eq('organization_id', organizationId)
        .not('category', 'is', null);

    final categories = (response as List)
        .map((r) => r['category']?.toString() ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});
