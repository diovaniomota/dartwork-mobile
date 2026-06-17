import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../data/models/service_order.dart';
import '../../../data/repositories/service_order_repository.dart';

class OsItemsTab extends StatefulWidget {
  final ServiceOrder order;
  final VoidCallback onChanged;

  const OsItemsTab({
    super.key,
    required this.order,
    required this.onChanged,
  });

  @override
  State<OsItemsTab> createState() => _OsItemsTabState();
}

class _OsItemsTabState extends State<OsItemsTab> {
  final _repo = ServiceOrderRepository();
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  bool _loading = false;

  bool get _isReadOnly =>
      ['finalizada', 'faturada', 'cancelada', 'estornada']
          .contains(widget.order.status.toLowerCase());

  int get _totalCents => widget.order.itens.fold(
        0,
        (sum, item) => sum + item.valorTotalCentavos,
      );

  Future<void> _removeItem(OsItem item) async {
    if (item.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover item'),
        content: Text('Remover "${item.descricao}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remover',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await _repo.removeItem(item.id!);
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddItemSheet() async {
    final tipoCtrl = ValueNotifier<String>('servico');
    final descCtrl = TextEditingController();
    final qtdCtrl = TextEditingController(text: '1');
    final valorCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Adicionar Item',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 12),
              // Tipo
              ValueListenableBuilder<String>(
                valueListenable: tipoCtrl,
                builder: (ctx, tipo, child) => SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'servico', label: Text('Serviço')),
                    ButtonSegment(value: 'produto', label: Text('Produto')),
                  ],
                  selected: {tipo},
                  onSelectionChanged: (v) => tipoCtrl.value = v.first,
                ),
              ),
              const SizedBox(height: 12),
              // Descrição
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descrição *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Informe a descrição' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Quantidade
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: qtdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Qtd *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Valor unitário
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: valorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Valor unitário *',
                        border: OutlineInputBorder(),
                        prefixText: 'R\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[\d,\.]')),
                      ],
                      validator: (v) {
                        final parsed = double.tryParse(
                            (v ?? '').replaceAll(',', '.'));
                        if (parsed == null || parsed < 0) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final qtd = int.parse(qtdCtrl.text.trim());
                    final unitPrice = double.parse(
                        valorCtrl.text.trim().replaceAll(',', '.'));
                    final unitCents = (unitPrice * 100).round();
                    final totalCents = unitCents * qtd;

                    Navigator.pop(ctx);

                    setState(() => _loading = true);
                    try {
                      await _repo.addItem(widget.order.id, {
                        'organization_id': widget.order.organizationId,
                        'tipo': tipoCtrl.value,
                        'descricao': descCtrl.text.trim(),
                        'quantidade': qtd,
                        'valor_unitario_centavos': unitCents,
                        'valor_total_centavos': totalCents,
                      });
                      // Atualiza valor total da OS
                      final newTotal =
                          _totalCents + totalCents;
                      await _repo.update(widget.order.id, {
                        'valor_total_centavos': newTotal,
                      });
                      widget.onChanged();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Erro: $e'),
                              backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  },
                  child: const Text('Adicionar'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    descCtrl.dispose();
    qtdCtrl.dispose();
    valorCtrl.dispose();
    tipoCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itens = widget.order.itens;

    return Stack(
      children: [
        Column(
          children: [
            // Total card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total da OS',
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer)),
                  Text(
                    _currency.format(_totalCents / 100),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            // Lista de itens
            Expanded(
              child: itens.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.build_circle_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha:0.3)),
                          const SizedBox(height: 8),
                          Text(
                            _isReadOnly
                                ? 'Nenhum item registrado'
                                : 'Nenhum item\nToque em + para adicionar',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha:0.5)),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                      itemCount: itens.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final item = itens[i];
                        return Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  item.tipo == 'servico'
                                      ? Colors.blue.withValues(alpha:0.15)
                                      : Colors.orange.withValues(alpha:0.15),
                              child: Icon(
                                item.tipo == 'servico'
                                    ? Icons.build
                                    : Icons.inventory_2,
                                size: 18,
                                color: item.tipo == 'servico'
                                    ? Colors.blue
                                    : Colors.orange,
                              ),
                            ),
                            title: Text(item.descricao,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${item.quantidade}x  ${_currency.format(item.unitPrice)}',
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currency.format(item.totalPrice),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold),
                                ),
                                if (!_isReadOnly) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 20),
                                    onPressed: () => _removeItem(item),
                                    tooltip: 'Remover',
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        // FAB adicionar
        if (!_isReadOnly)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: _loading ? null : _showAddItemSheet,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            ),
          ),
        // Loading overlay
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
}
