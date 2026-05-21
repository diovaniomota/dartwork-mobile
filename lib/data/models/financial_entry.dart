/// Model unificado de Lançamento Financeiro (`financial_entries`)
/// Abrange Contas a Pagar e Contas a Receber.
class FinancialEntry {
  final String id;
  final String organizationId;
  final String description;
  final String type; // 'receivable' ou 'payable'
  final double amount;
  final DateTime dueDate;
  final String status; // 'pending', 'paid', 'overdue', 'cancelled'
  final DateTime? paymentDate;
  final String? paymentMethod;
  final String? notes;

  // Relações opcionais comuns
  final String? clientId;
  final String? supplierId;
  final String? categoryId;
  final String? accountId;

  // Nomes agregados para UI
  final String? clientName;
  final String? supplierName;

  const FinancialEntry({
    required this.id,
    required this.organizationId,
    required this.description,
    required this.type,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paymentDate,
    this.paymentMethod,
    this.notes,
    this.clientId,
    this.supplierId,
    this.categoryId,
    this.accountId,
    this.clientName,
    this.supplierName,
  });

  factory FinancialEntry.fromJson(Map<String, dynamic> json) => FinancialEntry(
    id: json['id']?.toString() ?? '',
    organizationId: json['organization_id']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    type: json['type']?.toString() ?? 'receivable',
    amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
    dueDate:
        DateTime.tryParse(json['due_date']?.toString() ?? '') ?? DateTime.now(),
    status: json['status']?.toString() ?? 'pending',
    paymentDate: json['payment_date'] != null
        ? DateTime.tryParse(json['payment_date'].toString())
        : null,
    paymentMethod: json['payment_method']?.toString(),
    notes: json['notes']?.toString(),
    clientId: json['client_id']?.toString(),
    supplierId: json['supplier_id']?.toString(),
    categoryId: json['category_id']?.toString(),
    accountId: json['account_id']?.toString(),
    // Agregações de View / Join
    clientName:
        json['clients']?['name']?.toString() ?? json['client_name']?.toString(),
    supplierName:
        json['suppliers']?['name']?.toString() ??
        json['supplier_name']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'organization_id': organizationId,
    'description': description,
    'type': type,
    'amount': amount,
    'due_date': dueDate.toIso8601String().split('T')[0],
    'status': status,
    'payment_date': paymentDate?.toIso8601String().split('T')[0],
    'payment_method': paymentMethod,
    'notes': notes,
    'client_id': clientId,
    'supplier_id': supplierId,
    'category_id': categoryId,
    'account_id': accountId,
  };
}
