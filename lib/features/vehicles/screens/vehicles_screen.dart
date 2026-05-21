import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/repositories/vehicle_repository.dart';
import '../../../providers/permission_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/search_field.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_colors.dart';
import 'dart:async';

/// Tela de listagem de veículos.
class VehiclesScreen extends ConsumerStatefulWidget {
  const VehiclesScreen({super.key});

  @override
  ConsumerState<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends ConsumerState<VehiclesScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String? _search;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _search = v.isEmpty ? null : v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehiclesProvider(_search));
    final permissions = ref.watch(permissionProvider);

    return AppScaffold(
      title: 'Veículos',
      floatingActionButton: permissions.canCreate('veiculos')
          ? FloatingActionButton(
              onPressed: () => context.push('/veiculos/novo'),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchField(
              hintText: 'Buscar por placa, modelo...',
              controller: _searchCtrl,
              onChanged: _onSearch,
            ),
          ),
          Expanded(
            child: vehicles.when(
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.directions_car_outlined,
                    title: 'Nenhum veículo encontrado',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(vehiclesProvider(_search)),
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final v = list[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.info.withAlpha(25),
                          child: const Icon(
                            Icons.directions_car,
                            color: AppColors.info,
                          ),
                        ),
                        title: Text(
                          formatPlate(v.plate),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(v.displayName),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/veiculos/${v.id}'),
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
