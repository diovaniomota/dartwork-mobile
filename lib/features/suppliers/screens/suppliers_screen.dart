import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/supplier.dart';
import '../../../data/repositories/supplier_repository.dart';
import '../../../providers/organization_provider.dart';
import '../../../providers/permission_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/common_widgets.dart';

final supplierRepositoryProvider = Provider((ref) => SupplierRepository());

final suppliersProvider = FutureProvider.family<List<Supplier>, String?>((
  ref,
  search,
) async {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return [];
  final repo = ref.read(supplierRepositoryProvider);
  return await repo.getAll(orgId, search: search);
});

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  final _searchCtrl = TextEditingController();
  String? _searchQuery;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() => _searchQuery = value.isEmpty ? null : value);
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(suppliersProvider(_searchQuery));
    final permissions = ref.watch(permissionProvider);
    final canCreate = permissions.canCreate('fornecedores');

    return AppScaffold(
      title: 'Fornecedores',
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => context.push('/fornecedores/novo'),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou documento...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearch('');
                        },
                      )
                    : null,
              ),
              onSubmitted: _onSearch,
            ),
          ),
          Expanded(
            child: suppliers.when(
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.store_mall_directory_outlined,
                    title: 'Nenhum fornecedor encontrado',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(suppliersProvider(_searchQuery)),
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final s = list[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withAlpha(25),
                            child: const Icon(
                              Icons.store,
                              color: Colors.blueGrey,
                            ),
                          ),
                          title: Text(
                            s.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (s.document != null)
                                Text('CNPJ/CPF: ${s.document}'),
                              if (s.phone != null) Text('Tel: ${s.phone}'),
                            ],
                          ),
                          onTap: () => context.push('/fornecedores/${s.id}'),
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
                subtitle: e.toString(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
