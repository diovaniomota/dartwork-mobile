import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/service_order.dart';
import '../../../data/repositories/service_order_repository.dart';
import '../../../providers/organization_provider.dart';
import '../../../providers/permission_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_colors.dart';

final serviceOrdersProvider =
    FutureProvider.family<List<ServiceOrder>, String?>((ref, status) async {
      final orgId = ref.watch(currentOrgIdProvider);
      if (orgId == null) return [];
      final repo = ref.read(serviceOrderRepositoryProvider);
      return await repo.getAll(orgId, status: status);
    });

/// Tela de listagem de ordens de serviço com filtro por status.
class ServiceOrdersScreen extends ConsumerStatefulWidget {
  const ServiceOrdersScreen({super.key});

  @override
  ConsumerState<ServiceOrdersScreen> createState() =>
      _ServiceOrdersScreenState();
}

class _ServiceOrdersScreenState extends ConsumerState<ServiceOrdersScreen> {
  String? _statusFilter;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aberta':
        return AppColors.warning;
      case 'em_andamento':
        return AppColors.info;
      case 'finalizada':
        return AppColors.success;
      case 'cancelada':
        return AppColors.danger;
      default:
        return AppColors.lightTextMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(serviceOrdersProvider(_statusFilter));
    final permissions = ref.watch(permissionProvider);

    return AppScaffold(
      title: 'Ordens de Serviço',
      actions: [
        if (permissions.canCreate('ordens_servico'))
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/ordens-servico/nova'),
          ),
      ],
      body: Column(
        children: [
          // Filtros de status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todas',
                  selected: _statusFilter == null,
                  onTap: () => setState(() => _statusFilter = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Abertas',
                  selected: _statusFilter == 'aberta',
                  color: AppColors.warning,
                  onTap: () => setState(() => _statusFilter = 'aberta'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Em Andamento',
                  selected: _statusFilter == 'em_andamento',
                  color: AppColors.info,
                  onTap: () => setState(() => _statusFilter = 'em_andamento'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Finalizadas',
                  selected: _statusFilter == 'finalizada',
                  color: AppColors.success,
                  onTap: () => setState(() => _statusFilter = 'finalizada'),
                ),
              ],
            ),
          ),

          Expanded(
            child: orders.when(
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.build_outlined,
                    title: 'Nenhuma OS encontrada',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(serviceOrdersProvider(_statusFilter)),
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final os = list[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  os.clientName ?? 'Sem cliente',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(os.status).withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  os.statusLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _statusColor(os.status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              if (os.vehiclePlate != null)
                                Text(
                                  '🚗 ${formatPlate(os.vehiclePlate)}${os.vehicleModel != null ? ' - ${os.vehicleModel}' : ''}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formatCurrency(os.totalValue),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    formatDateString(
                                      os.createdAt?.toIso8601String(),
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => context.push('/ordens-servico/${os.id}'),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const LoadingIndicator(),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Erro',
                subtitle: '$e',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = color ?? AppColors.primary;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: primaryColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected
            ? Colors.white
            : (isDarkMode ? Colors.white70 : Colors.black87),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
