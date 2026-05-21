import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/plan_catalog.dart';
import '../core/utils/billing_access.dart';
import 'organization_provider.dart';

/// Provider de billing/plano - verifica se features estão disponíveis no plano.
final billingProvider = Provider<BillingChecker>((ref) {
  final org = ref.watch(currentOrganizationProvider).value;
  return BillingChecker(org);
});

/// Classe para verificar acesso baseado no plano.
class BillingChecker {
  final dynamic _org;

  BillingChecker(this._org);

  /// Código do plano normalizado.
  String get planCode => normalizePlanCode(_org?.planCode);

  /// Nome do plano.
  String get planName => getPlanByCode(_org?.planCode)?.name ?? 'Sem Plano';

  /// Verifica se a organização está bloqueada.
  bool get isBlocked => shouldBlockByBillingPolicy(_org);

  /// Verifica se uma feature está disponível no plano atual.
  bool hasFeature(String featureKey) {
    if (_org == null) return false;

    // Se a org tem enabled_features explícitas, usa elas
    final orgFeatures = _org.enabledFeatures as List<String>?;
    if (orgFeatures != null && orgFeatures.isNotEmpty) {
      return orgFeatures.contains(featureKey);
    }

    // Caso contrário, verifica pelo catálogo de planos
    final features = getPlanFeatures(_org.planCode);
    return features.contains(featureKey);
  }

  /// Status da assinatura.
  String get subscriptionStatus =>
      _org?.subscriptionStatus?.toString() ?? 'unknown';

  /// Verifica se a assinatura está ativa.
  bool get isSubscriptionActive {
    final status = subscriptionStatus.toLowerCase();
    return status == 'active' || status == 'authorized' || status == 'trialing';
  }
}
