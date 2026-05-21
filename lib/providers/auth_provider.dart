import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/app_user.dart';
import '../data/repositories/auth_repository.dart';
import '../core/constants/supabase_constants.dart';

/// Provider do repositório de auth.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider do estado de autenticação (stream do Supabase).
final authStateProvider = StreamProvider<Session?>((ref) {
  return supabase.auth.onAuthStateChange.map((event) => event.session);
});

/// Provider do perfil do usuário logado (AppUser).
final userProfileProvider = FutureProvider<AppUser?>((ref) async {
  final session = ref.watch(authStateProvider).value;
  if (session == null) return null;

  final repo = ref.read(authRepositoryProvider);
  return await repo.getUserProfile(session.user.id);
});

/// Notifier para ações de login/logout.
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.data(null));

  /// Realiza login com email e senha.
  Future<bool> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repo.signIn(email, password);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Realiza logout.
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repo.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
      final repo = ref.read(authRepositoryProvider);
      return AuthNotifier(repo);
    });
