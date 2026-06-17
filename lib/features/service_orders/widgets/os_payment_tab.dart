import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../data/models/service_order.dart';
import '../../../data/repositories/service_order_repository.dart';

enum _PayStatus {
  pagoAgora('pago_agora', 'À Vista'),
  parcelado('parcelado', 'Parcelado'),
  pendente('pendente', 'Pendente');

  final String value;
  final String label;
  const _PayStatus(this.value, this.label);
}

class _Parcela {
  DateTime date;
  double valor;
  final bool isEntrada;
  _Parcela({required this.date, required this.valor, this.isEntrada = false});
}

// Métodos para À Vista
const _avistaMethods = [
  ('dinheiro', 'Dinheiro', Icons.money),
  ('pix', 'Pix', Icons.qr_code),
  ('cartao_debito', 'Débito', Icons.credit_card_outlined),
  ('cartao_credito', 'Crédito', Icons.credit_card),
  ('transferencia', 'Transferência', Icons.account_balance_outlined),
  ('outros', 'Outros', Icons.more_horiz),
];

// Métodos para Parcelado
const _parceladoMethods = [
  ('crediario', 'Crediário', Icons.calendar_month_outlined),
  ('cartao_credito', 'Cartão Crédito', Icons.credit_card),
  ('boleto', 'Boleto', Icons.receipt_outlined),
];

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
  final _currencyFmt =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _downPayCtrl = TextEditingController();

  _PayStatus _status = _PayStatus.pagoAgora;
  String _method = 'dinheiro';
  DateTime _date = DateTime.now();
  int _installments = 1;
  int _intervalDays = 30;
  List<_Parcela> _parcelas = [];
  bool _loading = false;

  bool get _isClosed => const [
        'finalizada',
        'faturada',
        'cancelada',
        'estornada',
      ].contains(widget.order.status.toLowerCase());

  double get _totalValue {
    if ((widget.order.valorTotalCentavos ?? 0) > 0) {
      return widget.order.valorTotalCentavos! / 100.0;
    }
    return widget.order.itens
        .fold(0.0, (s, i) => s + i.valorTotalCentavos / 100.0);
  }

  double get _downPayment {
    final raw = _downPayCtrl.text.trim().replaceAll(',', '.');
    return (double.tryParse(raw) ?? 0.0).clamp(0.0, _totalValue);
  }

  bool get _hasInstallmentsSupport =>
      _status == _PayStatus.parcelado &&
      (_method == 'crediario' || _method == 'boleto');

  bool get _hasDownPaymentSupport => _hasInstallmentsSupport;

  String _methodLabel(String m) {
    const all = [..._avistaMethods, ..._parceladoMethods];
    return all
        .firstWhere((e) => e.$1 == m,
            orElse: () => (m, m, Icons.payment))
        .$2;
  }

  @override
  void dispose() {
    _downPayCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _generateParcelas() {
    final toInstall =
        _totalValue - (_hasDownPaymentSupport ? _downPayment : 0);
    if (toInstall <= 0 || _installments <= 0) return;

    final result = <_Parcela>[];
    if (_hasDownPaymentSupport && _downPayment > 0) {
      result.add(_Parcela(date: _date, valor: _downPayment, isEntrada: true));
    }

    final baseCents = (toInstall / _installments * 100).floor();
    final lastCents =
        (toInstall * 100).round() - baseCents * (_installments - 1);

    for (var i = 0; i < _installments; i++) {
      final due = DateTime(
        _date.year,
        _date.month,
        _date.day + _intervalDays * (i + 1),
      );
      result.add(_Parcela(
        date: due,
        valor: (i == _installments - 1 ? lastCents : baseCents) / 100.0,
      ));
    }
    setState(() => _parcelas = result);
  }

  void _addParcela() {
    final base = _parcelas.isEmpty ? _date : _parcelas.last.date;
    final next = DateTime(
        base.year, base.month, base.day + _intervalDays);
    final currentSum =
        _parcelas.fold(0.0, (s, p) => s + p.valor);
    final restante = (_totalValue - currentSum).clamp(0.0, _totalValue);
    setState(() => _parcelas.add(_Parcela(date: next, valor: restante)));
  }

  Future<void> _pickParcelaDate(int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _parcelas[index].date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
    );
    if (picked != null && mounted) {
      setState(() => _parcelas[index].date = picked);
    }
  }

  Future<void> _finalizar() async {
    if (_totalValue <= 0) {
      _snack('Adicione itens à OS antes de finalizar.', Colors.orange);
      return;
    }
    if (_status == _PayStatus.parcelado &&
        _hasInstallmentsSupport &&
        _parcelas.isEmpty) {
      _snack('Gere ou adicione as parcelas antes de finalizar.', Colors.orange);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalizar OS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: ${_currencyFmt.format(_totalValue)}'),
            Text('Situação: ${_status.label}'),
            if (_status != _PayStatus.pendente)
              Text('Forma: ${_methodLabel(_method)}'),
            Text('Data: ${_dateFmt.format(_date)}'),
            if (_hasInstallmentsSupport && _parcelas.isNotEmpty)
              Text(
                  'Parcelas: ${_parcelas.where((p) => !p.isEntrada).length}'),
            const SizedBox(height: 10),
            const Text('Confirmar finalização?',
                style: TextStyle(fontSize: 13)),
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
      List<Map<String, dynamic>>? parcelasPayload;
      if (_hasInstallmentsSupport && _parcelas.isNotEmpty) {
        parcelasPayload = _parcelas
            .map((p) => {
                  'data': '${p.date.year}-${p.date.month.toString().padLeft(2, '0')}-${p.date.day.toString().padLeft(2, '0')}',
                  'valor': p.valor,
                  'tipo': p.isEntrada ? 'entrada' : 'parcela',
                })
            .toList();
      }

      await _repo.finalizar(
        widget.order.id,
        widget.order.organizationId,
        paymentMethod:
            _status == _PayStatus.pendente ? 'pendente' : _method,
        totalCents: (_totalValue * 100).round(),
        paymentDate: _date,
        paymentStatus: _status.value,
        installments: _installments,
        parcelas: parcelasPayload,
      );

      widget.onChanged();
      if (mounted) _snack('OS finalizada com sucesso!', Colors.green);
    } catch (e) {
      if (mounted) _snack('Erro: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: bg),
    );
  }

  // -------------------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total card
              _TotalCard(value: _totalValue, currency: _currencyFmt),
              const SizedBox(height: 16),

              if (_isClosed) ...[
                _ClosedCard(order: widget.order, dateFmt: _dateFmt),
              ] else ...[
                // Status selector
                _SectionLabel('Como será o pagamento?', theme),
                const SizedBox(height: 8),
                _StatusSelector(
                  current: _status,
                  onChanged: (s) {
                    setState(() {
                      _status = s;
                      _parcelas = [];
                      if (s == _PayStatus.pagoAgora) {
                        _method = 'dinheiro';
                      } else if (s == _PayStatus.parcelado) {
                        _method = 'crediario';
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Data do pagamento
                _SectionLabel(
                  _method == 'crediario'
                      ? 'Data base das parcelas'
                      : 'Data do pagamento',
                  theme,
                ),
                const SizedBox(height: 8),
                _DateField(
                    date: _date, fmt: _dateFmt, onTap: _pickDate),
                const SizedBox(height: 20),

                // À Vista
                if (_status == _PayStatus.pagoAgora) ...[
                  _SectionLabel('Forma de pagamento', theme),
                  const SizedBox(height: 8),
                  _MethodChips(
                    methods: _avistaMethods,
                    selected: _method,
                    onChanged: (m) => setState(() => _method = m),
                  ),
                ],

                // Parcelado
                if (_status == _PayStatus.parcelado) ...[
                  _SectionLabel('Forma de parcelamento', theme),
                  const SizedBox(height: 8),
                  _MethodChips(
                    methods: _parceladoMethods,
                    selected: _method,
                    onChanged: (m) => setState(() {
                      _method = m;
                      _parcelas = [];
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Crediário / Boleto
                  if (_hasDownPaymentSupport) ...[
                    _DownPaymentField(
                      ctrl: _downPayCtrl,
                      totalValue: _totalValue,
                      currency: _currencyFmt,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('Nº de parcelas', theme),
                            const SizedBox(height: 8),
                            _NumberField(
                              value: _installments,
                              min: 1,
                              max: _hasInstallmentsSupport ? 48 : 24,
                              onChanged: (v) =>
                                  setState(() => _installments = v),
                            ),
                          ],
                        ),
                      ),
                      if (_hasInstallmentsSupport) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel('Intervalo', theme),
                              const SizedBox(height: 8),
                              _IntervalDropdown(
                                value: _intervalDays,
                                onChanged: (v) =>
                                    setState(() => _intervalDays = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_hasInstallmentsSupport) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _generateParcelas,
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: Text(_parcelas.isEmpty
                            ? 'Gerar Parcelas'
                            : 'Regerar Parcelas'),
                      ),
                    ),
                  ],
                  if (_parcelas.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _ParcelasTable(
                      parcelas: _parcelas,
                      currency: _currencyFmt,
                      dateFmt: _dateFmt,
                      totalValue: _totalValue,
                      onPickDate: _pickParcelaDate,
                      onValueChanged: (i, v) =>
                          setState(() => _parcelas[i].valor = v),
                      onRemove: (i) =>
                          setState(() => _parcelas.removeAt(i)),
                      onAdd: _addParcela,
                    ),
                  ],
                  if (_hasInstallmentsSupport && _parcelas.isEmpty) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _addParcela,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Adicionar parcela manualmente'),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              style: BorderStyle.solid, width: 1,
                              color: Colors.grey)),
                    ),
                  ],
                ],

                // Pendente
                if (_status == _PayStatus.pendente) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule_outlined,
                            color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'A OS será finalizada com pagamento pendente. '
                            'O cliente pagará posteriormente.',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _finalizar,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _loading ? 'Finalizando...' : 'Finalizar OS',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade600),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
        if (_loading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _TotalCard extends StatelessWidget {
  final double value;
  final NumberFormat currency;
  const _TotalCard({required this.value, required this.currency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Valor total da OS',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer
                      .withValues(alpha: 0.7))),
          const SizedBox(height: 4),
          Text(
            currency.format(value),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosedCard extends StatelessWidget {
  final ServiceOrder order;
  final DateFormat dateFmt;
  const _ClosedCard({required this.order, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color c;
    switch (order.status.toLowerCase()) {
      case 'finalizada':
        c = Colors.green;
      case 'faturada':
        c = Colors.purple;
      case 'cancelada':
        c = Colors.red;
      default:
        c = Colors.grey;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: c, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('OS ${order.statusLabel}',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  if (order.dataFechamento != null)
                    Text(
                        'Fechada em ${dateFmt.format(order.dataFechamento!)}',
                        style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final _PayStatus current;
  final ValueChanged<_PayStatus> onChanged;

  const _StatusSelector(
      {required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const options = _PayStatus.values;
    return Row(
      children: options
          .map((s) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _SelectBtn(
                    label: s.label,
                    selected: current == s,
                    onTap: () => onChanged(s),
                    theme: theme,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _SelectBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _SelectBtn({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : null,
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.dividerColor,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: selected ? theme.colorScheme.primary : null,
            fontWeight: selected ? FontWeight.w700 : null,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _MethodChips extends StatelessWidget {
  final List<(String, String, IconData)> methods;
  final String selected;
  final ValueChanged<String> onChanged;

  const _MethodChips({
    required this.methods,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: methods.map((m) {
        final isSelected = selected == m.$1;
        return ChoiceChip(
          avatar: Icon(m.$3,
              size: 16,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : null),
          label: Text(m.$2),
          selected: isSelected,
          onSelected: (_) => onChanged(m.$1),
          selectedColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : null,
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
        );
      }).toList(),
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime date;
  final DateFormat fmt;
  final VoidCallback onTap;

  const _DateField(
      {required this.date, required this.fmt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18),
            const SizedBox(width: 10),
            Text(fmt.format(date), style: theme.textTheme.bodyLarge),
            const Spacer(),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _DownPaymentField extends StatelessWidget {
  final TextEditingController ctrl;
  final double totalValue;
  final NumberFormat currency;

  const _DownPaymentField({
    required this.ctrl,
    required this.totalValue,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
            'Entrada (${currency.format(totalValue)} total)', theme),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
          ],
          decoration: InputDecoration(
            prefixText: 'R\$ ',
            hintText: '0,00',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _NumberField({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _NumBtn(
          icon: Icons.remove,
          onTap: value > min ? () => onChanged(value - 1) : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$value× ',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        _NumBtn(
          icon: Icons.add,
          onTap: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _NumBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NumBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 18,
            color: onTap == null
                ? Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3)
                : null),
      ),
    );
  }
}

class _IntervalDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _IntervalDropdown(
      {required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [7, 15, 30, 60, 90];
    return DropdownButtonFormField<int>(
      initialValue: options.contains(value) ? value : 30,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: options
          .map((d) => DropdownMenuItem(
              value: d, child: Text('$d dias')))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _ParcelasTable extends StatelessWidget {
  final List<_Parcela> parcelas;
  final NumberFormat currency;
  final DateFormat dateFmt;
  final double totalValue;
  final ValueChanged<int> onPickDate;
  final void Function(int, double) onValueChanged;
  final ValueChanged<int> onRemove;
  final VoidCallback onAdd;

  const _ParcelasTable({
    required this.parcelas,
    required this.currency,
    required this.dateFmt,
    required this.totalValue,
    required this.onPickDate,
    required this.onValueChanged,
    required this.onRemove,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sumTotal = parcelas.fold(0.0, (s, p) => s + p.valor);
    final diff = sumTotal - totalValue;
    final regularCount =
        parcelas.where((p) => !p.isEntrada).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  parcelas.any((p) => p.isEntrada)
                      ? 'Entrada + $regularCount parcela${regularCount != 1 ? 's' : ''}'
                      : '$regularCount parcela${regularCount != 1 ? 's' : ''}',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (diff.abs() > 0.01)
                  Text(
                    diff > 0
                        ? '+${currency.format(diff.abs())}'
                        : '-${currency.format(diff.abs())}',
                    style: TextStyle(
                      color: diff > 0 ? Colors.red : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const Divider(height: 16),
            ...parcelas.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              return _ParcelaRow(
                index: i,
                parcela: p,
                currency: currency,
                dateFmt: dateFmt,
                onPickDate: () => onPickDate(i),
                onValueChanged: (v) => onValueChanged(i, v),
                onRemove: p.isEntrada ? null : () => onRemove(i),
              );
            }),
            const SizedBox(height: 8),
            Divider(height: 1,
                color: theme.dividerColor.withValues(alpha: 0.5)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total do plano',
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600)),
                  Text(
                    currency.format(sumTotal),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Adicionar parcela'),
              style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParcelaRow extends StatefulWidget {
  final int index;
  final _Parcela parcela;
  final NumberFormat currency;
  final DateFormat dateFmt;
  final VoidCallback onPickDate;
  final ValueChanged<double> onValueChanged;
  final VoidCallback? onRemove;

  const _ParcelaRow({
    required this.index,
    required this.parcela,
    required this.currency,
    required this.dateFmt,
    required this.onPickDate,
    required this.onValueChanged,
    required this.onRemove,
  });

  @override
  State<_ParcelaRow> createState() => _ParcelaRowState();
}

class _ParcelaRowState extends State<_ParcelaRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.parcela.valor.toStringAsFixed(2).replaceAll('.', ','));
  }

  @override
  void didUpdateWidget(covariant _ParcelaRow old) {
    super.didUpdateWidget(old);
    if (old.parcela.valor != widget.parcela.valor) {
      final newText = widget.parcela.valor
          .toStringAsFixed(2)
          .replaceAll('.', ',');
      if (_ctrl.text != newText) _ctrl.text = newText;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.parcela;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              p.isEntrada ? 'Ent.' : '${widget.index + 1}ª',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: p.isEntrada
                    ? theme.colorScheme.primary
                    : null,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: widget.onPickDate,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.dateFmt.format(p.date),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _ctrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
              ],
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall,
              decoration: InputDecoration(
                prefixText: 'R\$ ',
                prefixStyle: theme.textTheme.bodySmall,
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 8),
              ),
              onChanged: (v) {
                final parsed =
                    double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
                widget.onValueChanged(parsed);
              },
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 32,
            child: widget.onRemove != null
                ? IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.close, size: 16),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    color: Colors.red.shade400,
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final ThemeData theme;
  const _SectionLabel(this.text, this.theme);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: theme.textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w600));
  }
}
