import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/cash_register.dart';
import '../../../data/repositories/cash_register_repository.dart';
import '../../../providers/organization_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_colors.dart';

final cashRegisterRepositoryProvider = Provider(
  (ref) => CashRegisterRepository(),
);

final openRegisterProvider = FutureProvider<CashRegister?>((ref) async {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return null;
  final repo = ref.read(cashRegisterRepositoryProvider);
  return await repo.getOpenRegister(orgId);
});

final cashMovementsProvider = FutureProvider<List<CaixaMovement>>((ref) async {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return [];
  final repo = ref.read(cashRegisterRepositoryProvider);
  return await repo.getMovements(orgId);
});

/// Tela do caixa com abertura/fechamento e movimentações.
class CashRegisterScreen extends ConsumerStatefulWidget {
  const CashRegisterScreen({super.key});

  @override
  ConsumerState<CashRegisterScreen> createState() => _CashRegisterScreenState();
}

class _CashRegisterScreenState extends ConsumerState<CashRegisterScreen> {
  bool _loading = false;

  Future<void> _openRegister() async {
    final amountCtrl = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abrir Caixa'),
        content: TextField(
          controller: amountCtrl,
          decoration: const InputDecoration(labelText: 'Saldo Inicial (R\$)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(amountCtrl.text) ?? 0),
            child: const Text('Abrir'),
          ),
        ],
      ),
    );
    if (result == null) return;

    setState(() => _loading = true);
    try {
      final orgId = ref.read(currentOrgIdProvider);
      final user = ref.read(userProfileProvider).value;
      if (orgId == null) return;
      final repo = ref.read(cashRegisterRepositoryProvider);
      await repo.openRegister(orgId, result, userId: user?.authId);
      ref.invalidate(openRegisterProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Caixa aberto!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _closeRegister(String registerId) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Fechar Caixa',
      message: 'Deseja realmente fechar o caixa?',
      confirmColor: AppColors.danger,
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(cashRegisterRepositoryProvider);
      await repo.closeRegister(registerId, 0);
      ref.invalidate(openRegisterProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Caixa fechado!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final register = ref.watch(openRegisterProvider);
    final movements = ref.watch(cashMovementsProvider);

    return AppScaffold(
      title: 'Caixa',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(openRegisterProvider);
          ref.invalidate(cashMovementsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status do caixa
              register.when(
                data: (reg) {
                  if (reg == null || !reg.isOpen) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_outlined,
                                size: 40,
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Caixa Fechado',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loading ? null : _openRegister,
                              icon: const Icon(Icons.lock_open),
                              label: const Text('Abrir Caixa'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.lock_open,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Caixa Aberto',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => _closeRegister(reg.id),
                                child: const Text(
                                  'Fechar',
                                  style: TextStyle(color: AppColors.danger),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Saldo inicial: ${formatCurrency(reg.openingBalance)}',
                          ),
                          if (reg.openedAt != null)
                            Text(
                              'Aberto em: ${formatDateTimeBR(reg.openedAt)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const LoadingIndicator(),
                error: (e, _) => Text('Erro: $e'),
              ),

              const SizedBox(height: 20),

              // Movimentações recentes
              Text(
                'Movimentações Recentes',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              movements.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Sem movimentações',
                    );
                  }
                  return Column(
                    children: list
                        .take(20)
                        .map(
                          (m) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  (m.isEntrada
                                          ? AppColors.success
                                          : AppColors.danger)
                                      .withAlpha(25),
                              radius: 18,
                              child: Icon(
                                m.isEntrada
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: m.isEntrada
                                    ? AppColors.success
                                    : AppColors.danger,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              m.description ??
                                  (m.isEntrada ? 'Entrada' : 'Saída'),
                            ),
                            subtitle: Text(
                              formatDateTimeBR(m.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: Text(
                              '${m.isEntrada ? '+' : '-'} ${formatCurrency(m.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: m.isEntrada
                                    ? AppColors.success
                                    : AppColors.danger,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const LoadingIndicator(),
                error: (e, _) => Text('Erro: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
