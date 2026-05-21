import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../providers/organization_provider.dart';
import '../../../providers/permission_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/search_field.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_colors.dart';
import 'dart:async';

final productRepositoryProvider = Provider((ref) => ProductRepository());

final productsProvider = FutureProvider.family<List<Product>, String?>((
  ref,
  search,
) async {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return [];
  final repo = ref.read(productRepositoryProvider);
  return await repo.getAll(orgId, search: search);
});

/// Tela de listagem de produtos.
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
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
    final products = ref.watch(productsProvider(_search));
    final permissions = ref.watch(permissionProvider);

    return AppScaffold(
      title: 'Produtos',
      floatingActionButton: permissions.canCreate('produtos')
          ? FloatingActionButton(
              onPressed: () => context.push('/produtos/novo'),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchField(
              hintText: 'Buscar produto...',
              controller: _searchCtrl,
              onChanged: _onSearch,
            ),
          ),
          Expanded(
            child: products.when(
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Nenhum produto encontrado',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(productsProvider(_search)),
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final p = list[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              (p.isService ? AppColors.info : AppColors.success)
                                  .withAlpha(25),
                          child: Icon(
                            p.isService
                                ? Icons.build_outlined
                                : Icons.inventory_2,
                            color: p.isService
                                ? AppColors.info
                                : AppColors.success,
                          ),
                        ),
                        title: Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${formatCurrency(p.price)} • Estoque: ${p.stock}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/produtos/${p.id}'),
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
