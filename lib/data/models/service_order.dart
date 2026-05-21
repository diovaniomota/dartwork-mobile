/// Model de Ordem de Serviço — alinhado com tabela `ordens_servico` real.
class ServiceOrder {
  final String id;
  final String organizationId;
  final String? clientId;
  final String? clientName;
  final String? vehicleId;
  final String? veiculoPlaca;
  final String? veiculoModelo;
  final String status;
  final String? descricaoProblema;
  final String? diagnostico;
  final String? observacoes;
  final String? tecnicoResponsavel;
  final int? valorTotalCentavos;
  final int? kmEntrada;
  final int? kmSaida;
  final String? tanqueNivel;
  final List<OsItem> itens;
  final DateTime? dataAbertura;
  final DateTime? dataPrevisao;
  final DateTime? dataFechamento;
  final String? approvalStatus;
  final String? approvalToken;
  final DateTime? approvalRequestedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ServiceOrder({
    required this.id,
    required this.organizationId,
    this.clientId,
    this.clientName,
    this.vehicleId,
    this.veiculoPlaca,
    this.veiculoModelo,
    this.status = 'aberta',
    this.descricaoProblema,
    this.diagnostico,
    this.observacoes,
    this.tecnicoResponsavel,
    this.valorTotalCentavos,
    this.kmEntrada,
    this.kmSaida,
    this.tanqueNivel,
    this.itens = const [],
    this.dataAbertura,
    this.dataPrevisao,
    this.dataFechamento,
    this.approvalStatus,
    this.approvalToken,
    this.approvalRequestedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Valor em reais (centavos / 100)
  double get totalValue =>
      valorTotalCentavos != null ? valorTotalCentavos! / 100.0 : 0;

  /// Aliases para compatibilidade com telas existentes
  String? get description => descricaoProblema;
  String? get notes => observacoes;
  String? get vehiclePlate => veiculoPlaca;
  String? get vehicleModel => veiculoModelo;

  factory ServiceOrder.fromJson(Map<String, dynamic> json) {
    // Itens da OS (tabela os_itens)
    final itensList =
        (json['os_itens'] as List?)
            ?.map((e) => OsItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Dados aninhados do cliente/veículo
    final clientData = json['clients'] as Map<String, dynamic>?;
    final vehicleData = json['vehicles'] as Map<String, dynamic>?;
    final rawClientType = clientData?['tipo_pessoa']?.toString();
    final rawClientFantasy = clientData?['fantasy_name']?.toString();
    final rawClientName = clientData?['name']?.toString();
    final hasFantasy =
        rawClientFantasy != null && rawClientFantasy.trim().isNotEmpty;
    final displayClientName = (rawClientType == 'J' && hasFantasy)
        ? rawClientFantasy.trim()
        : rawClientName;

    return ServiceOrder(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString() ?? '',
      clientId: json['client_id']?.toString(),
      clientName: displayClientName,
      vehicleId: json['vehicle_id']?.toString(),
      veiculoPlaca:
          vehicleData?['plate']?.toString() ??
          json['veiculo_placa']?.toString(),
      veiculoModelo:
          vehicleData?['model']?.toString() ??
          json['veiculo_modelo']?.toString(),
      status: json['status']?.toString() ?? 'aberta',
      descricaoProblema: json['descricao_problema']?.toString(),
      diagnostico: json['diagnostico']?.toString(),
      observacoes: json['observacoes']?.toString(),
      tecnicoResponsavel: json['tecnico_responsavel']?.toString(),
      valorTotalCentavos: _toInt(json['valor_total_centavos']),
      kmEntrada: _toInt(json['km_entrada']),
      kmSaida: _toInt(json['km_saida']),
      tanqueNivel: json['tanque_nivel']?.toString(),
      itens: itensList,
      dataAbertura: _parseDate(json['data_abertura']),
      dataPrevisao: _parseDate(json['data_previsao']),
      dataFechamento: _parseDate(json['data_fechamento']),
      approvalStatus: json['approval_status']?.toString(),
      approvalToken: json['approval_token']?.toString(),
      approvalRequestedAt: _parseDate(json['approval_requested_at']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'organization_id': organizationId,
    'client_id': clientId,
    'vehicle_id': vehicleId,
    'status': status,
    'descricao_problema': descricaoProblema,
    'diagnostico': diagnostico,
    'observacoes': observacoes,
    'tecnico_responsavel': tecnicoResponsavel,
    'valor_total_centavos': valorTotalCentavos,
    'km_entrada': kmEntrada,
    'km_saida': kmSaida,
    'tanque_nivel': tanqueNivel,
  };

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'aberta':
        return 'Aberta';
      case 'em_andamento':
        return 'Em Andamento';
      case 'finalizada':
        return 'Finalizada';
      case 'cancelada':
        return 'Cancelada';
      default:
        return status;
    }
  }

  static int? _toInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString());
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    return DateTime.tryParse(val.toString());
  }
}

/// Item da OS — tabela `os_itens`.
class OsItem {
  final String? id;
  final String? produtoId;
  final String tipo; // 'servico' ou 'produto'
  final String descricao;
  final int quantidade;
  final int valorUnitarioCentavos;
  final int valorTotalCentavos;
  final DateTime? createdAt;

  const OsItem({
    this.id,
    this.produtoId,
    required this.tipo,
    required this.descricao,
    this.quantidade = 1,
    this.valorUnitarioCentavos = 0,
    this.valorTotalCentavos = 0,
    this.createdAt,
  });

  /// Aliases para exibição
  String get name => descricao;
  double get unitPrice => valorUnitarioCentavos / 100.0;
  double get totalPrice => valorTotalCentavos / 100.0;

  factory OsItem.fromJson(Map<String, dynamic> json) => OsItem(
    id: json['id']?.toString(),
    produtoId: json['produto_id']?.toString(),
    tipo: json['tipo']?.toString() ?? 'servico',
    descricao: json['descricao']?.toString() ?? '',
    quantidade: _toInt(json['quantidade']),
    valorUnitarioCentavos: _toInt(json['valor_unitario_centavos']),
    valorTotalCentavos: _toInt(json['valor_total_centavos']),
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null,
  );

  Map<String, dynamic> toJson() => {
    'produto_id': produtoId,
    'tipo': tipo,
    'descricao': descricao,
    'quantidade': quantidade,
    'valor_unitario_centavos': valorUnitarioCentavos,
    'valor_total_centavos': valorTotalCentavos,
  };

  static int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }
}
