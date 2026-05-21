import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../../providers/organization_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_colors.dart';

class ProductPicker extends ConsumerStatefulWidget {
  final Function(Product) onSelected;

  const ProductPicker({super.key, required this.onSelected});

  @override
  ConsumerState<ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends ConsumerState<ProductPicker> {
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orgId = ref.watch(currentOrgIdProvider) ?? '';
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Selecionar Produto', style: theme.textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Nome, GTIN ou SKU...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _search = '';
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (val) => setState(() => _search = val),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: ref
                  .read(productRepositoryProvider)
                  .getAll(orgId, search: _search),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }

                final products = snapshot.data ?? [];

                if (products.isEmpty) {
                  return const Center(
                    child: Text('Nenhum produto encontrado.'),
                  );
                }

                return ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      title: Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'GTIN: ${product.gtin ?? 'N/A'} | SKU: ${product.sku ?? 'N/A'}',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatCurrency(product.price),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (product.stock > 0)
                            Text(
                              'Estoque: ${product.stock}',
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withAlpha(20),
                        child: const Icon(Icons.inventory_2, size: 20),
                      ),
                      onTap: () {
                        widget.onSelected(product);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
