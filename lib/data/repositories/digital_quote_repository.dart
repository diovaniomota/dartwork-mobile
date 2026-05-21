import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/supabase_constants.dart';
import '../models/digital_quote.dart';

class DigitalQuoteRepository {
  Future<List<DigitalQuote>> getAll(
    String organizationId, {
    int page = 0,
    String? search,
  }) async {
    int offset = page * AppConstants.defaultPageSize;
    var query = supabase
        .from('digital_quotes')
        .select()
        .eq('organization_id', organizationId);

    if (search != null && search.isNotEmpty) {
      query = query.or('client_name.ilike.%$search%,title.ilike.%$search%');
    }

    final response = await query
        .order('approval_requested_at', ascending: false, nullsFirst: false)
        .order('created_at', ascending: false)
        .range(offset, offset + AppConstants.defaultPageSize - 1);

    return (response as List)
        .map((json) => DigitalQuote.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<DigitalQuote?> getById(String id) async {
    final response = await supabase
        .from('digital_quotes')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return DigitalQuote.fromJson(response);
  }

  Future<DigitalQuote> create(DigitalQuote quote) async {
    final response = await supabase
        .from('digital_quotes')
        .insert(quote.toJson())
        .select()
        .single();
    return DigitalQuote.fromJson(response);
  }

  Future<DigitalQuote> update(String id, DigitalQuote quote) async {
    final response = await supabase
        .from('digital_quotes')
        .update(quote.toJson())
        .eq('id', id)
        .select()
        .single();
    return DigitalQuote.fromJson(response);
  }

  Future<void> delete(String id) async {
    await supabase.from('digital_quotes').delete().eq('id', id);
  }
}

final digitalQuoteRepositoryProvider = Provider<DigitalQuoteRepository>((ref) {
  return DigitalQuoteRepository();
});
