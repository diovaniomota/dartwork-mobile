/// Model de Venda PDV — alinhado com tabela `sales` do Supabase.
class PdvSale {
  final String id;
  final String? organizationId;
  final String? cashRegisterId;
  final String? clientId;
  final String? clientName;
  final double subtotal;
  final double discount;
  final double total;
  final String? paymentMethod;
  final int? installments;
  final double? cashReceived;
  final double? changeAmount;
  final String? sellerName;
  final String? notes;
  final String status;
  final List<SaleItem> items;
  final DateTime? createdAt;

  const PdvSale({
    required this.id,
    this.organizationId,
    this.cashRegisterId,
    this.clientId,
    this.clientName,
    this.subtotal = 0,
    this.discount = 0,
    this.total = 0,
    this.paymentMethod,
    this.installments,
    this.cashReceived,
    this.changeAmount,
    this.sellerName,
    this.notes,
    this.status = 'completed',
    this.items = const [],
    this.createdAt,
  });

  /// Alias para compatibilidade
  double get totalValue => total;

  factory PdvSale.fromJson(Map<String, dynamic> json) {
    final itemsList =
        (json['sale_items'] as List?)
            ?.map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return PdvSale(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString(),
      cashRegisterId: json['cash_register_id']?.toString(),
      clientId: json['client_id']?.toString(),
      clientName: json['client_name']?.toString(),
      subtotal: _toDouble(json['subtotal']),
      discount: _toDouble(json['discount']),
      total: _toDouble(json['total']),
      paymentMethod: json['payment_method']?.toString(),
      installments: json['installments'] is int ? json['installments'] : null,
      cashReceived: json['cash_received'] != null
          ? _toDouble(json['cash_received'])
          : null,
      changeAmount: json['change_amount'] != null
          ? _toDouble(json['change_amount'])
          : null,
      sellerName: json['seller_name']?.toString(),
      notes: json['notes']?.toString(),
      status: json['status']?.toString() ?? 'completed',
      items: itemsList,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }
}

/// Item de venda — tabela `sale_items`.
class SaleItem {
  final String? id;
  final String? productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double discount;
  final double subtotal;
  final String? notes;

  const SaleItem({
    this.id,
    this.productId,
    required this.productName,
    this.quantity = 1,
    this.unitPrice = 0,
    this.discount = 0,
    this.subtotal = 0,
    this.notes,
  });

  /// Aliases para compatibilidade
  String get name => productName;
  double get totalPrice => subtotal;

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
    id: json['id']?.toString(),
    productId: json['product_id']?.toString(),
    productName: json['product_name']?.toString() ?? '',
    quantity: _toDouble(json['quantity']),
    unitPrice: _toDouble(json['unit_price']),
    discount: _toDouble(json['discount']),
    subtotal: _toDouble(json['subtotal']),
    notes: json['notes']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'product_name': productName,
    'quantity': quantity,
    'unit_price': unitPrice,
    'discount': discount,
    'subtotal': subtotal,
    'notes': notes,
  };

  static double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }
}
