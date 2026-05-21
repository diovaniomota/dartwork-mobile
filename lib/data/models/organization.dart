class Organization {
  final String id;
  final String name;
  final String? cnpj;
  final String? nomeFantasia;
  final String? razaoSocial;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final String status;
  final String? planCode;
  final String? planName;
  final List<String> enabledFeatures;
  final String? subscriptionStatus;
  final String? subscriptionCurrentPeriodEnd;
  final String? billingProvider;
  final String? billingPaymentMethod;
  final bool billingManualOverride;
  final int billingRetryCount;
  final int billingRetryLimit;
  final int? maxUsers;
  final Map<String, dynamic> raw;

  const Organization({
    required this.id,
    required this.name,
    this.cnpj,
    this.nomeFantasia,
    this.razaoSocial,
    this.phone,
    this.email,
    this.logoUrl,
    this.status = 'ativo',
    this.planCode,
    this.planName,
    this.enabledFeatures = const [],
    this.subscriptionStatus,
    this.subscriptionCurrentPeriodEnd,
    this.billingProvider,
    this.billingPaymentMethod,
    this.billingManualOverride = false,
    this.billingRetryCount = 0,
    this.billingRetryLimit = 4,
    this.maxUsers,
    this.raw = const {},
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    List<String> parseFeatures(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    return Organization(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ??
          json['razao_social']?.toString() ??
          json['nome_fantasia']?.toString() ??
          'Organizacao',
      cnpj: json['cnpj']?.toString(),
      nomeFantasia: json['nome_fantasia']?.toString(),
      razaoSocial: json['razao_social']?.toString(),
      phone: json['phone']?.toString() ?? json['telefone']?.toString(),
      email: json['email']?.toString(),
      logoUrl: json['logo_url']?.toString(),
      status: json['status']?.toString() ?? 'ativo',
      planCode: json['plan_code']?.toString() ?? json['plan']?.toString(),
      planName: json['plan_name']?.toString(),
      enabledFeatures: parseFeatures(json['enabled_features']),
      subscriptionStatus: json['subscription_status']?.toString(),
      subscriptionCurrentPeriodEnd:
          json['subscription_current_period_end']?.toString(),
      billingProvider: json['billing_provider']?.toString(),
      billingPaymentMethod: json['billing_payment_method']?.toString(),
      billingManualOverride: json['billing_manual_override'] == true,
      billingRetryCount:
          int.tryParse(json['billing_retry_count']?.toString() ?? '') ?? 0,
      billingRetryLimit:
          int.tryParse(json['billing_retry_limit']?.toString() ?? '') ?? 4,
      maxUsers: int.tryParse(json['max_users']?.toString() ?? ''),
      raw: json,
    );
  }

  bool get isBlocked {
    final s = status.toLowerCase();
    return s == 'bloqueado' || s == 'blocked' || s == 'suspended';
  }
}
