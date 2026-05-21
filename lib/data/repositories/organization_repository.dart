import '../models/organization.dart';
import '../../core/constants/supabase_constants.dart';

/// Repositório de organização - gerencia dados da empresa.
class OrganizationRepository {
  /// Busca organização pelo ID.
  Future<Organization?> getById(String id) async {
    final response = await supabase
        .from('organizations')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Organization.fromJson(response);
  }

  /// Atualiza dados da organização.
  Future<void> update(String id, Map<String, dynamic> data) async {
    await supabase.from('organizations').update(data).eq('id', id);
  }
}
