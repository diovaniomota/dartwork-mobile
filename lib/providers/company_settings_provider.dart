import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/company_settings.dart';
import '../data/repositories/company_settings_repository.dart';
import 'organization_provider.dart';

final companySettingsRepositoryProvider = Provider<CompanySettingsRepository>((
  ref,
) {
  return CompanySettingsRepository();
});

final companySettingsProvider = FutureProvider<CompanySettings?>((ref) async {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return null;

  final repo = ref.read(companySettingsRepositoryProvider);
  return await repo.getByOrganizationId(orgId);
});
