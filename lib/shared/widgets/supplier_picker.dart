import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/supplier.dart';
import '../../data/repositories/supplier_repository.dart';
import '../../providers/organization_provider.dart';
import '../../core/theme/app_colors.dart';

class SupplierPicker extends ConsumerStatefulWidget {
  final Function(Supplier) onSelected;

  const SupplierPicker({super.key, required this.onSelected});

  @override
  ConsumerState<SupplierPicker> createState() => _SupplierPickerState();
}

class _SupplierPickerState extends ConsumerState<SupplierPicker> {
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
              Text('Selecionar Fornecedor', style: theme.textTheme.titleLarge),
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
              hintText: 'Nome ou CNPJ...',
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
            child: FutureBuilder<List<Supplier>>(
              future: ref
                  .read(supplierRepositoryProvider)
                  .getAll(orgId, search: _search),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }

                final suppliers = snapshot.data ?? [];

                if (suppliers.isEmpty) {
                  return const Center(
                    child: Text('Nenhum fornecedor encontrado.'),
                  );
                }

                return ListView.separated(
                  itemCount: suppliers.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final supplier = suppliers[index];
                    return ListTile(
                      title: Text(
                        supplier.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        supplier.document ?? 'Sem documento',
                        style: theme.textTheme.bodySmall,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withAlpha(20),
                        child: const Icon(
                          Icons.business,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      onTap: () {
                        widget.onSelected(supplier);
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
