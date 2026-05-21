import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/client.dart';
import '../../../data/repositories/client_repository.dart';
import '../../../data/repositories/vehicle_repository.dart';
import '../../../providers/organization_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/client_picker.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Formulário de criação/edição de veículo — paridade total com web.
class VehicleFormScreen extends ConsumerStatefulWidget {
  final String? vehicleId;
  const VehicleFormScreen({super.key, this.vehicleId});

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _isLoadingData = false;

  final _plateCtrl = TextEditingController();
  final _renavamCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedClientId;
  String? _selectedClientName;

  bool get isEditing => widget.vehicleId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) _loadVehicle();
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    _renavamCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVehicle() async {
    setState(() => _isLoadingData = true);
    try {
      final repo = ref.read(vehicleRepositoryProvider);
      final v = await repo.getById(widget.vehicleId!);
      if (v != null && mounted) {
        _plateCtrl.text = v.plate;
        _renavamCtrl.text = v.renavam ?? '';
        _brandCtrl.text = v.brand ?? '';
        _modelCtrl.text = v.model ?? '';
        _yearCtrl.text = v.year ?? '';
        _colorCtrl.text = v.color ?? '';
        _notesCtrl.text = v.notes ?? '';
        _selectedClientId = v.clientId;
        // Carregar nome do cliente se tiver client_id
        if (v.clientId != null) {
          final clientRepo = ref.read(clientRepositoryProvider);
          final client = await clientRepo.getById(v.clientId!);
          if (client != null && mounted) {
            _selectedClientName = client.name;
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingData = false);
  }

  void _pickClient() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ClientPicker(
        onSelected: (ClientModel client) {
          setState(() {
            _selectedClientId = client.id;
            _selectedClientName = client.name;
          });
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final orgId = ref.read(currentOrgIdProvider);
      if (orgId == null) return;
      final repo = ref.read(vehicleRepositoryProvider);
      final data = {
        'organization_id': orgId,
        'client_id': _selectedClientId,
        'placa': _plateCtrl.text.trim().toUpperCase(),
        'renavam': _renavamCtrl.text.trim().isEmpty
            ? null
            : _renavamCtrl.text.trim(),
        'marca': _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        'modelo':
            _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
        'ano': _yearCtrl.text.trim().isEmpty ? null : _yearCtrl.text.trim(),
        'cor': _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
        'observacoes':
            _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      };
      if (isEditing) {
        await repo.update(widget.vehicleId!, data);
      } else {
        await repo.create(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Veículo atualizado!' : 'Veículo criado!',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carregando...')),
        body: const LoadingIndicator(),
      );
    }
    return AppScaffold(
      title: isEditing ? 'Editar Veículo' : 'Novo Veículo',
      actions: [
        TextButton.icon(
          onPressed: _loading ? null : _save,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: const Text('Salvar'),
        ),
      ],
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cliente Proprietário
              Text(
                'Cliente Proprietário',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickClient,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Cliente',
                    suffixIcon: Icon(Icons.search),
                  ),
                  child: Text(
                    _selectedClientName ?? 'Selecione o Cliente',
                    style: TextStyle(
                      color: _selectedClientName != null
                          ? null
                          : Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ),
              if (_selectedClientId != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedClientId = null;
                        _selectedClientName = null;
                      });
                    },
                    child: const Text('Remover cliente'),
                  ),
                ),
              const SizedBox(height: 16),
              // Dados do Veículo
              Text(
                'Dados do Veículo',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _plateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Placa *',
                  hintText: 'ABC-1234',
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Placa obrigatória' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _renavamCtrl,
                decoration: const InputDecoration(labelText: 'Renavam'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brandCtrl,
                decoration: const InputDecoration(
                  labelText: 'Marca',
                  hintText: 'Ex: Toyota',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Modelo',
                  hintText: 'Ex: Corolla XEi',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _yearCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ano',
                        hintText: '2023/2024',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _colorCtrl,
                      decoration: const InputDecoration(labelText: 'Cor'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Observações'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
