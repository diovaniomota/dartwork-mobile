import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../core/constants/supabase_constants.dart';

class AiChatService {
  String _readAccessToken() {
    final session = supabase.auth.currentSession;
    if (session == null || session.accessToken.trim().isEmpty) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }
    return session.accessToken;
  }

  Future<String?> _tryRefreshAccessToken() async {
    try {
      final refreshed = await supabase.auth.refreshSession();
      final token = refreshed.session?.accessToken;
      if (token == null || token.trim().isEmpty) return null;
      return token;
    } catch (_) {
      return null;
    }
  }

  Future<http.Response> _postChat({
    required String accessToken,
    required List<Map<String, String>> messages,
    required String currentRoute,
    String? companyContext,
  }) {
    final uri = Uri.parse('${AppConstants.webAppUrl}/api/chat');
    return http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $accessToken',
            'x-supabase-access-token': accessToken,
            'x-client-platform': 'work-erp-mobile',
          },
          body: jsonEncode({
            'messages': messages,
            'currentRoute': currentRoute,
            if (companyContext != null && companyContext.trim().isNotEmpty)
              'companyContext': companyContext,
          }),
        )
        .timeout(const Duration(seconds: 30));
  }

  Future<String> sendMessage({
    required List<Map<String, String>> messages,
    String? currentRoute,
    String? companyContext,
  }) async {
    final route = currentRoute ?? '/assistente';
    final firstToken = _readAccessToken();
    var response = await _postChat(
      accessToken: firstToken,
      messages: messages,
      currentRoute: route,
      companyContext: companyContext,
    );

    if (response.statusCode == 401) {
      final refreshedToken = await _tryRefreshAccessToken();
      if (refreshedToken != null) {
        response = await _postChat(
          accessToken: refreshedToken,
          messages: messages,
          currentRoute: route,
          companyContext: companyContext,
        );
      }
    }

    final raw = response.body;
    Map<String, dynamic>? parsed;
    try {
      parsed = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      parsed = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        final unauthorizedMessage =
            parsed?['message']?.toString() ??
            'Acesso não autorizado. Faça login novamente para usar o assistente.';
        throw Exception(
          unauthorizedMessage,
        );
      }

      final message =
          parsed?['message']?.toString() ??
          'Falha ao consultar assistente (${response.statusCode}).';
      throw Exception(message);
    }

    final message = parsed?['message']?.toString().trim() ?? '';
    if (message.isEmpty) {
      throw Exception('Resposta vazia do assistente.');
    }
    return message;
  }
}
