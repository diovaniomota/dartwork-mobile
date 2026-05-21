import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../providers/organization_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/common_widgets.dart';

class ReportsSummary {
  final int clientsCount;
  final int vehiclesCount;
  final int productsCount;
  final int serviceOrdersOpen;
  final int serviceOrdersTotal;
  final double salesThisMonth;
  final double purchasesThisMonth;
  final double receivablePending;
  final double payablePending;

  const ReportsSummary({
    this.clientsCount = 0,
    this.vehiclesCount = 0,
    this.productsCount = 0,
    this.serviceOrdersOpen = 0,
    this.serviceOrdersTotal = 0,
    this.salesThisMonth = 0,
    this.purchasesThisMonth = 0,
    this.receivablePending = 0,
    this.payablePending = 0,
  });
}

final reportsSummaryProvider = FutureProvider<ReportsSummary>((ref) async {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return const ReportsSummary();

  Future<List<Map<String, dynamic>>> safeList(
    Future<List<dynamic>> Function() callback,
  ) async {
    try {
      final response = await callback();
      return response.cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }

  Future<int> countRows(String table) async {
    final rows = await safeList(
      () => supabase
          .from(table)
          .select('id')
          .eq('organization_id', orgId)
          .limit(5000),
    );
    return rows.length;
  }

  final now = DateTime.now();
  final firstDayMonth = DateTime(
    now.year,
    now.month,
    1,
  ).toIso8601String().split('T').first;

  final clientsFuture = countRows('clients');
  final vehiclesFuture = countRows('vehicles');
  final productsFuture = countRows('products');

  final osFuture = safeList(
    () => supabase
        .from('ordens_servico')
        .select('status')
        .eq('organization_id', orgId)
        .limit(5000),
  );

  final salesFuture = safeList(
    () => supabase
        .from('sales')
        .select('total')
        .eq('organization_id', orgId)
        .gte('date', firstDayMonth)
        .limit(5000),
  );

  final purchasesFuture = safeList(
    () => supabase
        .from('purchases')
        .select('valor_total')
        .eq('organization_id', orgId)
        .gte('data_entrada', firstDayMonth)
        .limit(5000),
  );

  final receivablesFuture = safeList(
    () => supabase
        .from('finance_receivables')
        .select('amount, status')
        .eq('organization_id', orgId)
        .eq('status', 'pending')
        .limit(5000),
  );

  final payablesFuture = safeList(
    () => supabase
        .from('finance_payables')
        .select('amount, status')
        .eq('organization_id', orgId)
        .eq('status', 'pending')
        .limit(5000),
  );

  final responses = await Future.wait([
    clientsFuture,
    vehiclesFuture,
    productsFuture,
    osFuture,
    salesFuture,
    purchasesFuture,
    receivablesFuture,
    payablesFuture,
  ]);

  final osRows = responses[3] as List<Map<String, dynamic>>;
  final salesRows = responses[4] as List<Map<String, dynamic>>;
  final purchaseRows = responses[5] as List<Map<String, dynamic>>;
  final receivablesRows = responses[6] as List<Map<String, dynamic>>;
  final payablesRows = responses[7] as List<Map<String, dynamic>>;

  double toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  final salesTotal = salesRows.fold<double>(
    0,
    (sum, row) => sum + toDouble(row['total']),
  );
  final purchasesTotal = purchaseRows.fold<double>(
    0,
    (sum, row) => sum + toDouble(row['valor_total']),
  );
  final receivablesPending = receivablesRows.fold<double>(
    0,
    (sum, row) => sum + toDouble(row['amount']),
  );
  final payablesPending = payablesRows.fold<double>(
    0,
    (sum, row) => sum + toDouble(row['amount']),
  );

  final osOpen = osRows.where((row) {
    final status = row['status']?.toString().toLowerCase() ?? '';
    return status == 'aberta' || status == 'em_andamento';
  }).length;

  return ReportsSummary(
    clientsCount: responses[0] as int,
    vehiclesCount: responses[1] as int,
    productsCount: responses[2] as int,
    serviceOrdersTotal: osRows.length,
    serviceOrdersOpen: osOpen,
    salesThisMonth: salesTotal,
    purchasesThisMonth: purchasesTotal,
    receivablePending: receivablesPending,
    payablePending: payablesPending,
  );
});

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(reportsSummaryProvider);
    final formatCurrency = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return AppScaffold(
      title: 'Relatórios',
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.invalidate(reportsSummaryProvider),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: summary.when(
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _HeadlineCard(
              title: 'Resumo Financeiro do Mês',
              revenue: formatCurrency.format(data.salesThisMonth),
              expense: formatCurrency.format(data.purchasesThisMonth),
              receivable: formatCurrency.format(data.receivablePending),
              payable: formatCurrency.format(data.payablePending),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.people_rounded,
                    title: 'Clientes',
                    value: '${data.clientsCount}',
                    onTap: () => context.push('/clientes'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.directions_car_rounded,
                    title: 'Veículos',
                    value: '${data.vehiclesCount}',
                    onTap: () => context.push('/veiculos'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.inventory_rounded,
                    title: 'Produtos',
                    value: '${data.productsCount}',
                    onTap: () => context.push('/produtos'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.build_rounded,
                    title: 'OS Abertas',
                    value:
                        '${data.serviceOrdersOpen}/${data.serviceOrdersTotal}',
                    onTap: () => context.push('/ordens-servico'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atalhos de análise',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => context.push('/vendas'),
                          icon: const Icon(Icons.shopping_cart_rounded),
                          label: const Text('Vendas'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => context.push('/compras'),
                          icon: const Icon(Icons.local_shipping_rounded),
                          label: const Text('Compras'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => context.push('/receber'),
                          icon: const Icon(Icons.arrow_downward_rounded),
                          label: const Text('Receber'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => context.push('/pagar'),
                          icon: const Icon(Icons.arrow_upward_rounded),
                          label: const Text('Pagar'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => context.push('/caixa'),
                          icon: const Icon(
                            Icons.account_balance_wallet_rounded,
                          ),
                          label: const Text('Caixa'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () =>
            const LoadingIndicator(message: 'Calculando indicadores...'),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Erro ao carregar relatórios',
          subtitle: error.toString(),
        ),
      ),
    );
  }
}

class _HeadlineCard extends StatelessWidget {
  final String title;
  final String revenue;
  final String expense;
  final String receivable;
  final String payable;

  const _HeadlineCard({
    required this.title,
    required this.revenue,
    required this.expense,
    required this.receivable,
    required this.payable,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withAlpha(220),
            colorScheme.secondary.withAlpha(210),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withAlpha(225),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _line('Receitas', revenue),
          _line('Despesas', expense),
          _line('Receber pendente', receivable),
          _line('Pagar pendente', payable),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withAlpha(205),
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(icon, color: colorScheme.primary, size: 18),
              ),
              const SizedBox(height: 8),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
