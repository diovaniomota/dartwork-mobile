import '../../data/models/organization.dart';

String _normalizeText(String? value) => (value ?? '').trim().toLowerCase();

const Set<String> _blockedStatusSet = {'bloqueado', 'blocked', 'suspended'};
const Set<String> _overdueStatusSet = {'vencido', 'overdue'};
const Set<String> _trialStatusSet = {'trial', 'pending'};
const Set<String> _failureSubscriptionStatusSet = {'past_due', 'canceled'};
const Set<String> _cardPaymentMethodSet = {
  'card',
  'credit_card',
  'credito',
  'mercado_pago_card',
};

const int defaultBillingRetryLimit = 4;
const int defaultOverdueBlockDays = 5;
const int _dayInMs = 24 * 60 * 60 * 1000;

String normalizeSubscriptionStatus(String? status) {
  final normalized = _normalizeText(status);
  if (normalized.isEmpty) return 'inactive';
  if (normalized == 'trialing') return 'trial';
  if (normalized == 'cancelled') return 'canceled';
  if (normalized == 'overdue') return 'past_due';
  return normalized;
}

String normalizeOrganizationStatus(String? status) {
  final normalized = _normalizeText(status);
  if (normalized.isEmpty) return 'ativo';
  if (normalized == 'active') return 'ativo';
  if (normalized == 'blocked' || normalized == 'suspended') return 'bloqueado';
  if (normalized == 'overdue') return 'vencido';
  return normalized;
}

String getBillingPaymentMethod(Organization? organization) {
  if (organization == null) return 'none';
  final explicitMethod = _normalizeText(organization.billingPaymentMethod);
  if (explicitMethod.isNotEmpty) return explicitMethod;

  final provider = _normalizeText(organization.billingProvider);
  final subscriptionExternalId = _normalizeText(
    organization.raw['subscription_external_id']?.toString(),
  );

  if (provider == 'mercado_pago' && subscriptionExternalId.isNotEmpty) {
    return 'card';
  }
  return 'none';
}

bool isCardPaymentMethod(Organization? organization) =>
    _cardPaymentMethodSet.contains(getBillingPaymentMethod(organization));

bool isManualBillingOverride(Organization? organization) =>
    organization?.billingManualOverride == true;

int getBillingRetryLimit(Organization? organization) {
  final parsed = organization?.billingRetryLimit;
  if (parsed != null && parsed > 0) return parsed;
  return defaultBillingRetryLimit;
}

int getBillingRetryCount(Organization? organization) {
  final parsed = organization?.billingRetryCount;
  if (parsed == null || parsed < 0) return 0;
  return parsed;
}

bool hasRemainingCardRetries(Organization? organization) {
  if (!isCardPaymentMethod(organization)) return false;
  final retryLimit = getBillingRetryLimit(organization);
  final retryCount = getBillingRetryCount(organization);
  return retryCount < retryLimit;
}

bool isPastDate(String? value) {
  if (value == null || value.trim().isEmpty) return false;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return false;
  return parsed.millisecondsSinceEpoch <= DateTime.now().millisecondsSinceEpoch;
}

bool isTrialExpired(Organization? organization) {
  if (organization == null) return false;
  final subscriptionStatus = normalizeSubscriptionStatus(
    organization.subscriptionStatus,
  );
  final organizationStatus = normalizeOrganizationStatus(
    organization.status.isNotEmpty
        ? organization.status
        : organization.raw['situacao']?.toString(),
  );
  final effectiveStatus = subscriptionStatus.isNotEmpty
      ? subscriptionStatus
      : (organizationStatus == 'trial' ? 'trial' : 'inactive');

  if (!_trialStatusSet.contains(effectiveStatus)) return false;
  return isPastDate(organization.subscriptionCurrentPeriodEnd);
}

int getDaysOverdue(Organization? organization) {
  if (organization == null) return 0;
  final periodEnd = organization.subscriptionCurrentPeriodEnd;
  if (periodEnd == null || periodEnd.trim().isEmpty) return 0;
  final parsed = DateTime.tryParse(periodEnd);
  if (parsed == null) return 0;

  final diff =
      DateTime.now().millisecondsSinceEpoch - parsed.millisecondsSinceEpoch;
  return diff > 0 ? (diff / _dayInMs).floor() : 0;
}

bool isOverdueByDays(
  Organization? organization, {
  int maxDays = defaultOverdueBlockDays,
}) {
  if (organization == null) return false;
  if (isManualBillingOverride(organization)) return false;

  final subscriptionStatus = normalizeSubscriptionStatus(
    organization.subscriptionStatus,
  );
  if (!_failureSubscriptionStatusSet.contains(subscriptionStatus)) return false;
  return getDaysOverdue(organization) >= maxDays;
}

bool isCardRetryGraceActive(Organization? organization) {
  if (organization == null) return false;
  if (isManualBillingOverride(organization)) return false;
  if (!isCardPaymentMethod(organization)) return false;
  if (!hasRemainingCardRetries(organization)) return false;

  final subscriptionStatus = normalizeSubscriptionStatus(
    organization.subscriptionStatus,
  );
  if (isTrialExpired(organization)) return true;
  return _failureSubscriptionStatusSet.contains(subscriptionStatus);
}

bool shouldBlockByBillingPolicy(Organization? organization) {
  if (organization == null) return false;
  if (isManualBillingOverride(organization)) return false;

  final orgStatus = normalizeOrganizationStatus(
    organization.status.isNotEmpty
        ? organization.status
        : organization.raw['situacao']?.toString(),
  );
  if (_blockedStatusSet.contains(orgStatus)) return true;

  if (isOverdueByDays(organization, maxDays: defaultOverdueBlockDays)) {
    return true;
  }

  if (isCardRetryGraceActive(organization)) return false;

  if (isTrialExpired(organization)) return true;
  if (_overdueStatusSet.contains(orgStatus)) return true;
  return false;
}

String? getBillingBlockReason(Organization? organization) {
  if (organization == null) return null;
  if (isManualBillingOverride(organization)) return null;

  final orgStatus = normalizeOrganizationStatus(
    organization.status.isNotEmpty
        ? organization.status
        : organization.raw['situacao']?.toString(),
  );
  if (_blockedStatusSet.contains(orgStatus)) {
    return organization.raw['blocked_reason']?.toString() ??
        organization.raw['motivo_bloqueio']?.toString() ??
        'Conta bloqueada';
  }

  if (isOverdueByDays(organization, maxDays: defaultOverdueBlockDays)) {
    final days = getDaysOverdue(organization);
    return 'Pagamento não realizado após $days dias do vencimento.';
  }

  if (isCardRetryGraceActive(organization)) return null;

  if (isTrialExpired(organization)) {
    if (isCardPaymentMethod(organization)) {
      final retryCount = getBillingRetryCount(organization);
      final retryLimit = getBillingRetryLimit(organization);
      if (retryCount >= retryLimit) {
        return 'Falha de cobrança após $retryLimit tentativas no cartão.';
      }
    }
    return 'Período de trial vencido.';
  }

  if (_overdueStatusSet.contains(orgStatus)) {
    if (isCardPaymentMethod(organization)) {
      final retryCount = getBillingRetryCount(organization);
      final retryLimit = getBillingRetryLimit(organization);
      if (retryCount >= retryLimit) {
        return 'Cobrança não aprovada após $retryLimit tentativas no cartão.';
      }
    }
    return 'Pagamento vencido.';
  }

  return null;
}

/// Verifica se o acesso mobile está bloqueado para a organização.
/// Retorna true se a feature 'mobile_app' NÃO está em enabledFeatures.
bool shouldBlockByMobileAccess(Organization? organization) {
  if (organization == null) return false;
  return !organization.enabledFeatures.contains('mobile_app');
}

/// Retorna a mensagem de bloqueio de acesso mobile.
String? getMobileBlockReason(Organization? organization) {
  if (organization == null) return null;
  if (!shouldBlockByMobileAccess(organization)) return null;
  return 'O acesso ao aplicativo mobile não foi liberado para sua empresa.';
}
