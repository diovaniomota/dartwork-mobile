import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/financial_entry.dart';
import '../../../data/repositories/financial_repository.dart';
import '../../../providers/organization_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/client_picker.dart';
import '../../../shared/widgets/supplier_picker.dart';

final financialDetailProvider =
    FutureProvider.family<FinancialEntry?, Map<String, dynamic>>((
      ref,
      params,
    ) async {
      final id = params['id'] as String;
      final type = params['type'] as String;

      if (id == 'novo') return null;
      final repo = ref.read(financialRepositoryProvider);
      return await repo.getById(id, type: type);
    });

class FinancialFormScreen extends ConsumerStatefulWidget {
  final String id;
  final String type; // 'receivable' ou 'payable'

  const FinancialFormScreen({super.key, required this.id, required this.type});

  @override
  ConsumerState<FinancialFormScreen> createState() =>
      _FinancialFormScreenState();
}

class _FinancialFormScreenState extends ConsumerState<FinancialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(); // Em reais (texto)
  final _notesCtrl = TextEditingController();

  DateTime _dueDate = DateTime.now();
  String _status = 'pending'; // pending, paid, cancelled
  String? _selectedClientId;
  String? _selectedSupplierId;
  String? _selectedName;

  bool get isEditing => widget.id != 'novo';

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _loadData(FinancialEntry entry) {
    if (_descCtrl.text.isNotEmpty) return;
    _descCtrl.text = entry.description;
    _amountCtrl.text = entry.amount.toStringAsFixed(2).replaceAll('.', ',');
    _notesCtrl.text = entry.notes ?? '';
    _dueDate = entry.dueDate;
    _status = entry.status;
    _selectedClientId = entry.clientId;
    _selectedSupplierId = entry.supplierId;
    _selectedName = entry.clientName ?? entry.supplierName;
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _showPicker() {
    if (widget.type == 'receivable') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ClientPicker(
          onSelected: (client) {
            setState(() {
              _selectedClientId = client.id;
              _selectedName = client.name;
              _selectedSupplierId = null;
            });
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SupplierPicker(
          onSelected: (supplier) {
            setState(() {
              _selectedSupplierId = supplier.id;
              _selectedName = supplier.name;
              _selectedClientId = null;
            });
          },
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final orgId = ref.read(currentOrgIdProvider);
      if (orgId == null) throw Exception('Organização não identificada');

      // Limpar formatação BRL to Double
      String amountSource = _amountCtrl.text
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();
      double parsedAmount = double.tryParse(amountSource) ?? 0;

      final data = {
        'organization_id': orgId,
        'description': _descCtrl.text.trim(),
        'amount': parsedAmount,
        'due_date': _dueDate.toIso8601String().split('T')[0],
        'status': _status,
        'type': widget.type,
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'client_id': _selectedClientId,
        'supplier_id': _selectedSupplierId,
        if (_status == 'paid')
          'payment_date': DateTime.now().toIso8601String().split('T')[0],
      };

      final repo = ref.read(financialRepositoryProvider);
      if (isEditing) {
        await repo.update(widget.id, data, type: widget.type);
      } else {
        await repo.create(data, type: widget.type);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lançamento salvo com sucesso!')),
        );
        context.pop();
        // Invalidate a lista que mandou ali via refresh indicator, pra atualizar a view
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      final data = ref.watch(
        financialDetailProvider({'id': widget.id, 'type': widget.type}),
      );
      return data.when(
        data: (entry) {
          if (entry != null) _loadData(entry);
          return _buildForm();
        },
        loading: () =>
            const AppScaffold(title: 'Carregando...', body: LoadingIndicator()),
        error: (e, _) => AppScaffold(
          title: 'Erro',
          body: EmptyState(
            title: 'Falha ao processar lançamento',
            subtitle: '$e',
            icon: Icons.error,
          ),
        ),
      );
    }
    return _buildForm();
  }

  Widget _buildForm() {
    final titlePrefix = widget.type == 'receivable' ? 'Receita' : 'Despesa';
    return AppScaffold(
      title: isEditing ? 'Editar $titlePrefix' : 'Nova $titlePrefix',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descrição do Lançamento*',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _showPicker,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: widget.type == 'receivable'
                        ? 'Cliente'
                        : 'Fornecedor',
                    prefixIcon: Icon(
                      widget.type == 'receivable'
                          ? Icons.person
                          : Icons.business,
                    ),
                    suffixIcon: _selectedName != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _selectedName = null;
                                _selectedClientId = null;
                                _selectedSupplierId = null;
                              });
                            },
                          )
                        : const Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    _selectedName ?? 'Selecionar (Opcional)',
                    style: TextStyle(
                      color: _selectedName == null ? Colors.grey : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Valor (R\$)*',
                        prefixText: 'R\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Informe o valor' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: _selectDueDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Vencimento*',
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(_dueDate)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'Situação',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'pending',
                    label: Text('Pendente'),
                    icon: Icon(Icons.schedule),
                  ),
                  ButtonSegment(
                    value: 'paid',
                    label: Text('Baixado/Pago'),
                    icon: Icon(Icons.check_circle),
                  ),
                  // if (false) ButtonSegment(value: 'cancelled', label: Text('Cancelado')),
                ],
                selected: {_status},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() => _status = newSelection.first);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return _status == 'paid'
                          ? Colors.green.withAlpha(50)
                          : Theme.of(context).primaryColor.withAlpha(50);
                    }
                    return Colors.transparent;
                  }),
                ),
              ),

              const Divider(height: 48),

              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observações Internas (Opcional)',
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
