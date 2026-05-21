import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/supabase_constants.dart';
import '../models/nota_fiscal.dart';

/// Repositório unificado para as Notas Fiscais, separando entre nfce (65), nfe (55) e nfse.
class FiscalRepository {
  /// Lista notas por tipo (55 = NFe, 65 = NFCe, NFSe = Servicos)
  Future<List<NotaFiscal>> getAll(
    String organizationId, {
    required String tipoModelo, // '55', '65' ou 'nfse'
    int page = 0,
    String? status,
  }) async {
    final table = _getTableName(tipoModelo);
    // Para simplificacao da view tipamos todas saídas parecidas na UI.
    var query = supabase
        .from(table)
        .select()
        .eq('organization_id', organizationId);

    if (status != null && status.isNotEmpty && status != 'todos') {
      query = query.eq('status', status);
    }

    final offset = page * AppConstants.defaultPageSize;
    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + AppConstants.defaultPageSize - 1);

    return (response as List)
        .map(
          (json) =>
              NotaFiscal.fromJson(json as Map<String, dynamic>, tipoModelo),
        )
        .toList();
  }

  /// Retorna os nomes das tabelas exatas conforme back-end (Supabase Web)
  String _getTableName(String modelo) {
    if (modelo == '55') return 'notas_fiscais';
    if (modelo == 'nfse') return 'nfse';
    return 'nfce';
  }
}

final fiscalRepositoryProvider = Provider<FiscalRepository>(
  (ref) => FiscalRepository(),
);
