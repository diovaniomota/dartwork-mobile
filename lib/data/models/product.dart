/// Model de Produto — alinhado com a tabela `products` do Supabase.
/// Contém todos os campos fiscais do formulário web para paridade total.
class Product {
  final String id;
  final String organizationId;
  final String name;
  final String? brand;
  final String? sku;
  final String? gtin;
  final String? gtinTributavel;
  final String? category;
  final String? descricaoReduzida;
  final double price;
  final double costPrice;
  final int stock;
  final int minStock;
  final String? unidade;
  final String? unidadeTributavel;

  // Dados Fiscais
  final String? ncm;
  final String? cest;
  final int origem; // 0=Nacional, 1-8=Importação
  final double pesoBruto;
  final double pesoLiquido;
  final String? cfopInterno; // CFOP interno (5102)
  final String? cfopExterno; // CFOP externo (6102)
  final String? cfopDentro; // alias para cfop_interno
  final String? cfopFora; // alias para cfop_externo

  // Tributação
  final String? situacaoTributaria;
  final String? cstIcms;
  final String? csosn;
  final double? aliqIcms;
  final double? reducaoBc;
  final String? cstIpi;
  final double? aliqIpi;
  final String? cstPis;
  final double? aliqPis;
  final String? cstCofins;
  final double? aliqCofins;

  final DateTime? createdAt;

  const Product({
    required this.id,
    required this.organizationId,
    required this.name,
    this.brand,
    this.sku,
    this.gtin,
    this.gtinTributavel,
    this.category,
    this.descricaoReduzida,
    this.price = 0,
    this.costPrice = 0,
    this.stock = 0,
    this.minStock = 0,
    this.unidade,
    this.unidadeTributavel,
    this.ncm,
    this.cest,
    this.origem = 0,
    this.pesoBruto = 0,
    this.pesoLiquido = 0,
    this.cfopInterno,
    this.cfopExterno,
    this.cfopDentro,
    this.cfopFora,
    this.situacaoTributaria,
    this.cstIcms,
    this.csosn,
    this.aliqIcms,
    this.reducaoBc,
    this.cstIpi,
    this.aliqIpi,
    this.cstPis,
    this.aliqPis,
    this.cstCofins,
    this.aliqCofins,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id']?.toString() ?? '',
    organizationId: json['organization_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    brand: json['brand']?.toString(),
    sku: json['sku']?.toString(),
    gtin: json['gtin']?.toString(),
    gtinTributavel: json['gtin_tributavel']?.toString(),
    category: json['category']?.toString(),
    descricaoReduzida: json['descricao_reduzida']?.toString(),
    price: _toDouble(json['price']),
    costPrice: _toDouble(json['cost_price']),
    stock: _toInt(json['stock']),
    minStock: _toInt(json['min_stock']),
    unidade: json['unidade']?.toString(),
    unidadeTributavel: json['unidade_tributavel']?.toString(),
    ncm: json['ncm']?.toString(),
    cest: json['cest']?.toString(),
    origem: _toInt(json['origem']),
    pesoBruto: _toDouble(json['peso_bruto']),
    pesoLiquido: _toDouble(json['peso_liquido']),
    cfopInterno: json['cfop_interno']?.toString(),
    cfopExterno: json['cfop_externo']?.toString(),
    cfopDentro: json['cfop_dentro']?.toString(),
    cfopFora: json['cfop_fora']?.toString(),
    situacaoTributaria: json['situacao_tributaria']?.toString(),
    cstIcms: json['cst_icms']?.toString(),
    csosn: json['csosn']?.toString(),
    aliqIcms: _toNullableDouble(json['aliq_icms']),
    reducaoBc: _toNullableDouble(json['reducao_bc']),
    cstIpi: json['cst_ipi']?.toString(),
    aliqIpi: _toNullableDouble(json['aliq_ipi']),
    cstPis: json['cst_pis']?.toString(),
    aliqPis: _toNullableDouble(json['aliq_pis']),
    cstCofins: json['cst_cofins']?.toString(),
    aliqCofins: _toNullableDouble(json['aliq_cofins']),
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null,
  );

  Map<String, dynamic> toJson() => {
    'organization_id': organizationId,
    'name': name,
    'brand': brand,
    'sku': sku,
    'gtin': gtin,
    'gtin_tributavel': gtinTributavel,
    'category': category,
    'descricao_reduzida': descricaoReduzida,
    'price': price,
    'cost_price': costPrice,
    'stock': stock,
    'min_stock': minStock,
    'unidade': unidade,
    'unidade_tributavel': unidadeTributavel,
    'ncm': ncm,
    'cest': cest,
    'origem': origem,
    'peso_bruto': pesoBruto,
    'peso_liquido': pesoLiquido,
    'cfop_interno': cfopInterno,
    'cfop_externo': cfopExterno,
    'cfop_dentro': cfopDentro ?? cfopInterno,
    'cfop_fora': cfopFora ?? cfopExterno,
    'situacao_tributaria': situacaoTributaria,
    'cst_icms': cstIcms,
    'csosn': csosn,
    'aliq_icms': aliqIcms,
    'reducao_bc': reducaoBc,
    'cst_ipi': cstIpi,
    'aliq_ipi': aliqIpi,
    'cst_pis': cstPis,
    'aliq_pis': aliqPis,
    'cst_cofins': cstCofins,
    'aliq_cofins': aliqCofins,
  };

  /// Verifica se é serviço baseado na unidade
  bool get isService => unidade == 'SV' || unidade == 'HR';

  static double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }

  static double? _toNullableDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString());
  }

  static int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }
}
