import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/organization_provider.dart';
import '../../core/constants/supabase_constants.dart';

/// Repositório de veículos - CRUD completo com busca.
class VehicleRepository {
  /// Lista veículos da organização com paginação.
  Future<List<Vehicle>> getAll(
    String organizationId, {
    int page = 0,
    String? search,
    String? clientId,
  }) async {
    var query = supabase
        .from('vehicles')
        .select()
        .eq('organization_id', organizationId);

    if (search != null && search.trim().isNotEmpty) {
      query = query.or(
        'placa.ilike.%${search.trim()}%,marca.ilike.%${search.trim()}%,modelo.ilike.%${search.trim()}%',
      );
    }

    if (clientId != null) {
      query = query.eq('client_id', clientId);
    }

    final offset = page * AppConstants.defaultPageSize;

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + AppConstants.defaultPageSize - 1);

    return (response as List)
        .map((json) => Vehicle.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Busca veículo por ID.
  Future<Vehicle?> getById(String id) async {
    final response = await supabase
        .from('vehicles')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Vehicle.fromJson(response);
  }

  /// Cria um novo veículo.
  Future<Vehicle> create(Map<String, dynamic> data) async {
    final response = await supabase
        .from('vehicles')
        .insert(data)
        .select()
        .single();

    return Vehicle.fromJson(response);
  }

  /// Atualiza um veículo.
  Future<void> update(String id, Map<String, dynamic> data) async {
    await supabase.from('vehicles').update(data).eq('id', id);
  }

  /// Remove um veículo.
  Future<void> delete(String id) async {
    await supabase.from('vehicles').delete().eq('id', id);
  }

  /// Conta total de veículos da organização.
  Future<int> count(String organizationId) async {
    final response = await supabase
        .from('vehicles')
        .select('id')
        .eq('organization_id', organizationId);
    return (response as List).length;
  }
}

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepository();
});

final vehiclesProvider = FutureProvider.family<List<Vehicle>, String?>((
  ref,
  search,
) async {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return [];
  final repo = ref.read(vehicleRepositoryProvider);
  return await repo.getAll(orgId, search: search);
});
