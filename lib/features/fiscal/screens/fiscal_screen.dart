import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../providers/organization_provider.dart';
import '../../../data/models/nota_fiscal.dart';
import '../../../data/repositories/fiscal_repository.dart';
import '../../../shared/widgets/app_drawer.dart';

final fiscalStatusFilterProvider = StateProvider<String>((ref) => 'todos');

final fiscalListProvider = FutureProvider.family<List<NotaFiscal>, String>((
  ref,
  tipoModelo,
) async {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return [];

  final status = ref.watch(fiscalStatusFilterProvider);
  final repo = ref.read(fiscalRepositoryProvider);
  return repo.getAll(orgId, tipoModelo: tipoModelo, status: status);
});

class FiscalScreen extends ConsumerWidget {
  final String tipoModelo;
  // '55' = NF-e, '65' = NFC-e, 'nfse' = NFS-e

  const FiscalScreen({super.key, required this.tipoModelo});

  String get _title {
    if (tipoModelo == '55') return 'NF-e (Notas Fiscais)';
    if (tipoModelo == '65') return 'NFC-e (Consumidor)';
    return 'NFS-e (Serviços)';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(fiscalStatusFilterProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(fiscalListProvider(tipoModelo)),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildFilterChips(context, ref, statusFilter, isDarkMode),
          Expanded(child: _buildList(ref, isDarkMode)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (tipoModelo == 'nfse') {
            context.push('/nfse/novo');
          } else if (tipoModelo == '65') {
            context.push('/nfce/novo');
          } else {
            context.push('/nfe/novo');
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    WidgetRef ref,
    String statusFilter,
    bool isDarkMode,
  ) {
    final statuses = ['todos', 'rascunho', 'processando', 'autorizada', 'erro'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: statuses.map((status) {
          final isSelected = statusFilter == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(status.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(fiscalStatusFilterProvider.notifier).state = status;
                }
              },
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDarkMode ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList(WidgetRef ref, bool isDark) {
    final asyncData = ref.watch(fiscalListProvider(tipoModelo));

    return asyncData.when(
      data: (notas) {
        if (notas.isEmpty) {
          return const Center(child: Text('Nenhuma nota encontrada.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notas.length,
          itemBuilder: (context, index) {
            final nota = notas[index];
            return _buildNotaCard(context, nota, isDark);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Erro: \$e')),
    );
  }

  Widget _buildNotaCard(BuildContext context, NotaFiscal nota, bool isDark) {
    final colorStatus = _getStatusColor(nota.status);
    final dataFormat = nota.dataEmissao != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(nota.dataEmissao!)
        : 'Sem data';
    final valFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(nota.valorTotal);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showFiscalDetails(context, nota),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Nº ${nota.numero ?? "-"} / Sér. ${nota.serie ?? "-"}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorStatus.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      nota.status?.toUpperCase() ?? 'INDEFINIDO',
                      style: TextStyle(
                        color: colorStatus,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nota.clienteNome ?? 'Consumidor Final',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (nota.clienteDocumento != null &&
                  nota.clienteDocumento!.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.badge, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      nota.clienteDocumento!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dataFormat,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    valFormat,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.blue[300] : Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == 'autorizada') return Colors.green;
    if (status == 'erro' || status == 'rejeitada') return Colors.red;
    if (status == 'processando' || status == 'pendente') return Colors.orange;
    if (status == 'cancelada') return Colors.grey;
    return Colors.blue;
  }

  void _showFiscalDetails(BuildContext context, NotaFiscal nota) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumo da Nota',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Modelo: ${nota.tipoModelo == '55'
                          ? 'NF-e'
                          : nota.tipoModelo == '65'
                          ? 'NFC-e'
                          : 'NFS-e'}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),
            _detailRow('Nº da Nota', nota.numero?.toString() ?? 'N/A'),
            _detailRow('Série', nota.serie?.toString() ?? 'N/A'),
            _detailRow('Status', nota.status?.toUpperCase() ?? 'PENDENTE'),
            _detailRow(
              'Emissão',
              nota.dataEmissao != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(nota.dataEmissao!)
                  : 'N/A',
            ),
            const Divider(height: 32),
            _detailRow(
              'Cliente/Tomador',
              nota.clienteNome ?? 'Consumidor Final',
            ),
            _detailRow('Documento', nota.clienteDocumento ?? 'N/A'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Valor Total',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'pt_BR',
                      symbol: 'R\$',
                      decimalDigits: 2,
                    ).format(nota.valorTotal),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ação de impressão enviada.')),
                );
              },
              icon: const Icon(Icons.print),
              label: const Text('Imprimir / Visualizar PDF'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
