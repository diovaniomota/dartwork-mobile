import '../models/company_settings.dart';
import '../../core/constants/supabase_constants.dart';

class CompanySettingsRepository {
  Future<CompanySettings?> getByOrganizationId(String orgId) async {
    final response = await supabase
        .from('company_settings')
        .select()
        .eq('organization_id', orgId)
        .maybeSingle();

    if (response == null) return null;
    return CompanySettings.fromJson(response);
  }
}
