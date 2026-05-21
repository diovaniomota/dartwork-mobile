import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/sale.dart';
import '../../data/repositories/sale_repository.dart';
import '../../providers/auth_provider.dart';

class SalePicker extends ConsumerStatefulWidget {
  final Function(Sale) onSelected;

  const SalePicker({super.key, required this.onSelected});

  @override
  ConsumerState<SalePicker> createState() => _SalePickerState();
}

class _SalePickerState extends ConsumerState<SalePicker> {
  String _search = '';
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final orgId = ref.watch(userProfileProvider).value?.organizationId ?? '';
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
              Text('Importar de Venda', style: theme.textTheme.titleLarge),
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
              hintText: 'Buscar vendas...',
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
            child: FutureBuilder<List<Sale>>(
              future: ref
                  .read(saleRepositoryProvider)
                  .getAll(orgId, search: _search, status: 'completed'),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erro ao carregar vendas',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tente novamente em alguns instantes.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final sales = snapshot.data ?? [];

                if (sales.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma venda concluída encontrada.'),
                  );
                }

                return ListView.separated(
                  itemCount: sales.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    return ListTile(
                      title: Text('Venda #${sale.id.substring(0, 8)}'),
                      subtitle: Text(
                        'Cliente: ${sale.clientName ?? 'Não informado'}\nTotal: R\$ ${sale.total.toStringAsFixed(2)}',
                      ),
                      isThreeLine: true,
                      leading: const CircleAvatar(
                        child: Icon(Icons.shopping_cart),
                      ),
                      onTap: () {
                        widget.onSelected(sale);
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
