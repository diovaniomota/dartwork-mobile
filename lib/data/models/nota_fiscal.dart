/// Modelo Unificado Base de Notsa Fiscais para visualização no App Mobile
class NotaFiscal {
  final String id;
  final String organizationId;
  final String tipoModelo; // '55', '65', 'nfse'
  final String? status;
  final int? numero;
  final int? serie;
  final DateTime? dataEmissao;
  final double valorTotal;
  final String? clienteNome;
  final String? clienteDocumento;
  final String? nfeRef;

  const NotaFiscal({
    required this.id,
    required this.organizationId,
    required this.tipoModelo,
    this.status,
    this.numero,
    this.serie,
    this.dataEmissao,
    this.valorTotal = 0.0,
    this.clienteNome,
    this.clienteDocumento,
    this.nfeRef,
  });

  factory NotaFiscal.fromJson(Map<String, dynamic> json, String mModelo) {
    return NotaFiscal(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString() ?? '',
      tipoModelo: mModelo,
      status: json['status']?.toString(),
      numero: json['numero'] != null
          ? int.tryParse(json['numero'].toString())
          : null,
      serie: json['serie'] != null
          ? int.tryParse(json['serie'].toString())
          : null,
      valorTotal: _toDouble(json['valor_total'] ?? json['valor_servicos']),
      clienteNome:
          json['cliente_nome']?.toString() ?? json['tomador_nome']?.toString(),
      clienteDocumento:
          json['cliente_documento']?.toString() ??
          json['tomador_cnpj']?.toString(),
      nfeRef: json['nfe_ref']?.toString() ?? json['ref']?.toString(),
      dataEmissao: json['data_emissao'] != null
          ? DateTime.tryParse(json['data_emissao'].toString())
          : (json['created_at'] != null
                ? DateTime.tryParse(json['created_at'].toString())
                : null),
    );
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}
