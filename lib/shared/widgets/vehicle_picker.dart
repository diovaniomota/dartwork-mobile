import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/vehicle.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../../data/services/vehicle_plate_lookup_service.dart';
import '../../providers/organization_provider.dart';

class VehiclePicker extends ConsumerStatefulWidget {
  final Function(Vehicle) onSelected;
  final String? clientId;

  const VehiclePicker({super.key, required this.onSelected, this.clientId});

  @override
  ConsumerState<VehiclePicker> createState() => _VehiclePickerState();
}

class _VehiclePickerState extends ConsumerState<VehiclePicker> {
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showCreateVehicleDialog(String organizationId) async {
    final created = await showDialog<Vehicle>(
      context: context,
      builder: (_) => _CreateVehicleDialog(
        organizationId: organizationId,
        clientId: widget.clientId,
      ),
    );

    if (!mounted || created == null) return;
    widget.onSelected(created);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final orgId = ref.watch(currentOrgIdProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Selecionar Veículo', style: theme.textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por placa, modelo, marca...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _search = '';
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (val) => setState(() => _search = val),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: (orgId == null || orgId.isEmpty)
                  ? null
                  : () => _showCreateVehicleDialog(orgId),
              icon: const Icon(Icons.add),
              label: const Text('Novo veículo'),
            ),
          ),
          const SizedBox(height: 16),
          if (orgId == null || orgId.isEmpty)
            const Expanded(
              child: Center(child: Text('Organização não identificada.')),
            )
          else
            Expanded(
              child: FutureBuilder<List<Vehicle>>(
                future: ref
                    .read(vehicleRepositoryProvider)
                    .getAll(orgId, search: _search),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}'));
                  }

                  final vehicles = snapshot.data ?? [];
                  if (vehicles.isEmpty) {
                    return const Center(
                      child: Text('Nenhum veículo encontrado.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: vehicles.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];
                      final normalizedPlate = vehicle.plate.trim();
                      final initial = normalizedPlate.isNotEmpty
                          ? normalizedPlate.substring(0, 1).toUpperCase()
                          : '?';
                      final details = <String>[
                        if ((vehicle.model ?? '').trim().isNotEmpty)
                          vehicle.model!.trim(),
                        if ((vehicle.brand ?? '').trim().isNotEmpty)
                          vehicle.brand!.trim(),
                      ];

                      return ListTile(
                        title: Text(vehicle.plate),
                        subtitle: Text(
                          details.isEmpty
                              ? 'Sem detalhes'
                              : details.join(' • '),
                        ),
                        leading: CircleAvatar(child: Text(initial)),
                        onTap: () {
                          widget.onSelected(vehicle);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CreateVehicleDialog extends ConsumerStatefulWidget {
  final String organizationId;
  final String? clientId;

  const _CreateVehicleDialog({required this.organizationId, this.clientId});

  @override
  ConsumerState<_CreateVehicleDialog> createState() =>
      _CreateVehicleDialogState();
}

class _CreateVehicleDialogState extends ConsumerState<_CreateVehicleDialog> {
  final _plateCtrl = TextEditingController();
  final _renavamCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  Timer? _plateDebounce;
  bool _saving = false;
  bool _searchingPlate = false;
  String? _error;
  String? _lastLookupPlate;

  @override
  void dispose() {
    _plateDebounce?.cancel();
    _plateCtrl.dispose();
    _renavamCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _sanitizePlate(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
  }

  void _setControllerIfValue(TextEditingController ctrl, String? value) {
    if (value == null || value.trim().isEmpty) return;
    ctrl.text = value.trim();
  }

  void _schedulePlateLookup() {
    _plateDebounce?.cancel();
    final clean = _sanitizePlate(_plateCtrl.text);
    if (clean.length != 7 || clean == _lastLookupPlate) return;

    _plateDebounce = Timer(const Duration(milliseconds: 450), () {
      _lookupPlate(manual: false);
    });
  }

  Future<void> _lookupPlate({required bool manual}) async {
    final clean = _sanitizePlate(_plateCtrl.text);
    if (clean.length != 7) {
      if (manual) {
        setState(
          () => _error = 'Placa inválida. Digite 7 caracteres para consultar.',
        );
      }
      return;
    }

    if (_searchingPlate) return;
    if (!manual && clean == _lastLookupPlate) return;

    setState(() {
      _searchingPlate = true;
      if (manual) _error = null;
    });

    final result = await ref
        .read(vehiclePlateLookupServiceProvider)
        .lookup(clean);
    if (!mounted) return;

    if (result.success && result.data != null) {
      final info = result.data!;
      _lastLookupPlate = clean;
      _setControllerIfValue(_brandCtrl, info.brand);
      _setControllerIfValue(_modelCtrl, info.model);
      _setControllerIfValue(_colorCtrl, info.color);
      _setControllerIfValue(_yearCtrl, info.year);
      _setControllerIfValue(_renavamCtrl, info.renavam);
      setState(() {
        _searchingPlate = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _searchingPlate = false;
      if (manual) {
        _error = result.error ?? 'Não foi possível consultar a placa.';
      }
    });
  }

  Future<void> _save() async {
    final plate = _plateCtrl.text.trim().toUpperCase();
    if (plate.isEmpty) {
      setState(() => _error = 'Informe a placa do veículo.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(vehicleRepositoryProvider);
      final data = {
        'organization_id': widget.organizationId,
        if (widget.clientId != null && widget.clientId!.isNotEmpty)
          'client_id': widget.clientId,
        'placa': plate,
        'renavam': _renavamCtrl.text.trim().isEmpty
            ? null
            : _renavamCtrl.text.trim(),
        'marca': _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        'modelo': _modelCtrl.text.trim().isEmpty
            ? null
            : _modelCtrl.text.trim(),
        'ano': _yearCtrl.text.trim().isEmpty ? null : _yearCtrl.text.trim(),
        'cor': _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
        'observacoes': _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
      };

      final created = await repo.create(data);
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Erro ao criar veículo: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Veículo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _plateCtrl,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 8,
                    decoration: const InputDecoration(
                      labelText: 'Placa *',
                      hintText: 'ABC-1234',
                      counterText: '',
                    ),
                    buildCounter:
                        (
                          BuildContext context, {
                          required int currentLength,
                          required bool isFocused,
                          required int? maxLength,
                        }) {
                          return null;
                        },
                    onChanged: (_) => _schedulePlateLookup(),
                    onSubmitted: (_) => _lookupPlate(manual: true),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  height: 56,
                  child: FilledButton(
                    onPressed: _searchingPlate || _saving
                        ? null
                        : () => _lookupPlate(manual: true),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _searchingPlate
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.search),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _modelCtrl,
              decoration: const InputDecoration(labelText: 'Modelo'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _brandCtrl,
              decoration: const InputDecoration(labelText: 'Marca'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _yearCtrl,
              decoration: const InputDecoration(labelText: 'Ano'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _colorCtrl,
              decoration: const InputDecoration(labelText: 'Cor'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _renavamCtrl,
              decoration: const InputDecoration(labelText: 'Renavam'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Observações'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(_saving ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }
}
