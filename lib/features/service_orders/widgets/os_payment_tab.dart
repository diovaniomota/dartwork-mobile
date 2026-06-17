import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/service_order.dart';
import '../../../data/repositories/service_order_repository.dart';

class OsPaymentTab extends StatefulWidget {
  final ServiceOrder order;
  final VoidCallback onChanged;

  const OsPaymentTab({
    super.key,
    required this.order,
    required this.onChanged,
  });

  @override
  State<OsPaymentTab> createState() => _OsPaymentTabState();
}

class _OsPaymentTabState extends State<OsPaymentTab> {
  final _repo = ServiceOrderRepository();
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFmt = DateFormat('dd/MM/yyyy');

  String _paymentMethod = 'dinheiro';
  DateTime _paymentDate = DateTime.now();
  bool _loading = false;

  bool get _isClosed =>
      ['finalizada', 'faturada', 'cancelada', 'estornada']
          .contains(widget.order.status.toLowerCase());

  int get _totalCents =>
      widget.order.valorTotalCentavos ??
      widget.order.itens.fold(0, (s, i) => s + i.valorTotalCentavos);

  static const _methods = [
    ('dinheiro', 'Dinheiro', Icons.money),
    ('pix', 'Pix', Icons.qr_code),
    ('cartao_debito', 'Débito', Icons.credit_card),
    ('cartao_credito', 'Crédito', Icons.credit_card),
    ('transferencia', 'Transferência', Icons.account_balance),
    ('outros', 'Outros', Icons.more_horiz),
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
    );
    if (picked != null && mounted) setState(() => _paymentDate = picked);
  }

  Future<void> _finalizarOS() async {
    if (_totalCents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Adicione itens à OS antes de finalizar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalizar Ordem de Serviço'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: ${_currency.format(_totalCents / 100)}'),
            const SizedBox(height: 4),
            Text(
                'Pagamento: ${_methods.firstWhere((m) => m.$1 == _paymentMethod).$2}'),
            Text('Data: ${_dateFmt.format(_paymentDate)}'),
            const SizedBox(height: 12),
            const Text(
              'Confirmar finalização? Esta ação não pode ser desfeita pelo mobile.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Finalizar')),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await _repo.finalizar(
        widget.order.id,
        widget.order.organizationId,
        paymentMethod: _paymentMethod,
        totalCents: _totalCents,
        paymentDate: _paymentDate,
      );
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OS finalizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao finalizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Valor total',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withOpacity(0.7))),
                    const SizedBox(height: 4),
                    Text(
                      _currency.format(_totalCents / 100),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_isClosed) ...[
                // OS já fechada: mostrar info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: _statusColor(widget.order.status)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('OS ${widget.order.statusLabel}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold)),
                              if (widget.order.dataFechamento != null)
                                Text(
                                  'Fechada em ${_dateFmt.format(widget.order.dataFechamento!)}',
                                  style: theme.textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Forma de pagamento
                Text('Forma de pagamento',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _methods.map((m) {
                    final selected = _paymentMethod == m.$1;
                    return ChoiceChip(
                      avatar: Icon(m.$3,
                          size: 16,
                          color: selected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface),
                      label: Text(m.$2),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _paymentMethod = m.$1),
                      selectedColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        color: selected
                            ? theme.colorScheme.onPrimary
                            : null,
                        fontWeight: selected ? FontWeight.w600 : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Data pagamento
                Text('Data do pagamento',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 10),
                        Text(_dateFmt.format(_paymentDate),
                            style: theme.textTheme.bodyLarge),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Botão finalizar
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _finalizarOS,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Finalizar OS',
                        style: TextStyle(fontSize: 16)),
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade600),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_loading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x44000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'finalizada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      case 'faturada':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
