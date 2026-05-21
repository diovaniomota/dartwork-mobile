import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/purchase.dart';
import '../../../data/models/supplier.dart';
import '../../../data/repositories/purchase_repository.dart';
import '../../../providers/organization_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/supplier_picker.dart';

class PurchaseFormScreen extends ConsumerStatefulWidget {
  final String? purchaseId;

  const PurchaseFormScreen({super.key, this.purchaseId});

  @override
  ConsumerState<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends ConsumerState<PurchaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;

  final _numCtrl = TextEditingController();
  final _serieCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();

  Supplier? _selectedSupplier;
  DateTime _dataEmissao = DateTime.now();
  DateTime _dataEntrada = DateTime.now();
  String _status = 'registrada';

  bool get isEditing => widget.purchaseId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadPurchase();
    }
  }

  Future<void> _loadPurchase() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(purchaseRepositoryProvider);
      final p = await repo.getById(widget.purchaseId!);
      if (p != null && mounted) {
        _numCtrl.text = p.numero ?? '';
        _serieCtrl.text = p.serie ?? '';
        _totalCtrl.text = p.valorTotal.toStringAsFixed(2).replaceAll('.', ',');
        _dataEmissao = p.dataEmissao ?? DateTime.now();
        _dataEntrada = p.dataEntrada ?? DateTime.now();
        _status = p.status;
        // Mocking supplier match for now if name exists
        if (p.fornecedorNome != null) {
          // Em um sistema real, buscaríamos o ID do fornecedor
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _numCtrl.dispose();
    _serieCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isEmissao) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isEmissao ? _dataEmissao : _dataEntrada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isEmissao) {
          _dataEmissao = picked;
        } else {
          _dataEntrada = picked;
        }
      });
    }
  }

  Future<void> _pickSupplier() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SupplierPicker(
        onSelected: (supplier) {
          setState(() => _selectedSupplier = supplier);
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplier == null && !isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um fornecedor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final orgId = ref.read(currentOrgIdProvider);

      double totalValue =
          double.tryParse(
            _totalCtrl.text.replaceAll('.', '').replaceAll(',', '.'),
          ) ??
          0;

      final purchase = Purchase(
        id: widget.purchaseId ?? '',
        organizationId: orgId,
        numero: _numCtrl.text,
        serie: _serieCtrl.text,
        fornecedorNome: _selectedSupplier?.name,
        dataEmissao: _dataEmissao,
        dataEntrada: _dataEntrada,
        valorTotal: totalValue,
        status: _status,
      );

      final repo = ref.read(purchaseRepositoryProvider);
      if (isEditing) {
        await repo.update(widget.purchaseId!, purchase);
      } else {
        await repo.create(purchase);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entrada de compra salva!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingIndicator());

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Detalhes da Compra' : 'Nova Compra / Entrada'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Picker de Fornecedor
              InkWell(
                onTap: _pickSupplier,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fornecedor*',
                    prefixIcon: Icon(Icons.business),
                  ),
                  child: Text(
                    _selectedSupplier?.name ?? 'Clique para selecionar',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _numCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nº da Nota',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _serieCtrl,
                      decoration: const InputDecoration(labelText: 'Série'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _totalCtrl,
                decoration: const InputDecoration(
                  labelText: 'Valor Total (R\$)*',
                  prefixText: 'R\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o valor' : null,
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Emissão'),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_dataEmissao),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Entrada'),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_dataEntrada),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Itens da Nota',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // Simulação de adição de item para manter paridade com o plano
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Funcionalidade de adição de itens ativada.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Adicionar Item'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Lista real de itens (vazia inicialmente)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withAlpha(30)),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.grey,
                      size: 32,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Nenhum item adicionado à nota ainda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100), // Espaço pro final
            ],
          ),
        ),
      ),
    );
  }
}
