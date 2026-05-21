import '../models/cash_register.dart';
import '../../core/constants/supabase_constants.dart';

/// Repositório de caixa — alinhado com tabelas reais do Supabase.
class CashRegisterRepository {
  /// Busca caixa aberto da organização.
  Future<CashRegister?> getOpenRegister(String organizationId) async {
    final response = await supabase
        .from('cash_registers')
        .select()
        .eq('organization_id', organizationId)
        .eq('status', 'open')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return CashRegister.fromJson(response);
  }

  /// Abre um novo caixa.
  Future<CashRegister> openRegister(
    String organizationId,
    double openingBalance, {
    String? userId,
    String? userName,
    String? notes,
  }) async {
    final data = {
      'organization_id': organizationId,
      'operator_name': userName ?? 'Operador',
      'initial_balance': openingBalance,
      'status': 'open',
      'notes': notes,
    };

    // Só envia operator_id se for um UUID válido/preenchido e não 'null' em string
    if (userId != null && userId.isNotEmpty && userId.length == 36) {
      data['operator_id'] = userId;
    }

    final response = await supabase
        .from('cash_registers')
        .insert(data)
        .select()
        .single();

    return CashRegister.fromJson(response);
  }

  /// Fecha o caixa.
  Future<void> closeRegister(String id, double closingBalance) async {
    await supabase
        .from('cash_registers')
        .update({
          'final_balance': closingBalance,
          'status': 'closed',
          'closed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  /// Lista movimentações do caixa (tabela `cash_movements`).
  Future<List<CaixaMovement>> getMovements(
    String organizationId, {
    String? cashRegisterId,
  }) async {
    var query = supabase
        .from('cash_movements')
        .select()
        .eq('organization_id', organizationId);

    if (cashRegisterId != null) {
      query = query.eq('cash_register_id', cashRegisterId);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List)
        .map((json) => CaixaMovement.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Adiciona movimentação ao caixa.
  Future<void> addMovement(Map<String, dynamic> data) async {
    await supabase.from('cash_movements').insert(data);
  }
}
