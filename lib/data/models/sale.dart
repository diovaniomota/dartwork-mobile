// Item individual de uma venda ou pedido
class SaleItem {
  final String? id;
  final String saleId;
  final String productId;
  final double quantity;
  final double unitPrice;
  final double total;
  final String? productName;

  const SaleItem({
    this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.productName,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
    id: json['id']?.toString(),
    saleId: json['sale_id']?.toString() ?? '',
    productId: json['product_id']?.toString() ?? '',
    quantity: double.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
    unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0,
    total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
    productName:
        json['products']?['name']?.toString() ??
        json['product_name']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'sale_id': saleId,
    'product_id': productId,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total': total,
  };
}

// Entidade Pai: Venda / Pedido / Orçamento
class Sale {
  final String id;
  final String organizationId;
  final String? clientId;
  final String? sellerId; // Vendedor
  final String? transporterId; // Transportadora
  final DateTime date;
  final String status; // 'pending', 'completed', 'cancelled', 'budget'
  final double subtotal;
  final double discount;
  final double total;
  final String? notes;
  final String? paymentMethod;

  // Virtual Fields
  final String? clientName;
  final String? sellerName;
  final List<SaleItem>? items;

  const Sale({
    required this.id,
    required this.organizationId,
    this.clientId,
    this.sellerId,
    this.transporterId,
    required this.date,
    required this.status,
    this.subtotal = 0,
    this.discount = 0,
    this.total = 0,
    this.notes,
    this.paymentMethod,
    this.clientName,
    this.sellerName,
    this.items,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    List<SaleItem>? initialItems;
    if (json['sale_items'] != null) {
      initialItems = (json['sale_items'] as List)
          .map((i) => SaleItem.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return Sale(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString() ?? '',
      clientId: json['client_id']?.toString(),
      sellerId: json['seller_id']?.toString(),
      transporterId: json['transporter_id']?.toString(),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? 'pending',
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      notes: json['notes']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      clientName: json['clients']?['name']?.toString(),
      sellerName: json['users']?['name']
          ?.toString(), // Tabela supabase auth fallback
      items: initialItems,
    );
  }

  Map<String, dynamic> toJson() => {
    'organization_id': organizationId,
    'client_id': clientId,
    'seller_id': sellerId,
    'transporter_id': transporterId,
    'created_at': date.toIso8601String(),
    'status': status,
    'subtotal': subtotal,
    'discount': discount,
    'total': total,
    'notes': notes,
    'payment_method': paymentMethod,
  };
}
