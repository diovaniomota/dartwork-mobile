import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../../core/constants/supabase_constants.dart';

/// Repositório de autenticação - gerencia login, logout e sessão.
class AuthRepository {
  /// Login com email e senha.
  Future<AuthResponse> signIn(String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Logout.
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  /// Retorna a sessão atual.
  Session? get currentSession => supabase.auth.currentSession;

  /// Retorna o usuário auth atual.
  User? get currentUser => supabase.auth.currentUser;

  /// Stream de mudanças no estado de autenticação.
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  /// Busca o perfil do usuário na tabela app_users pelo auth_id.
  Future<AppUser?> getUserProfile(String authId) async {
    final response = await supabase
        .from('app_users')
        .select()
        .eq('auth_id', authId)
        .maybeSingle();

    if (response == null) return null;
    return AppUser.fromJson(response);
  }

  /// Busca todos os usuários da organização.
  Future<List<AppUser>> getOrganizationUsers(String organizationId) async {
    final response = await supabase
        .from('app_users')
        .select()
        .eq('organization_id', organizationId)
        .order('name');

    return (response as List)
        .map((json) => AppUser.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Atualiza o perfil do usuário.
  Future<void> updateUserProfile(String id, Map<String, dynamic> data) async {
    await supabase.from('app_users').update(data).eq('id', id);
  }
}
