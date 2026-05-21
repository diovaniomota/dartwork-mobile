import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/sale.dart';
import '../../../data/repositories/sale_repository.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/common_widgets.dart';

enum _SalesViewMode { board, list }

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  String _currentStatus = 'all';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  _SalesViewMode _viewMode = _SalesViewMode.board;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(salesProvider(_currentStatus));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: 'Vendas',
      subtitle: 'Kanban comercial e funil de pedidos',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vendas/novo'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova venda'),
      ),
      body: asyncData.when(
        data: (list) {
          final filtered = _applySearch(list);
          final summary = _buildSummary(list);
          final buckets = _buildBuckets(filtered);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(salesProvider(_currentStatus));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SalesHero(summary: summary),
                        const SizedBox(height: 12),
                        _KpiStrip(summary: summary),
                        const SizedBox(height: 12),
                        _SearchInput(
                          controller: _searchCtrl,
                          hint:
                              'Buscar por cliente, pedido, status ou pagamento',
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        _StatusFilters(
                          currentValue: _currentStatus,
                          onChanged: (value) {
                            setState(() {
                              _currentStatus = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              'Resultados: ${filtered.length}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            _ViewModeToggle(
                              mode: _viewMode,
                              onChanged: (mode) {
                                setState(() {
                                  _viewMode = mode;
                                });
                              },
                            ),
                          ],
                        ),
                        if (_searchQuery.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextButton.icon(
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('Limpar busca'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Nenhum pedido encontrado',
                      subtitle: _searchQuery.trim().isEmpty
                          ? 'Use Nova venda para registrar um pedido.'
                          : 'Ajuste o termo de busca ou troque o filtro de status.',
                    ),
                  )
                else if (_viewMode == _SalesViewMode.board)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final bucket = buckets[index];
                        final visual = _statusVisual(bucket.status, isDark);

                        return _StatusLane(
                          visual: visual,
                          bucket: bucket,
                          onOpenSale: (saleId) =>
                              context.push('/vendas/$saleId'),
                        );
                      }, childCount: buckets.length),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final sale = filtered[index];
                        final visual = _statusVisual(sale.status, isDark);

                        return _SaleListCard(
                          sale: sale,
                          visual: visual,
                          onTap: () => context.push('/vendas/${sale.id}'),
                        );
                      }, childCount: filtered.length),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const LoadingIndicator(message: 'Carregando vendas...'),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Erro ao carregar vendas',
          subtitle: e.toString(),
        ),
      ),
    );
  }

  List<Sale> _applySearch(List<Sale> list) {
    final term = _searchQuery.trim().toLowerCase();
    if (term.isEmpty) return list;

    return list.where((sale) {
      final id = sale.id.toLowerCase();
      final shortId = sale.id.length >= 8
          ? sale.id.substring(0, 8).toLowerCase()
          : sale.id.toLowerCase();
      final client = (sale.clientName ?? '').toLowerCase();
      final payment = (sale.paymentMethod ?? '').toLowerCase();
      final status = sale.status.toLowerCase();

      return id.contains(term) ||
          shortId.contains(term) ||
          client.contains(term) ||
          payment.contains(term) ||
          status.contains(term);
    }).toList();
  }

  _SalesSummary _buildSummary(List<Sale> list) {
    int pending = 0;
    int completed = 0;
    int cancelled = 0;
    int budget = 0;
    double gross = 0;

    for (final sale in list) {
      gross += sale.total;
      switch (sale.status) {
        case 'pending':
          pending += 1;
          break;
        case 'completed':
          completed += 1;
          break;
        case 'cancelled':
          cancelled += 1;
          break;
        case 'budget':
          budget += 1;
          break;
      }
    }

    final avgTicket = list.isNotEmpty ? gross / list.length : 0.0;

    return _SalesSummary(
      totalOrders: list.length,
      pending: pending,
      completed: completed,
      cancelled: cancelled,
      budget: budget,
      gross: gross,
      avgTicket: avgTicket,
    );
  }

  List<_SalesBucket> _buildBuckets(List<Sale> sales) {
    final statusOrder = ['pending', 'budget', 'completed', 'cancelled'];
    final grouped = <String, List<Sale>>{};

    for (final sale in sales) {
      grouped.putIfAbsent(sale.status, () => []).add(sale);
    }

    final buckets = <_SalesBucket>[];

    for (final status in statusOrder) {
      final items = grouped[status] ?? const <Sale>[];
      if (items.isEmpty) continue;

      double total = 0;
      for (final item in items) {
        total += item.total;
      }

      buckets.add(_SalesBucket(status: status, items: items, total: total));
    }

    for (final entry in grouped.entries) {
      if (statusOrder.contains(entry.key)) continue;
      if (entry.value.isEmpty) continue;

      double total = 0;
      for (final item in entry.value) {
        total += item.total;
      }

      buckets.add(
        _SalesBucket(status: entry.key, items: entry.value, total: total),
      );
    }

    return buckets;
  }
}

class _SalesHero extends StatelessWidget {
  final _SalesSummary summary;

  const _SalesHero({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF146C79), Color(0xFF0D4F8C)]
              : const [Color(0xFF159B8A), Color(0xFF1A7FA6)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.brandGreen : AppColors.brandBlue)
                .withAlpha(72),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_mall_rounded, color: Colors.white),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatCurrency(summary.gross),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Volume total de pedidos',
                  style: TextStyle(
                    color: Colors.white.withAlpha(220),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${summary.totalOrders} pedidos',
            style: TextStyle(
              color: Colors.white.withAlpha(225),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiStrip extends StatelessWidget {
  final _SalesSummary summary;

  const _KpiStrip({required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MiniMetric(label: 'Pendentes', value: '${summary.pending}'),
      _MiniMetric(label: 'Concluidas', value: '${summary.completed}'),
      _MiniMetric(label: 'Canceladas', value: '${summary.cancelled}'),
      _MiniMetric(label: 'Orcamentos', value: '${summary.budget}'),
      _MiniMetric(
        label: 'Ticket medio',
        value: formatCurrency(summary.avgTicket),
      ),
    ];

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => items[index],
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: items.length,
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchInput({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close_rounded),
              )
            : null,
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  final String currentValue;
  final ValueChanged<String> onChanged;

  const _StatusFilters({required this.currentValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final filters = const [
      ('Todas', 'all'),
      ('Pendentes', 'pending'),
      ('Concluidas', 'completed'),
      ('Canceladas', 'cancelled'),
      ('Orcamentos', 'budget'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((entry) {
          final label = entry.$1;
          final value = entry.$2;
          final selected = currentValue == value;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) => onChanged(value),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  final _SalesViewMode mode;
  final ValueChanged<_SalesViewMode> onChanged;

  const _ViewModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_SalesViewMode>(
      segments: const [
        ButtonSegment<_SalesViewMode>(
          value: _SalesViewMode.board,
          label: Text('Kanban'),
          icon: Icon(Icons.view_carousel_rounded, size: 16),
        ),
        ButtonSegment<_SalesViewMode>(
          value: _SalesViewMode.list,
          label: Text('Lista'),
          icon: Icon(Icons.view_list_rounded, size: 16),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) return;
        onChanged(selection.first);
      },
      style: const ButtonStyle(
        visualDensity: VisualDensity(horizontal: -2, vertical: -2),
      ),
    );
  }
}

class _StatusLane extends StatelessWidget {
  final _StatusVisual visual;
  final _SalesBucket bucket;
  final ValueChanged<String> onOpenSale;

  const _StatusLane({
    required this.visual,
    required this.bucket,
    required this.onOpenSale,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: visual.color.withAlpha(28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Icon(visual.icon, size: 14, color: visual.color),
                      const SizedBox(width: 5),
                      Text(
                        visual.label,
                        style: TextStyle(
                          color: visual.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${bucket.items.length} pedidos',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Text(
                  formatCurrency(bucket.total),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 175,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: bucket.items.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final sale = bucket.items[index];
                  return _SaleBoardCard(
                    sale: sale,
                    visual: visual,
                    onTap: () => onOpenSale(sale.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleBoardCard extends StatelessWidget {
  final Sale sale;
  final _StatusVisual visual;
  final VoidCallback onTap;

  const _SaleBoardCard({
    required this.sale,
    required this.visual,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shortId = sale.id.length >= 6
        ? sale.id.substring(0, 6).toUpperCase()
        : sale.id.toUpperCase();
    final dateLabel = DateFormat('dd/MM HH:mm').format(sale.date);

    return SizedBox(
      width: 230,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  visual.color.withAlpha(18),
                  Theme.of(context).cardColor,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#$shortId',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 14,
                      color: visual.color,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  formatCurrency(sale.total),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  sale.clientName?.isNotEmpty == true
                      ? sale.clientName!
                      : 'Cliente nao informado',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (sale.paymentMethod?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    sale.paymentMethod!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaleListCard extends StatelessWidget {
  final Sale sale;
  final _StatusVisual visual;
  final VoidCallback onTap;

  const _SaleListCard({
    required this.sale,
    required this.visual,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shortId = sale.id.length >= 8
        ? sale.id.substring(0, 8).toUpperCase()
        : sale.id.toUpperCase();

    final dateLabel = DateFormat('dd/MM/yyyy HH:mm').format(sale.date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 10,
                  height: 72,
                  decoration: BoxDecoration(
                    color: visual.color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#$shortId',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          Text(
                            visual.label,
                            style: TextStyle(
                              color: visual.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCurrency(sale.total),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sale.clientName?.isNotEmpty == true
                            ? sale.clientName!
                            : 'Cliente nao informado',
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

_StatusVisual _statusVisual(String status, bool isDark) {
  switch (status) {
    case 'completed':
      return _StatusVisual(
        label: 'Concluida',
        icon: Icons.check_circle_rounded,
        color: isDark ? const Color(0xFF5ED19E) : const Color(0xFF1E9F6E),
      );
    case 'pending':
      return _StatusVisual(
        label: 'Pendente',
        icon: Icons.schedule_rounded,
        color: isDark ? const Color(0xFFFFCC61) : const Color(0xFFCF8A1B),
      );
    case 'cancelled':
      return _StatusVisual(
        label: 'Cancelada',
        icon: Icons.cancel_rounded,
        color: isDark ? const Color(0xFFFF8E87) : const Color(0xFFD35B50),
      );
    case 'budget':
      return _StatusVisual(
        label: 'Orcamento',
        icon: Icons.request_quote_rounded,
        color: isDark ? const Color(0xFF89C1FF) : const Color(0xFF2E76C5),
      );
    default:
      return _StatusVisual(
        label: status,
        icon: Icons.info_outline_rounded,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      );
  }
}

class _StatusVisual {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusVisual({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _SalesSummary {
  final int totalOrders;
  final int pending;
  final int completed;
  final int cancelled;
  final int budget;
  final double gross;
  final double avgTicket;

  const _SalesSummary({
    required this.totalOrders,
    required this.pending,
    required this.completed,
    required this.cancelled,
    required this.budget,
    required this.gross,
    required this.avgTicket,
  });
}

class _SalesBucket {
  final String status;
  final List<Sale> items;
  final double total;

  const _SalesBucket({
    required this.status,
    required this.items,
    required this.total,
  });
}
