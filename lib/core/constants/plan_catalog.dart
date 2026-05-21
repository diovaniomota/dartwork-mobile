class PlanDefinition {
  final String code;
  final String name;
  final int monthlyPriceCents;
  final List<String> features;

  const PlanDefinition({
    required this.code,
    required this.name,
    required this.monthlyPriceCents,
    required this.features,
  });
}

const featureLabels = {
  'dashboard': 'Dashboard',
  'ordens_servico': 'Ordens de Servico',
  'pdv': 'PDV',
  'caixa': 'Controle de Caixa',
  'fluxo_caixa': 'Movimentacoes de Caixa',
  'nfe': 'NF-e',
  'nfce': 'NFC-e',
  'nfse': 'NFS-e',
  'vendas': 'Vendas',
  'clientes': 'Clientes',
  'veiculos': 'Veiculos',
  'fornecedores': 'Fornecedores',
  'produtos': 'Produtos e Estoque',
  'transportadoras': 'Transportadoras',
  'compras': 'Compras',
  'contas_pagar': 'Contas a Pagar',
  'contas_receber': 'Contas a Receber',
  'conciliacao_bancaria': 'Conciliacao Bancaria',
  'relatorios': 'Relatorios',
  'configuracoes': 'Configuracoes',
  'orcamentos': 'Orcamentos',
  'equipe': 'Equipe e Metas',
  'automacoes': 'Automacoes',
  'sugestoes': 'Sugestoes',
  'indicacoes': 'Indicacoes',
  'acesso_remoto': 'Acesso Remoto',
};

const _coreModules = [
  'dashboard',
  'ordens_servico',
  'pdv',
  'caixa',
  'fluxo_caixa',
  'clientes',
  'produtos',
  'contas_pagar',
  'contas_receber',
  'indicacoes',
  'configuracoes',
];

final planCatalog = [
  PlanDefinition(
    code: 'essencial',
    name: 'Essencial',
    monthlyPriceCents: 8000,
    features: _coreModules,
  ),
  PlanDefinition(
    code: 'prime',
    name: 'Prime',
    monthlyPriceCents: 19990,
    features: featureLabels.keys.toList(),
  ),
];

const _legacyPlanAlias = {
  'evolucao': 'prime',
  'escala': 'prime',
  'performance': 'prime',
};

String normalizePlanCode(String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  return _legacyPlanAlias[normalized] ?? normalized;
}

PlanDefinition? getPlanByCode(String? planCode) {
  final code = normalizePlanCode(planCode);
  try {
    return planCatalog.firstWhere((p) => p.code == code);
  } catch (_) {
    return null;
  }
}

List<String> getPlanFeatures(String? planCode) {
  return getPlanByCode(planCode)?.features ?? [];
}

String getFeatureLabel(String? featureKey) {
  final normalized = (featureKey ?? '').trim();
  return featureLabels[normalized] ?? normalized;
}
