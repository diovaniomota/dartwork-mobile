/// Model de Veículo — alinhado com a tabela `vehicles` do Supabase.
/// Colunas do DB: id, client_id, placa, renavam, marca, modelo, cor, ano, observacoes, organization_id
class Vehicle {
  final String id;
  final String organizationId;
  final String? clientId;
  final String plate; // coluna `placa`
  final String? renavam;
  final String? brand; // coluna `marca`
  final String? model; // coluna `modelo`
  final String? year; // coluna `ano`
  final String? color; // coluna `cor`
  final String? notes; // coluna `observacoes`
  final DateTime? createdAt;

  const Vehicle({
    required this.id,
    required this.organizationId,
    this.clientId,
    required this.plate,
    this.renavam,
    this.brand,
    this.model,
    this.year,
    this.color,
    this.notes,
    this.createdAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id']?.toString() ?? '',
        organizationId: json['organization_id']?.toString() ?? '',
        clientId: json['client_id']?.toString(),
        plate: json['placa']?.toString() ?? json['plate']?.toString() ?? '',
        renavam: json['renavam']?.toString(),
        brand: json['marca']?.toString() ?? json['brand']?.toString(),
        model: json['modelo']?.toString() ?? json['model']?.toString(),
        year: json['ano']?.toString() ?? json['year']?.toString(),
        color: json['cor']?.toString() ?? json['color']?.toString(),
        notes: json['observacoes']?.toString() ?? json['notes']?.toString(),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );

  /// toJson usa nomes de colunas do DB (português) para compatibilidade com web
  Map<String, dynamic> toJson() => {
        'organization_id': organizationId,
        'client_id': clientId,
        'placa': plate,
        'renavam': renavam,
        'marca': brand,
        'modelo': model,
        'ano': year,
        'cor': color,
        'observacoes': notes,
      };

  String get displayName {
    final parts = <String>[];
    if (brand != null && brand!.isNotEmpty) parts.add(brand!);
    if (model != null && model!.isNotEmpty) parts.add(model!);
    if (parts.isEmpty) return plate;
    return '${parts.join(' ')} - $plate';
  }
}
