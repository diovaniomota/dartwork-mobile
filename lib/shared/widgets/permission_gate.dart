import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/permission_provider.dart';

/// Widget que mostra/esconde conteúdo baseado em permissões.
class PermissionGate extends ConsumerWidget {
  final String module;
  final String action;
  final Widget child;
  final Widget? fallback;

  const PermissionGate({
    super.key,
    required this.module,
    this.action = 'view',
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionProvider);

    if (permissions.hasPermission(module, action)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}
