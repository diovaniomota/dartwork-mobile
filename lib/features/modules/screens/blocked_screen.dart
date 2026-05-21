import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/billing_access.dart';
import '../../../providers/organization_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';

class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationAsync = ref.watch(currentOrganizationProvider);
    final organization = organizationAsync.value;
    final isStillBlocked = shouldBlockByBillingPolicy(organization);
    final blockReason = getBillingBlockReason(organization);

    if (organization != null && !isStillBlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/');
        }
      });
    }

    return AppScaffold(
      title: 'Acesso Bloqueado',
      showDrawer: false,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_clock_rounded, size: 62),
              const SizedBox(height: 12),
              Text(
                'Sua organização está com recursos limitados no momento.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (blockReason != null && blockReason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Motivo: $blockReason',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Regularize o plano para restaurar todos os módulos.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.push('/configuracoes/plano'),
                icon: const Icon(Icons.workspace_premium_rounded),
                label: const Text('Ir para planos'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Voltar ao dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
