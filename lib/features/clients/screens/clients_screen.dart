import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/client.dart';
import '../../../data/repositories/client_repository.dart';
import '../../../providers/organization_provider.dart';
import '../../../providers/permission_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/search_field.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_colors.dart';
import 'dart:async';

/// Provider da lista de clientes.
final clientsProvider = FutureProvider.family<List<ClientModel>, String?>((
  ref,
  search,
) async {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return [];
  final repo = ref.read(clientRepositoryProvider);
  return await repo.getAll(orgId, search: search);
});

/// Tela de listagem de clientes.
class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _searchQuery;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchQuery = value.isEmpty ? null : value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider(_searchQuery));
    final permissions = ref.watch(permissionProvider);

    return AppScaffold(
      title: 'Clientes',
      floatingActionButton: permissions.canCreate('clientes')
          ? FloatingActionButton(
              onPressed: () => context.push('/clientes/novo'),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchField(
              hintText: 'Buscar cliente...',
              controller: _searchController,
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: clients.when(
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline,
                    title: 'Nenhum cliente encontrado',
                    subtitle: 'Adicione seu primeiro cliente',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(clientsProvider(_searchQuery)),
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final client = list[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withAlpha(25),
                          child: Text(
                            client.name.isNotEmpty
                                ? client.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          client.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          client.document != null
                              ? formatCpfCnpj(client.document)
                              : (client.phone ?? 'Sem contato'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/clientes/${client.id}'),
                      );
                    },
                  ),
                );
              },
              loading: () => const LoadingIndicator(),
              error: (error, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Erro ao carregar',
                subtitle: error.toString(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
