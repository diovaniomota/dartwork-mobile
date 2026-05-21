import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/financial_entry.dart';
import '../../../data/repositories/financial_repository.dart';
import '../../../providers/organization_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/common_widgets.dart';

// Parameters class due to Riverpod Provider Family limits to 1 argument
class FinancialFilter {
  final String? search;
  final String type; // 'receivable' ou 'payable'
  final String status;

  const FinancialFilter({this.search, required this.type, this.status = 'all'});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancialFilter &&
          runtimeType == other.runtimeType &&
          search == other.search &&
          type == other.type &&
          status == other.status;

  @override
  int get hashCode => search.hashCode ^ type.hashCode ^ status.hashCode;
}

final financialsProvider =
    FutureProvider.family<List<FinancialEntry>, FinancialFilter>((
      ref,
      filter,
    ) async {
      final orgId = ref.watch(currentOrgIdProvider);
      if (orgId == null) return [];
      final repo = ref.read(financialRepositoryProvider);
      return await repo.getAll(
        orgId,
        search: filter.search,
        type: filter.type,
        status: filter.status,
      );
    });

class FinancialScreen extends ConsumerStatefulWidget {
  final String type; // 'receivable' or 'payable'
  const FinancialScreen({super.key, required this.type});

  @override
  ConsumerState<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends ConsumerState<FinancialScreen> {
  final _searchCtrl = TextEditingController();
  String? _searchQuery;
  String _currentStatus = 'all'; // all, pending, paid, overdue

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() => _searchQuery = value.isEmpty ? null : value);
  }

  String get _screenTitle =>
      widget.type == 'receivable' ? 'Contas a Receber' : 'Contas a Pagar';

  @override
  Widget build(BuildContext context) {
    final filter = FinancialFilter(
      search: _searchQuery,
      type: widget.type,
      status: _currentStatus,
    );
    final asyncData = ref.watch(financialsProvider(filter));

    return AppScaffold(
      title: _screenTitle,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/financeiro/${widget.type}/novo'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar lançamento...',
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

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todos',
                  value: 'all',
                  groupValue: _currentStatus,
                  onChanged: (v) => setState(() => _currentStatus = v),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pendentes',
                  value: 'pending',
                  groupValue: _currentStatus,
                  onChanged: (v) => setState(() => _currentStatus = v),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Vencidos',
                  value: 'overdue',
                  groupValue: _currentStatus,
                  onChanged: (v) => setState(() => _currentStatus = v),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pagos/Recebidos',
                  value: 'paid',
                  groupValue: _currentStatus,
                  onChanged: (v) => setState(() => _currentStatus = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: asyncData.when(
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Nenhum lançamento',
                    subtitle: 'Use o botão + para adicionar',
                  );
                }

                // Calculando Totalizadores Rápidos
                double total = list.fold(0, (sum, item) => sum + item.amount);

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(financialsProvider(filter)),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Total Exibido:  ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(total)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                            final entry = list[i];
                            final isPaid = entry.status == 'paid';
                            final isOverdue =
                                entry.status == 'pending' &&
                                entry.dueDate.isBefore(DateTime.now());

                            Color statusColor = Colors.orange;
                            IconData statusIcon = Icons.schedule;
                            if (isPaid) {
                              statusColor = Colors.green;
                              statusIcon = Icons.check_circle;
                            } else if (isOverdue) {
                              statusColor = Colors.red;
                              statusIcon = Icons.warning;
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
                                  entry.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Venc: ${DateFormat('dd/MM/yyyy').format(entry.dueDate)}',
                                    ),
                                    if (entry.clientName != null)
                                      Text(
                                        'Cliente: ${entry.clientName}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    if (entry.supplierName != null)
                                      Text(
                                        'Fornec: ${entry.supplierName}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                  ],
                                ),
                                trailing: Text(
                                  NumberFormat.currency(
                                    locale: 'pt_BR',
                                    symbol: 'R\$',
                                  ).format(entry.amount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: widget.type == 'receivable'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                onTap: () => context.push(
                                  '/financeiro/${widget.type}/${entry.id}',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (b) {
        if (b) onChanged(value);
      },
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : (isDarkMode ? Colors.white70 : Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
