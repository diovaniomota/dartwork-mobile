import '../models/service_order.dart';
import '../models/service_order_photo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/constants/app_constants.dart';

/// Repositório de ordens de serviço — alinhado com DB real.
class ServiceOrderRepository {
  static const String storageBucket = 'erp-files';

  String _sanitizeStorageSegment(String value) {
    final normalized = value.trim();
    final safe = normalized
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return safe.isEmpty ? 'arquivo' : safe;
  }

  String _buildPhotoFolder({
    required String organizationId,
    required String orderId,
  }) {
    final org = _sanitizeStorageSegment(organizationId);
    final os = _sanitizeStorageSegment(orderId);
    return 'org_$org/ordens-servico/$os/fotos';
  }

  int _extractFileSize(Map<String, dynamic>? metadata) {
    if (metadata == null) return 0;
    final size = metadata['size'];
    if (size is int && size > 0) return size;
    if (size is num && size > 0) return size.toInt();
    if (size is String) return int.tryParse(size) ?? 0;
    return 0;
  }

  DateTime? _parseObjectDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  String? _toNullableString(dynamic value) {
    if (value == null) return null;
    final parsed = value.toString().trim();
    return parsed.isEmpty ? null : parsed;
  }

  Future<void> _syncVehicleClientLink({
    required dynamic organizationId,
    required dynamic vehicleId,
    required dynamic clientId,
  }) async {
    final org = _toNullableString(organizationId);
    final vehicle = _toNullableString(vehicleId);
    final client = _toNullableString(clientId);
    if (org == null || vehicle == null || client == null) return;

    await supabase
        .from('vehicles')
        .update({'client_id': client})
        .eq('id', vehicle)
        .eq('organization_id', org);
  }

  Future<List<ServiceOrderPhoto>> getPhotos({
    required String organizationId,
    required String orderId,
    String bucket = storageBucket,
  }) async {
    final folder = _buildPhotoFolder(
      organizationId: organizationId,
      orderId: orderId,
    );

    final listed = await supabase.storage.from(bucket).list(path: folder);
    final rows = listed.where((f) => f.name != '.emptyFolderPlaceholder');

    final photos = await Future.wait(
      rows.map((f) async {
        final path = '$folder/${f.name}';
        String? signedUrl;
        try {
          signedUrl = await supabase.storage
              .from(bucket)
              .createSignedUrl(path, 60 * 60);
        } catch (_) {
          signedUrl = null;
        }

        return ServiceOrderPhoto(
          name: f.name,
          path: path,
          signedUrl: signedUrl,
          sizeBytes: _extractFileSize(f.metadata),
          updatedAt:
              _parseObjectDate(f.updatedAt) ?? _parseObjectDate(f.createdAt),
        );
      }),
    );

    photos.sort((a, b) {
      final ad = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return photos;
  }

  Future<ServiceOrderPhoto> uploadPhoto({
    required String organizationId,
    required String orderId,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
    String bucket = storageBucket,
  }) async {
    final folder = _buildPhotoFolder(
      organizationId: organizationId,
      orderId: orderId,
    );

    final safeName = _sanitizeStorageSegment(fileName);
    final path = '$folder/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    await supabase.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType ?? 'application/octet-stream',
            upsert: false,
          ),
        );

    String? signedUrl;
    try {
      signedUrl = await supabase.storage
          .from(bucket)
          .createSignedUrl(path, 60 * 60);
    } catch (_) {
      signedUrl = null;
    }

    return ServiceOrderPhoto(
      name: safeName,
      path: path,
      signedUrl: signedUrl,
      sizeBytes: bytes.lengthInBytes,
      updatedAt: DateTime.now(),
    );
  }

  /// Lista ordens de serviço com joins.
  Future<List<ServiceOrder>> getAll(
    String organizationId, {
    int page = 0,
    String? search,
    String? status,
  }) async {
    var query = supabase
        .from('ordens_servico')
        .select(
          '*, clients(name, tipo_pessoa, fantasy_name), vehicles(placa, modelo, marca), os_itens(*)',
        )
        .eq('organization_id', organizationId);

    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }

    final offset = page * AppConstants.defaultPageSize;

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + AppConstants.defaultPageSize - 1);

    return (response as List)
        .map((json) => ServiceOrder.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Busca OS por ID com itens.
  Future<ServiceOrder?> getById(String id) async {
    final response = await supabase
        .from('ordens_servico')
        .select(
          '*, clients(name, tipo_pessoa, fantasy_name), vehicles(placa, modelo, marca), os_itens(*)',
        )
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return ServiceOrder.fromJson(response);
  }

  /// Cria uma nova OS.
  Future<ServiceOrder> create(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    final userId = supabase.auth.currentUser?.id;
    payload['user_id'] = payload['user_id'] ?? userId;

    if ((payload['user_id']?.toString().trim().isEmpty ?? true)) {
      throw Exception('Usuário não autenticado para criar OS.');
    }

    final response = await supabase
        .from('ordens_servico')
        .insert(payload)
        .select()
        .single();

    await _syncVehicleClientLink(
      organizationId: payload['organization_id'],
      vehicleId: payload['vehicle_id'],
      clientId: payload['client_id'],
    );

    return ServiceOrder.fromJson(response);
  }

  /// Atualiza uma OS.
  Future<void> update(String id, Map<String, dynamic> data) async {
    await supabase.from('ordens_servico').update(data).eq('id', id);

    await _syncVehicleClientLink(
      organizationId: data['organization_id'],
      vehicleId: data['vehicle_id'],
      clientId: data['client_id'],
    );
  }

  /// Remove uma OS.
  Future<void> delete(String id) async {
    await supabase.from('ordens_servico').delete().eq('id', id);
  }

  /// Adiciona item à OS (tabela `os_itens`).
  Future<void> addItem(String osId, Map<String, dynamic> item) async {
    await supabase.from('os_itens').insert({...item, 'os_id': osId});
  }

  /// Remove item da OS.
  Future<void> removeItem(String itemId) async {
    await supabase.from('os_itens').delete().eq('id', itemId);
  }

  /// Finaliza uma OS com forma de pagamento.
  Future<void> finalizar(
    String id,
    String organizationId, {
    required String paymentMethod,
    required int totalCents,
    DateTime? paymentDate,
    String paymentStatus = 'pago_agora',
    int installments = 1,
    List<Map<String, dynamic>>? parcelas,
  }) async {
    final now = DateTime.now().toIso8601String();
    final dateStr = (paymentDate ?? DateTime.now()).toIso8601String();

    try {
      await supabase.rpc('fn_finalizar_os_pagamento_desktop', params: {
        'p_os_id': id,
        'p_organization_id': organizationId,
        'p_payment_status': paymentStatus,
        'p_total_value': totalCents / 100.0,
        'p_client_id': null,
        'p_method': paymentMethod,
        'p_description': 'Finalizado via mobile',
        'p_receivables': parcelas ?? [],
      });
      return;
    } catch (_) {
      // RPC não disponível — usa update direto.
    }

    final pStatus = paymentStatus == 'pendente'
        ? 'pendente'
        : paymentStatus == 'parcelado'
            ? 'parcelado'
            : 'pago';
    await supabase.from('ordens_servico').update({
      'status': 'finalizada',
      'payment_status': pStatus,
      'payment_method': paymentMethod,
      'data_fechamento': dateStr,
      'updated_at': now,
    }).eq('id', id).eq('organization_id', organizationId);
  }

  /// Busca checklist de entrada da OS.
  Future<Map<String, dynamic>?> getChecklist(
      String osId, String orgId) async {
    try {
      return await supabase
          .from('os_checklists')
          .select()
          .eq('os_id', osId)
          .eq('organization_id', orgId)
          .eq('tipo', 'entrada')
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  /// Salva checklist de entrada (upsert). Também atualiza km e tanque na OS.
  Future<void> saveChecklist(
    String osId,
    String orgId, {
    required Map<String, dynamic> items,
    String? observacoes,
    int? kmEntrada,
    String? tanqueNivel,
  }) async {
    await supabase.from('os_checklists').upsert({
      'os_id': osId,
      'organization_id': orgId,
      'tipo': 'entrada',
      'items': items,
      'observacoes': observacoes,
    }, onConflict: 'os_id,tipo');

    if (kmEntrada != null || tanqueNivel != null) {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (kmEntrada != null) updates['km_entrada'] = kmEntrada;
      if (tanqueNivel != null) updates['tanque_nivel'] = tanqueNivel;
      await supabase.from('ordens_servico').update(updates).eq('id', osId);
    }
  }

  /// Itens de checklist personalizados da empresa (ou lista padrão).
  Future<List<String>> getChecklistItems(String orgId) async {
    try {
      final response = await supabase
          .from('checklist_items')
          .select('name')
          .eq('organization_id', orgId)
          .eq('active', true)
          .order('name');
      final items = (response as List)
          .map((r) => r['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      return items.isNotEmpty ? items : _defaultChecklistItems;
    } catch (_) {
      return _defaultChecklistItems;
    }
  }

  static const _defaultChecklistItems = [
    'Lataria/Pintura', 'Vidros/Espelhos', 'Pneus/Rodas',
    'Faróis/Lanternas', 'Interior/Estofado', 'Painel/Instrumentos',
    'Macaco/Chave de Roda', 'Estepe', 'Bateria', 'Freios',
    'Óleo/Fluidos', 'Suspensão',
  ];

  /// Altera o status da OS de forma explícita.
  Future<void> updateStatus(
    String id,
    String organizationId,
    String status,
  ) async {
    await supabase
        .from('ordens_servico')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .eq('organization_id', organizationId);
  }

  /// Estorna uma OS finalizada/faturada (reverte estoque, financeiro e caixa).
  /// Usa a mesma RPC do desktop: fn_reverse_service_order.
  Future<void> estornar(
    String id,
    String organizationId,
    String reason,
  ) async {
    final userId = supabase.auth.currentUser?.id;
    final error = await supabase.rpc('fn_reverse_service_order', params: {
      'p_os_id': id,
      'p_organization_id': organizationId,
      'p_reason': reason,
      'p_user_id': userId,
    }).then((_) => null).catchError((e) => e);

    if (error != null) {
      throw Exception(_friendlyRpcError(error,
          'Não foi possível estornar a OS com segurança.'));
    }
  }

  /// Reabre uma OS estornada, voltando para "em_andamento".
  /// Usa a mesma RPC do desktop: fn_reopen_service_order.
  Future<void> reabrir(
    String id,
    String organizationId, {
    String? reason,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    final reopenReason =
        (reason?.trim().isNotEmpty ?? false) ? reason!.trim() : 'Reabertura de OS estornada.';

    final error = await supabase.rpc('fn_reopen_service_order', params: {
      'p_os_id': id,
      'p_organization_id': organizationId,
      'p_reason': reopenReason,
      'p_target_status': 'em_andamento',
      'p_user_id': userId,
    }).then((_) => null).catchError((e) => e);

    if (error != null) {
      throw Exception(_friendlyRpcError(error,
          'Não foi possível reabrir a OS com segurança.'));
    }
  }

  String _friendlyRpcError(Object error, String fallback) {
    final msg = error is PostgrestException ? error.message : error.toString();
    return msg.isNotEmpty ? msg : fallback;
  }

  /// Conta ordens por status.
  Future<Map<String, int>> countByStatus(String organizationId) async {
    final response = await supabase
        .from('ordens_servico')
        .select('status')
        .eq('organization_id', organizationId);

    final counts = <String, int>{};
    for (final row in (response as List)) {
      final status = row['status']?.toString() ?? 'aberta';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }
}

final serviceOrderRepositoryProvider = Provider<ServiceOrderRepository>((ref) {
  return ServiceOrderRepository();
});
