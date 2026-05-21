import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/sale.dart';
import '../../../data/models/product.dart';
import '../../../data/models/client.dart';
import '../../../data/repositories/sale_repository.dart';
import '../../../providers/organization_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/common_widgets.dart';

import '../../../shared/widgets/client_picker.dart';
import '../../../shared/widgets/product_picker.dart';

final saleDetailProvider = FutureProvider.family<Sale?, String>((
  ref,
  id,
) async {
  if (id == 'novo') return null;
  final repo = ref.read(saleRepositoryProvider);
  return await repo.getById(id);
});

class SaleFormScreen extends ConsumerStatefulWidget {
  final String id;
  const SaleFormScreen({super.key, required this.id});

  @override
  ConsumerState<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends ConsumerState<SaleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  ClientModel? _selectedClient;
  String _status = 'pending';
  DateTime _date = DateTime.now();
  String _paymentMethod = 'Dinheiro';
  final _notesCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0,00');

  // Controle de Múltiplos Itens (Produtos da Venda)
  List<SaleItem> _items = [];

  bool get isEditing => widget.id != 'novo';

  @override
  void dispose() {
    _notesCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  void _loadData(Sale sale) {
    if (_notesCtrl.text.isNotEmpty) {
      return; // já processado
    }

    _status = sale.status;
    _date = sale.date;
    _paymentMethod = sale.paymentMethod ?? 'Dinheiro';
    _notesCtrl.text = sale.notes ?? '';
    _discountCtrl.text = sale.discount.toStringAsFixed(2).replaceAll('.', ',');

    if (sale.clientId != null) {
      // Mockamos um ClientModel para manter o state seccional,
      // numa versão robusta a tela usaria o provider direto pro fetch de id.
      _selectedClient = ClientModel(
        id: sale.clientId!,
        organizationId: sale.organizationId,
        name: sale.clientName ?? 'Cliente',
      );
    }

    if (sale.items != null) {
      _items = List.from(sale.items!);
    }
  }

  double get _subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.total);
  }

  double get _total {
    final dSource = _discountCtrl.text.replaceAll('.', '').replaceAll(',', '.');
    final discount = double.tryParse(dSource) ?? 0;
    return _subtotal - discount;
  }

  void _addItem(Product product, double qty) {
    final newItem = SaleItem(
      saleId: isEditing ? widget.id : '',
      productId: product.id,
      productName: product.name,
      quantity: qty,
      unitPrice: product.price,
      total: qty * product.price,
    );
    setState(() {
      _items.add(newItem);
    });
  }

  Future<void> _showProductPicker() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProductPicker(onSelected: (p) => _addItem(p, 1)),
    );
  }

  Future<void> _showClientPicker() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          ClientPicker(onSelected: (c) => setState(() => _selectedClient = c)),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A venda precisa ter ao menos um produto.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final orgId = ref.read(currentOrgIdProvider);
      if (orgId == null) {
        throw Exception('Organização não identificada');
      }

      final discountSource = _discountCtrl.text
          .replaceAll('.', '')
          .replaceAll(',', '.');
      final parsedDiscount = double.tryParse(discountSource) ?? 0;

      final saleData = {
        'organization_id': orgId,
        if (_selectedClient != null) 'client_id': _selectedClient!.id,
        'date': _date.toIso8601String(),
        'status': _status,
        'subtotal': _subtotal,
        'discount': parsedDiscount,
        'total': _total,
        'payment_method': _paymentMethod,
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      };

      final itemsData = _items
          .map(
            (i) => {
              'product_id': i.productId,
              'quantity': i.quantity,
              'unit_price': i.unitPrice,
              'total': i.total,
            },
          )
          .toList();

      final repo = ref.read(saleRepositoryProvider);
      if (isEditing) {
        await repo.update(widget.id, saleData, itemsData);
      } else {
        await repo.create(saleData, itemsData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venda salva com sucesso!')),
        );
        ref.invalidate(salesProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      final asyncData = ref.watch(saleDetailProvider(widget.id));
      return asyncData.when(
        data: (sale) {
          if (sale != null) {
            _loadData(sale);
          }
          return _buildForm();
        },
        loading: () =>
            const AppScaffold(title: 'Carregando...', body: LoadingIndicator()),
        error: (e, _) => AppScaffold(
          title: 'Erro',
          body: EmptyState(
            title: 'Erro ao carregar',
            subtitle: '$e',
            icon: Icons.error,
          ),
        ),
      );
    }
    return _buildForm();
  }

  Widget _buildForm() {
    return AppScaffold(
      title: isEditing ? 'Editar Venda / Pedido' : 'Nova Venda / Pedido',
      actions: [
        if (_isSaving)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          )
        else
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
      ],
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Seção Cliente ---
                    InkWell(
                      onTap: _showClientPicker,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Cliente Selecionado',
                        ),
                        child: Text(
                          _selectedClient?.name ??
                              'Clique para selecionar o cliente',
                          style: TextStyle(
                            color: _selectedClient == null ? Colors.grey : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Seção Dados ---
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setState(() => _date = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Data da Venda',
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_date),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _paymentMethod,
                            decoration: const InputDecoration(
                              labelText: 'Forma Pgto',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Dinheiro',
                                child: Text('Dinheiro'),
                              ),
                              DropdownMenuItem(
                                value: 'Cartão C.',
                                child: Text('Cartão C.'),
                              ),
                              DropdownMenuItem(
                                value: 'Cartão D.',
                                child: Text('Cartão D.'),
                              ),
                              DropdownMenuItem(
                                value: 'PIX',
                                child: Text('PIX'),
                              ),
                              DropdownMenuItem(
                                value: 'Boleto',
                                child: Text('Boleto'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _paymentMethod = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status do Pedido',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('Pendente / Aberto'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Concluído / Faturado'),
                        ),
                        DropdownMenuItem(
                          value: 'budget',
                          child: Text('Apenas Orçamento'),
                        ),
                        DropdownMenuItem(
                          value: 'cancelled',
                          child: Text('Cancelado'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                    const SizedBox(height: 24),

                    // --- Titulo dos Produtos ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Produtos e Serviços',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _showProductPicker,
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- Itens Injetados ---
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = _items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: Text(
                      item.productName ??
                          'Item #${item.productId.substring(0, 4)}',
                    ),
                    subtitle: Text(
                      '${item.quantity}x de R\$ ${item.unitPrice.toStringAsFixed(2)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'R\$ ${item.total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() => _items.removeAt(index));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: _items.length),
            ),

            // --- Subtotal e Total ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                        Text(
                          NumberFormat.currency(
                            locale: 'pt_BR',
                            symbol: 'R\$',
                          ).format(_subtotal),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Desconto R\$:',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: TextFormField(
                            controller: _discountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(isDense: true),
                            onChanged: (v) =>
                                setState(() {}), // força redraw do Totaĺ
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: 'pt_BR',
                            symbol: 'R\$',
                          ).format(_total),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText:
                            'Observações do Pedido (Anotações Opcionais)',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
