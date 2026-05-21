/// Model de Cliente — alinhado com a tabela `clients` do Supabase.
/// Contém todos os campos do formulário web para paridade total.
class ClientModel {
  final String id;
  final String organizationId;
  final String name;
  final String? code;
  final String? fantasyName;
  final String? document; // CPF/CNPJ
  final String? tipoPessoa; // 'F' ou 'J'
  final String? status; // 'ativo', 'inativo', 'bloqueado'

  // Dados Fiscais
  final String? taxRegime;
  final String? ieIndicator;
  final String? ie; // Inscrição Estadual
  final bool? ieExempt;
  final String? im; // Inscrição Municipal
  final String? rg;
  final String? rgEmissor;
  final bool? isPublicOrg;
  final String? suframa;
  final bool? consumidorFinal;
  final String? codPais;

  // Endereço Principal
  final String? cep;
  final String? uf;
  final String? city;
  final String? neighborhood;
  final String? address;
  final String? number;
  final String? complement;
  final String? codMunicipio;

  // Endereço de Cobrança
  final String? billingCep;
  final String? billingUf;
  final String? billingCity;
  final String? billingNeighborhood;
  final String? billingAddress;
  final String? billingNumber;
  final String? billingComplement;

  // Contato
  final String? email;
  final String? nfeEmail;
  final String? phone;
  final String? mobile;
  final String? fax;
  final String? carrier;
  final String? website;
  final String? contactInfo;
  final String? contactPeople;
  final String? contactType;

  // Dados Adicionais (Pessoa Física)
  final String? civilStatus;
  final String? profession;
  final String? gender;
  final String? birthDate;
  final String? birthplace;
  final String? fatherName;
  final String? fatherCpf;
  final String? motherName;
  final String? motherCpf;

  // Comercial
  final String? clientSince;
  final String? nextVisit;
  final String? situation;
  final String? seller;
  final String? defaultOperation;
  final String? creditLimitType;
  final double? creditLimit;
  final String? paymentCondition;
  final String? category;

  // Observações
  final String? notes;

  final DateTime? createdAt;

  const ClientModel({
    required this.id,
    required this.organizationId,
    required this.name,
    this.code,
    this.fantasyName,
    this.document,
    this.tipoPessoa,
    this.status,
    this.taxRegime,
    this.ieIndicator,
    this.ie,
    this.ieExempt,
    this.im,
    this.rg,
    this.rgEmissor,
    this.isPublicOrg,
    this.suframa,
    this.consumidorFinal,
    this.codPais,
    this.cep,
    this.uf,
    this.city,
    this.neighborhood,
    this.address,
    this.number,
    this.complement,
    this.codMunicipio,
    this.billingCep,
    this.billingUf,
    this.billingCity,
    this.billingNeighborhood,
    this.billingAddress,
    this.billingNumber,
    this.billingComplement,
    this.email,
    this.nfeEmail,
    this.phone,
    this.mobile,
    this.fax,
    this.carrier,
    this.website,
    this.contactInfo,
    this.contactPeople,
    this.contactType,
    this.civilStatus,
    this.profession,
    this.gender,
    this.birthDate,
    this.birthplace,
    this.fatherName,
    this.fatherCpf,
    this.motherName,
    this.motherCpf,
    this.clientSince,
    this.nextVisit,
    this.situation,
    this.seller,
    this.defaultOperation,
    this.creditLimitType,
    this.creditLimit,
    this.paymentCondition,
    this.category,
    this.notes,
    this.createdAt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) => ClientModel(
    id: json['id']?.toString() ?? '',
    organizationId: json['organization_id']?.toString() ?? '',
    name:
        json['name']?.toString() ??
        json['razao_social']?.toString() ??
        json['nome_fantasia']?.toString() ??
        '',
    code: json['code']?.toString(),
    fantasyName:
        json['fantasy_name']?.toString() ?? json['nome_fantasia']?.toString(),
    document: json['document']?.toString(),
    tipoPessoa: json['tipo_pessoa']?.toString(),
    status: json['status']?.toString(),
    taxRegime: json['tax_regime']?.toString(),
    ieIndicator: json['ie_indicator']?.toString(),
    ie: json['ie']?.toString(),
    ieExempt: json['ie_exempt'] is bool ? json['ie_exempt'] : null,
    im: json['im']?.toString(),
    rg: json['rg']?.toString(),
    rgEmissor: json['rg_emissor']?.toString(),
    isPublicOrg: json['is_public_org'] is bool ? json['is_public_org'] : null,
    suframa: json['suframa']?.toString(),
    consumidorFinal: json['consumidor_final'] is bool
        ? json['consumidor_final']
        : null,
    codPais: json['cod_pais']?.toString(),
    cep: json['cep']?.toString(),
    uf: json['uf']?.toString(),
    city: json['city']?.toString(),
    neighborhood: json['neighborhood']?.toString(),
    address: json['address']?.toString(),
    number: json['number']?.toString(),
    complement: json['complement']?.toString(),
    codMunicipio: json['cod_municipio']?.toString(),
    billingCep: json['billing_cep']?.toString(),
    billingUf: json['billing_uf']?.toString(),
    billingCity: json['billing_city']?.toString(),
    billingNeighborhood: json['billing_neighborhood']?.toString(),
    billingAddress: json['billing_address']?.toString(),
    billingNumber: json['billing_number']?.toString(),
    billingComplement: json['billing_complement']?.toString(),
    email: json['email']?.toString(),
    nfeEmail: json['nfe_email']?.toString(),
    phone: json['phone']?.toString(),
    mobile: json['mobile']?.toString(),
    fax: json['fax']?.toString(),
    carrier: json['carrier']?.toString(),
    website: json['website']?.toString(),
    contactInfo: json['contact_info']?.toString(),
    contactPeople: json['contact_people']?.toString(),
    contactType: json['contact_type']?.toString(),
    civilStatus: json['civil_status']?.toString(),
    profession: json['profession']?.toString(),
    gender: json['gender']?.toString(),
    birthDate: json['birth_date']?.toString(),
    birthplace: json['birthplace']?.toString(),
    fatherName: json['father_name']?.toString(),
    fatherCpf: json['father_cpf']?.toString(),
    motherName: json['mother_name']?.toString(),
    motherCpf: json['mother_cpf']?.toString(),
    clientSince: json['client_since']?.toString(),
    nextVisit: json['next_visit']?.toString(),
    situation: json['situation']?.toString(),
    seller: json['seller']?.toString(),
    defaultOperation: json['default_operation']?.toString(),
    creditLimitType: json['credit_limit_type']?.toString(),
    creditLimit: _toDouble(json['credit_limit']),
    paymentCondition: json['payment_condition']?.toString(),
    category: json['category']?.toString(),
    notes: json['notes']?.toString(),
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null,
  );

  String get displayName {
    final fantasy = fantasyName?.trim();
    final isCompany = (tipoPessoa ?? '').toUpperCase() == 'J';
    if (isCompany && fantasy != null && fantasy.isNotEmpty) return fantasy;
    return name;
  }

  Map<String, dynamic> toJson() => {
    'organization_id': organizationId,
    'name': name,
    'code': code,
    'fantasy_name': fantasyName,
    'document': document,
    'tipo_pessoa': tipoPessoa,
    'status': status,
    'tax_regime': taxRegime,
    'ie_indicator': ieIndicator,
    'ie': ie,
    'ie_exempt': ieExempt,
    'im': im,
    'rg': rg,
    'rg_emissor': rgEmissor,
    'is_public_org': isPublicOrg,
    'suframa': suframa,
    'consumidor_final': consumidorFinal,
    'cod_pais': codPais,
    'cep': cep,
    'uf': uf,
    'city': city,
    'neighborhood': neighborhood,
    'address': address,
    'number': number,
    'complement': complement,
    'cod_municipio': codMunicipio,
    'billing_cep': billingCep,
    'billing_uf': billingUf,
    'billing_city': billingCity,
    'billing_neighborhood': billingNeighborhood,
    'billing_address': billingAddress,
    'billing_number': billingNumber,
    'billing_complement': billingComplement,
    'email': email,
    'nfe_email': nfeEmail,
    'phone': phone,
    'mobile': mobile,
    'fax': fax,
    'carrier': carrier,
    'website': website,
    'contact_info': contactInfo,
    'contact_people': contactPeople,
    'contact_type': contactType,
    'civil_status': civilStatus,
    'profession': profession,
    'gender': gender,
    'birth_date': birthDate,
    'birthplace': birthplace,
    'father_name': fatherName,
    'father_cpf': fatherCpf,
    'mother_name': motherName,
    'mother_cpf': motherCpf,
    'client_since': clientSince,
    'next_visit': nextVisit,
    'situation': situation,
    'seller': seller,
    'default_operation': defaultOperation,
    'credit_limit_type': creditLimitType,
    'credit_limit': creditLimit,
    'payment_condition': paymentCondition,
    'category': category,
    'notes': notes,
  };

  static double? _toDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString());
  }
}
