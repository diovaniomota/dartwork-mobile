class Purchase {
  final String id;
  final String? organizationId;
  final String? numero;
  final String? serie;
  final String? fornecedorNome;
  final DateTime? dataEmissao;
  final DateTime? dataEntrada;
  final double valorTotal;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Purchase({
    required this.id,
    this.organizationId,
    this.numero,
    this.serie,
    this.fornecedorNome,
    this.dataEmissao,
    this.dataEntrada,
    this.valorTotal = 0.0,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String?,
      numero: json['numero'] as String?,
      serie: json['serie'] as String?,
      fornecedorNome: json['fornecedor_nome'] as String?,
      dataEmissao: json['data_emissao'] != null
          ? DateTime.tryParse(json['data_emissao'] as String)
          : null,
      dataEntrada: json['data_entrada'] != null
          ? DateTime.tryParse(json['data_entrada'] as String)
          : null,
      valorTotal: (json['valor_total'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'em_digitacao',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (organizationId != null) 'organization_id': organizationId,
      if (numero != null) 'numero': numero,
      if (serie != null) 'serie': serie,
      if (fornecedorNome != null) 'fornecedor_nome': fornecedorNome,
      if (dataEmissao != null) 'data_emissao': dataEmissao!.toIso8601String(),
      if (dataEntrada != null) 'data_entrada': dataEntrada!.toIso8601String(),
      'valor_total': valorTotal,
      'status': status,
    };
  }

  Purchase copyWith({
    String? id,
    String? organizationId,
    String? numero,
    String? serie,
    String? fornecedorNome,
    DateTime? dataEmissao,
    DateTime? dataEntrada,
    double? valorTotal,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Purchase(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      numero: numero ?? this.numero,
      serie: serie ?? this.serie,
      fornecedorNome: fornecedorNome ?? this.fornecedorNome,
      dataEmissao: dataEmissao ?? this.dataEmissao,
      dataEntrada: dataEntrada ?? this.dataEntrada,
      valorTotal: valorTotal ?? this.valorTotal,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
