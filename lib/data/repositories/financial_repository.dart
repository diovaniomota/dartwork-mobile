import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/financial_entry.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/constants/app_constants.dart';

class FinancialRepository {
  Future<List<FinancialEntry>> getAll(
    String organizationId, {
    int page = 0,
    String? search,
    String? type, // 'receivable' ou 'payable'
    String? status, // Filtro por pendente/pago
  }) async {
    final tableName = type == 'receivable'
        ? 'finance_receivables'
        : 'finance_payables';

    // Selecionamos apenas o relacionamento que existe para cada tipo de tabela
    final selectStr = type == 'receivable'
        ? '*, clients(name)'
        : '*, suppliers(name)';

    var query = supabase
        .from(tableName)
        .select(selectStr)
        .eq('organization_id', organizationId);

    if (status != null && status.isNotEmpty && status != 'all') {
      if (status == 'overdue') {
        final tz = DateTime.now().toIso8601String().split('T')[0];
        query = query.eq('status', 'pending').lt('due_date', tz);
      } else {
        query = query.eq('status', status);
      }
    }

    if (search != null && search.trim().isNotEmpty) {
      final s = search.trim();
      query = query.ilike('description', '%$s%');
    }

    final offset = page * AppConstants.defaultPageSize;
    final response = await query
        .order('due_date', ascending: true)
        .range(offset, offset + AppConstants.defaultPageSize - 1);

    return (response as List)
        .map((json) => FinancialEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<FinancialEntry?> getById(String id, {required String type}) async {
    final tableName = type == 'receivable'
        ? 'finance_receivables'
        : 'finance_payables';

    final selectStr = type == 'receivable'
        ? '*, clients(name)'
        : '*, suppliers(name)';

    final response = await supabase
        .from(tableName)
        .select(selectStr)
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return FinancialEntry.fromJson(response);
  }

  Future<FinancialEntry> create(
    Map<String, dynamic> data, {
    required String type,
  }) async {
    final tableName = type == 'receivable'
        ? 'finance_receivables'
        : 'finance_payables';

    final response = await supabase
        .from(tableName)
        .insert(data)
        .select()
        .single();
    return FinancialEntry.fromJson(response);
  }

  Future<void> update(
    String id,
    Map<String, dynamic> data, {
    required String type,
  }) async {
    final tableName = type == 'receivable'
        ? 'finance_receivables'
        : 'finance_payables';
    await supabase.from(tableName).update(data).eq('id', id);
  }

  Future<void> delete(String id, {required String type}) async {
    final tableName = type == 'receivable'
        ? 'finance_receivables'
        : 'finance_payables';
    await supabase.from(tableName).delete().eq('id', id);
  }
}

final financialRepositoryProvider = Provider((ref) => FinancialRepository());
