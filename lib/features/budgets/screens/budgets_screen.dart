import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/digital_quote_repository.dart';
import '../../../data/repositories/service_order_repository.dart';
import '../../../providers/organization_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/common_widgets.dart';

class BudgetViewObject {
  final String id;
  final String source; // 'manual' | 'os'
  final String displayNumber;
  final String status;
  final String approvalStatus;
  final DateTime? approvalRequestedAt;
  final String clientName;
  final double totalValue;
  final bool isApproved;
  final bool isRejected;

  BudgetViewObject({
    required this.id,
    required this.source,
    required this.displayNumber,
    required this.status,
    required this.approvalStatus,
    this.approvalRequestedAt,
    required this.clientName,
    required this.totalValue,
  }) : isApproved = approvalStatus == 'aprovado',
       isRejected = approvalStatus == 'rejeitado';
}

final budgetsProvider = FutureProvider.family<List<BudgetViewObject>, String?>((
  ref,
  search,
) async {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return [];

  final manualRepo = ref.read(digitalQuoteRepositoryProvider);
  final osRepo = ref.read(serviceOrderRepositoryProvider);

  // Fetch from both sources
  final manualQuotes = await manualRepo.getAll(orgId, search: search);
  final osListResult = await osRepo.getAll(orgId, status: null, page: 0);

  // Convert Manual Quotes to Unified Object
  var result = <BudgetViewObject>[];

  for (var quote in manualQuotes) {
    result.add(
      BudgetViewObject(
        id: quote.id,
        source: 'manual',
        displayNumber: quote.quoteNumber != null
            ? 'ORÇ-${quote.quoteNumber.toString().padLeft(5, '0')}'
            : 'ORÇ-00000',
        status: quote.status,
        approvalStatus: quote.approvalStatus,
        approvalRequestedAt: quote.approvalRequestedAt ?? quote.createdAt,
        clientName: quote.clientName ?? 'Cliente não informado',
        totalValue: quote.totalValue,
      ),
    );
  }

  // Filter OS List locally by matching logic from Node API
  for (var os in osListResult) {
    final validStatuses = [
      'aberta',
      'em_andamento',
      'aguardando_peca',
      'aguardando_aprovacao',
      'finalizada',
    ];
    if (!validStatuses.contains(os.status)) {
      continue;
    }

    if (search != null && search.isNotEmpty) {
      bool matchClient =
          os.clientName?.toLowerCase().contains(search.toLowerCase()) ?? false;
      bool matchOs =
          os.id.contains(search) ||
          (os.veiculoPlaca != null && os.veiculoPlaca!.contains(search));
      if (!matchClient && !matchOs) {
        continue;
      }
    }

    result.add(
      BudgetViewObject(
        id: os.id,
        source: 'os',
        displayNumber: 'OS #${os.id.substring(0, 5).toUpperCase()}',
        status: os.status,
        approvalStatus: os.approvalStatus ?? 'nao_solicitado',
        approvalRequestedAt: os.approvalRequestedAt ?? os.dataAbertura,
        clientName: os.clientName ?? 'Cliente não informado',
        totalValue: os.totalValue,
      ),
    );
  }

  // Sort by requested Date
  result.sort((a, b) {
    if (a.approvalRequestedAt == null && b.approvalRequestedAt == null) {
      return 0;
    }
    if (a.approvalRequestedAt == null) return 1;
    if (b.approvalRequestedAt == null) return -1;
    return b.approvalRequestedAt!.compareTo(a.approvalRequestedAt!);
  });

  return result;
});

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
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
      budgetsProvider(_currentSearch.isEmpty ? null : _currentSearch),
    );

    return AppScaffold(
      title: 'Orçamentos Digitais',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/orcamentos/novo'),
        label: const Text('Novo Avulso'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por cliente, ou placa...',
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
                    icon: Icons.assignment_outlined,
                    title: 'Nenhum Orçamento Encontrado',
                    subtitle:
                        'Crie um orçamento avulso, ou envie orçamentos a partir de uma Ordem de Serviço.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(budgetsProvider),
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final item = list[i];

                      Color statusColor = Colors.grey;
                      IconData statusIcon = Icons.info;
                      String statusLabel = item.approvalStatus;

                      if (item.approvalStatus == 'aprovado') {
                        statusColor = Colors.green;
                        statusIcon = Icons.check_circle;
                        statusLabel = 'Aprovado';
                      } else if (item.approvalStatus == 'rejeitado') {
                        statusColor = Colors.red;
                        statusIcon = Icons.cancel;
                        statusLabel = 'Rejeitado';
                      } else if (item.approvalStatus == 'pendente') {
                        statusColor = Colors.orange;
                        statusIcon = Icons.access_time_filled;
                        statusLabel = 'Pendente';
                      } else {
                        statusLabel = 'Não Solicitado';
                        statusColor = Colors.blueGrey;
                        statusIcon = Icons.edit_document;
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
                            item.displayNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.approvalRequestedAt != null)
                                Text(
                                  'Criado em: ${DateFormat('dd/MM/yyyy HH:mm').format(item.approvalRequestedAt!)}',
                                ),
                              Text(
                                item.clientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    margin: const EdgeInsets.only(
                                      top: 4,
                                      right: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.source == 'os'
                                          ? Colors.blue.withAlpha(40)
                                          : Colors.purple.withAlpha(40),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.source == 'os' ? 'O.S' : 'Avulso',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: item.source == 'os'
                                            ? Colors.blue[800]
                                            : Colors.purple[800],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
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
                                ).format(item.totalValue),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            if (item.source == 'os') {
                              context.push('/ordens-servico/${item.id}');
                            } else {
                              context.push('/orcamentos/${item.id}');
                            }
                          },
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const LoadingIndicator(),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Erro ao carregar',
                subtitle: e.toString(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
