import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';

/// Tela exibida quando o acesso mobile não está liberado para a organização.
class MobileBlockedScreen extends ConsumerWidget {
  const MobileBlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'Acesso Mobile',
      showDrawer: false,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.smartphone_rounded,
                size: 62,
                color: Color(0xFF94a3b8),
              ),
              const SizedBox(height: 16),
              Text(
                'Acesso ao app mobile não liberado',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                'O acesso ao aplicativo mobile ainda não foi habilitado '
                'para a sua empresa. Entre em contato com o suporte ou '
                'o administrador do sistema para solicitar a liberação.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748b),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).signOut();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sair'),
                style: FilledButton.styleFrom(minimumSize: const Size(180, 48)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
