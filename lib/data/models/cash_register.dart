/// Model de Caixa — alinhado com a tabela `cash_registers` do Supabase.
class CashRegister {
  final String id;
  final String organizationId;
  final String? operatorId;
  final String? operatorName;
  final double openingBalance;
  final double? closingBalance;
  final String status; // 'open' ou 'closed'
  final DateTime? openedAt;
  final DateTime? closedAt;
  final String? notes;

  const CashRegister({
    required this.id,
    required this.organizationId,
    this.operatorId,
    this.operatorName,
    this.openingBalance = 0,
    this.closingBalance,
    this.status = 'open',
    this.openedAt,
    this.closedAt,
    this.notes,
  });

  factory CashRegister.fromJson(Map<String, dynamic> json) => CashRegister(
    id: json['id']?.toString() ?? '',
    organizationId: json['organization_id']?.toString() ?? '',
    operatorId: json['operator_id']?.toString(),
    operatorName: json['operator_name']?.toString(),
    openingBalance: _toDouble(json['initial_balance']),
    closingBalance: json['final_balance'] != null
        ? _toDouble(json['final_balance'])
        : null,
    status: json['status']?.toString() ?? 'open',
    openedAt: json['opened_at'] != null
        ? DateTime.tryParse(json['opened_at'].toString())
        : json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null,
    closedAt: json['closed_at'] != null
        ? DateTime.tryParse(json['closed_at'].toString())
        : null,
    notes: json['notes']?.toString(),
  );

  bool get isOpen => status == 'open';

  static double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }
}

/// Model de Movimentação — alinhado com a tabela `cash_movements` do Supabase.
/// Tipos reais: 'sale', 'deposit', 'withdrawal', 'correction'
class CaixaMovement {
  final String id;
  final String? organizationId;
  final String? cashRegisterId;
  final String type; // sale, deposit, withdrawal, correction
  final double amount;
  final String? description;
  final DateTime? createdAt;

  const CaixaMovement({
    required this.id,
    this.organizationId,
    this.cashRegisterId,
    required this.type,
    required this.amount,
    this.description,
    this.createdAt,
  });

  factory CaixaMovement.fromJson(Map<String, dynamic> json) => CaixaMovement(
    id: json['id']?.toString() ?? '',
    organizationId: json['organization_id']?.toString(),
    cashRegisterId: json['cash_register_id']?.toString(),
    type: json['type']?.toString() ?? 'sale',
    amount: _toDouble(json['amount']),
    description: json['description']?.toString(),
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null,
  );

  /// Entrada = sale ou deposit; Saída = withdrawal ou correction
  bool get isEntrada => type == 'sale' || type == 'deposit';

  static double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }
}
