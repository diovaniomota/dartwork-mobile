class CompanySettings {
  final String id;
  final String organizationId;
  final String? cnpj;
  final String? razaoSocial;
  final String? nomeFantasia;
  final String? inscricaoEstadual;
  final String? regimeTributario;

  final String? logradouro;
  final String? numero;
  final String? bairro;
  final String? cidade;
  final String? uf;
  final String? cep;
  final String? codigoMunicipio;
  final String? codigoUf;

  final String? serieNfce;
  final int? proximaNfce;
  final String? ambiente; // '1' = produção, '2' = homologação
  final String? verProc;

  const CompanySettings({
    required this.id,
    required this.organizationId,
    this.cnpj,
    this.razaoSocial,
    this.nomeFantasia,
    this.inscricaoEstadual,
    this.regimeTributario,
    this.logradouro,
    this.numero,
    this.bairro,
    this.cidade,
    this.uf,
    this.cep,
    this.codigoMunicipio,
    this.codigoUf,
    this.serieNfce,
    this.proximaNfce,
    this.ambiente,
    this.verProc,
  });

  factory CompanySettings.fromJson(Map<String, dynamic> json) {
    return CompanySettings(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString() ?? '',
      cnpj: json['cnpj']?.toString(),
      razaoSocial:
          json['razao_social']?.toString() ?? json['company_name']?.toString(),
      nomeFantasia:
          json['nome_fantasia']?.toString() ?? json['trade_name']?.toString(),
      inscricaoEstadual:
          json['inscricao_estadual']?.toString() ??
          json['state_registration']?.toString(),
      regimeTributario: json['regime_tributario']?.toString(),
      logradouro:
          json['endereco_logradouro']?.toString() ??
          json['address']?.toString(),
      numero:
          json['endereco_numero']?.toString() ??
          json['address_number']?.toString(),
      bairro:
          json['endereco_bairro']?.toString() ??
          json['neighborhood']?.toString(),
      cidade: json['endereco_cidade']?.toString() ?? json['city']?.toString(),
      uf: json['endereco_uf']?.toString() ?? json['state']?.toString(),
      cep: json['endereco_cep']?.toString() ?? json['cep']?.toString(),
      codigoMunicipio: json['codigo_municipio']?.toString(),
      codigoUf: json['codigo_uf']?.toString(),
      serieNfce: json['serie_nfce']?.toString(),
      proximaNfce: int.tryParse(
        json['proxima_nfce']?.toString() ??
            json['ultimo_numero_nfce']?.toString() ??
            '',
      ),
      ambiente: json['ambiente']?.toString(),
      verProc: json['ver_proc']?.toString() ?? '1.0.0',
    );
  }
}
