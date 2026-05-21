import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../core/constants/supabase_constants.dart';

class FiscalApiService {
  /// Obter os headers dinâmicos autenticados (Supabase JWT e JSON)
  Future<Map<String, String>> _headers() async {
    final session = supabase.auth.currentSession;
    if (session == null) {
      throw Exception('Usuário não autenticado no aplicativo');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${session.accessToken}',
    };
  }

  /// Emitir NF-e a partir de uma Venda (Web Hook compatível)
  Future<Map<String, dynamic>> emitirNfe(
    String vendaId,
    String organizationId,
  ) async {
    final baseUrl = const String.fromEnvironment(
      'API_URL',
      defaultValue: AppConstants.webAppUrl,
    );
    final url = Uri.parse('$baseUrl/api/fiscal/nfe');

    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode({
        'action': 'emitir_por_venda',
        'vendaId': vendaId,
        'organizationId': organizationId,
      }),
    );

    return _parseResult(response);
  }

  /// Emitir NF-e a partir de um Payload Avulso construido localmente
  Future<Map<String, dynamic>> emitirNfePayload(
    String ref,
    Map<String, dynamic> payload,
  ) async {
    final baseUrl = const String.fromEnvironment(
      'API_URL',
      defaultValue: AppConstants.webAppUrl,
    );
    final url = Uri.parse('$baseUrl/api/fiscal/nfe');

    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode({
        'action': 'emitir_payload',
        'ref': ref,
        'payload': payload,
      }),
    );

    return _parseResult(response);
  }

  /// Emitir NFC-e (Cupom Fiscal Avulso consumido no PDV Frontend)
  Future<Map<String, dynamic>> emitirNfce(
    String ref,
    Map<String, dynamic> payload,
  ) async {
    final baseUrl = const String.fromEnvironment(
      'API_URL',
      defaultValue: AppConstants.webAppUrl,
    );
    final url = Uri.parse('$baseUrl/api/fiscal/nfce');

    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode({'action': 'emitir', 'ref': ref, 'payload': payload}),
    );

    return _parseResult(response);
  }

  /// Emitir NFS-e (Nota de Serviços gerados manualmente na UI do Mobile)
  Future<Map<String, dynamic>> emitirNfse(
    String ref,
    Map<String, dynamic> nfseData,
  ) async {
    final baseUrl = const String.fromEnvironment(
      'API_URL',
      defaultValue: AppConstants.webAppUrl,
    );
    final url = Uri.parse('$baseUrl/api/fiscal/nfse');

    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode({'action': 'emitir', 'ref': ref, 'nfseData': nfseData}),
    );

    return _parseResult(response);
  }

  // Parse simplificado dos retornos da Vercel Edge API
  Map<String, dynamic> _parseResult(http.Response response) {
    if (response.statusCode >= 500) {
      throw Exception(
        'Erro de servidor na Integração Fiscal (Vercel Backend). Código: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);
    if (data['success'] != true) {
      final errMsg =
          data['error'] ??
          'Erro desconhecido do Back-end de Integração FocusNFe';
      throw Exception(errMsg);
    }
    return data;
  }
}

final fiscalApiProvider = Provider<FiscalApiService>(
  (ref) => FiscalApiService(),
);
