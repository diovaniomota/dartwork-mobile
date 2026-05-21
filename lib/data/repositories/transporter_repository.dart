import '../models/transporter.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/constants/app_constants.dart';

class TransporterRepository {
  Future<List<Transporter>> getAll(
    String organizationId, {
    int page = 0,
    String? search,
  }) async {
    var query = supabase
        .from('transporters')
        .select()
        .eq('organization_id', organizationId);

    if (search != null && search.trim().isNotEmpty) {
      final s = search.trim();
      query = query.or('name.ilike.%$s%,document.ilike.%$s%');
    }

    final offset = page * AppConstants.defaultPageSize;
    final response = await query
        .order('name', ascending: true)
        .range(offset, offset + AppConstants.defaultPageSize - 1);

    return (response as List)
        .map((json) => Transporter.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Transporter?> getById(String id) async {
    final response = await supabase
        .from('transporters')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Transporter.fromJson(response);
  }

  Future<Transporter> create(Map<String, dynamic> data) async {
    final response = await supabase
        .from('transporters')
        .insert(data)
        .select()
        .single();
    return Transporter.fromJson(response);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await supabase.from('transporters').update(data).eq('id', id);
  }

  Future<void> delete(String id) async {
    await supabase.from('transporters').delete().eq('id', id);
  }
}
