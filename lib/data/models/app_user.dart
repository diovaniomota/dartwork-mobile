class AppUser {
  final String id;
  final String authId;
  final String? organizationId;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? avatarUrl;
  final Map<String, dynamic>? permissions;
  final bool isSuperAdmin;
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.authId,
    this.organizationId,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.permissions,
    this.isSuperAdmin = false,
    this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final role = (json['role'] ?? 'user').toString().trim().toLowerCase();
    final isSuperAdmin =
        role == 'super_admin' || role == 'super admin' || role == 'superadmin';

    return AppUser(
      id: json['id']?.toString() ?? '',
      authId: json['auth_id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString(),
      name:
          json['name']?.toString() ??
          json['full_name']?.toString() ??
          json['nome']?.toString() ??
          'Usuario',
      email: json['email']?.toString() ?? '',
      role: role,
      phone: json['phone']?.toString(),
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl'])?.toString(),
      permissions: json['permissions'] is Map<String, dynamic>
          ? json['permissions']
          : null,
      isSuperAdmin: isSuperAdmin,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Roles com acesso total — alinhado com o desktop (requestPermission.js).
  static const Set<String> _adminLikeRoles = {
    'admin',
    'administrador',
    'owner',
    'super admin',
    'super_admin',
    'superadmin',
  };

  bool get isAdminLike =>
      isSuperAdmin || _adminLikeRoles.contains(role.trim().toLowerCase());

  bool get isAdmin => isAdminLike;

  bool hasPermission(String module, String action) {
    if (isAdminLike) return true;
    if (module == 'dashboard') return true;
    if (permissions == null) return false;

    final modulePerms = permissions![module];
    // Módulo inteiro liberado (true) ou negado (false/null).
    if (modulePerms == null || modulePerms == false) return false;
    if (modulePerms == true) return true;
    if (modulePerms is Map) {
      return modulePerms[action] == true;
    }
    if (modulePerms is List) {
      return modulePerms.contains(action);
    }
    return false;
  }

  bool canView(String module) => hasPermission(module, 'view');
  bool canCreate(String module) => hasPermission(module, 'create');
  bool canEdit(String module) => hasPermission(module, 'edit');
  bool canDelete(String module) => hasPermission(module, 'delete');
}
