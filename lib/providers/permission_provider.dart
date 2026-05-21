import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

/// Provider de permissões baseado no perfil do usuário.
/// Verifica role e permissões granulares (view/create/edit/delete por módulo).
final permissionProvider = Provider<PermissionChecker>((ref) {
  final userProfile = ref.watch(userProfileProvider).value;
  return PermissionChecker(userProfile);
});

/// Classe para verificar permissões do usuário.
class PermissionChecker {
  final dynamic _user;

  PermissionChecker(this._user);

  bool get isLoggedIn => _user != null;

  String get role => _user?.role ?? 'user';

  bool get isSuperAdmin => _user?.isSuperAdmin == true;

  bool get isAdmin => _user?.isAdmin == true || isSuperAdmin;

  /// Verifica se o usuário tem permissão para acessar um módulo com uma ação.
  bool hasPermission(String module, String action) {
    if (_user == null) return false;
    return _user.hasPermission(module, action);
  }

  bool canView(String module) => hasPermission(module, 'view');
  bool canCreate(String module) => hasPermission(module, 'create');
  bool canEdit(String module) => hasPermission(module, 'edit');
  bool canDelete(String module) => hasPermission(module, 'delete');
}
