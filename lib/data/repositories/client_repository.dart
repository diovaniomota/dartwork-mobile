import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/constants/app_constants.dart';

/// Repositório de clientes — alinhado com tabela `clients` real do Supabase.
class ClientRepository {
  /// Lista clientes da organização com paginação.
  Future<List<ClientModel>> getAll(
    String organizationId, {
    int page = 0,
    String? search,
  }) async {
    var query = supabase
        .from('clients')
        .select()
        .eq('organization_id', organizationId);

    if (search != null && search.trim().isNotEmpty) {
      query = query.or(
        'name.ilike.%${search.trim()}%,fantasy_name.ilike.%${search.trim()}%,document.ilike.%${search.trim()}%,email.ilike.%${search.trim()}%,phone.ilike.%${search.trim()}%',
      );
    }

    final offset = page * AppConstants.defaultPageSize;

    final response = await query
        .order('name')
        .range(offset, offset + AppConstants.defaultPageSize - 1);

    return (response as List)
        .map((json) => ClientModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Busca cliente por ID.
  Future<ClientModel?> getById(String id) async {
    final response = await supabase
        .from('clients')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return ClientModel.fromJson(response);
  }

  /// Cria um novo cliente.
  Future<ClientModel> create(Map<String, dynamic> data) async {
    final response = await supabase
        .from('clients')
        .insert(data)
        .select()
        .single();

    return ClientModel.fromJson(response);
  }

  /// Atualiza um cliente.
  Future<void> update(String id, Map<String, dynamic> data) async {
    await supabase.from('clients').update(data).eq('id', id);
  }

  /// Remove um cliente.
  Future<void> delete(String id) async {
    await supabase.from('clients').delete().eq('id', id);
  }

  /// Conta total de clientes da organização.
  Future<int> count(String organizationId) async {
    final response = await supabase
        .from('clients')
        .select('id')
        .eq('organization_id', organizationId);
    return (response as List).length;
  }
}

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository();
});
