import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/purchase.dart';
import '../../../data/repositories/purchase_repository.dart';
import '../../../providers/organization_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/common_widgets.dart';

final purchasesProvider = FutureProvider.family<List<Purchase>, String?>((
  ref,
  search,
) async {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return [];
  final repo = ref.read(purchaseRepositoryProvider);
  return await repo.getAll(orgId, search: search);
});

class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  final _searchController = TextEditingController();
  String _currentSearch = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    setState(() {
      _currentSearch = _searchController.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(
      purchasesProvider(_currentSearch.isEmpty ? null : _currentSearch),
    );

    return AppScaffold(
      title: 'Compras & Entradas',
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/compras/nova'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nº ou fornecedor...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _onSearch,
                ),
              ),
              onSubmitted: (_) => _onSearch(),
            ),
          ),
          Expanded(
            child: asyncData.when(
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long,
                    title: 'Nenhuma Compra Encontrada',
                    subtitle:
                        'Use o botão + para registrar uma entrada ou importar XML.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(purchasesProvider),
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final item = list[i];

                      Color statusColor = Colors.grey;
                      IconData statusIcon = Icons.info;
                      String statusLabel = item.status;

                      if (item.status == 'finalizado') {
                        statusColor = Colors.green;
                        statusIcon = Icons.check_circle;
                        statusLabel = 'Finalizada';
                      } else if (item.status == 'em_digitacao') {
                        statusColor = Colors.orange;
                        statusIcon = Icons.edit;
                        statusLabel = 'Em Digitação';
                      } else if (item.status == 'cancelado') {
                        statusColor = Colors.red;
                        statusIcon = Icons.cancel;
                        statusLabel = 'Cancelada';
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withAlpha(30),
                            child: Icon(statusIcon, color: statusColor),
                          ),
                          title: Text(
                            'NF ${item.numero ?? "S/N"} / Série ${item.serie ?? "-"}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.dataEntrada != null)
                                Text(
                                  'Entrada: ${DateFormat('dd/MM/yyyy').format(item.dataEntrada!)}',
                                ),
                              Text(
                                'Fornec: ${item.fornecedorNome ?? "Não informado"}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Status: $statusLabel',
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                NumberFormat.currency(
                                  locale: 'pt_BR',
                                  symbol: 'R\$',
                                ).format(item.valorTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => context.push('/compras/${item.id}'),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const LoadingIndicator(),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Erro de listagem',
                subtitle: e.toString(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
