import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/transporter.dart';
import '../../../providers/organization_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/common_widgets.dart';
import 'transporters_screen.dart';

final transporterDetailProvider = FutureProvider.family<Transporter?, String>((
  ref,
  id,
) async {
  if (id == 'novo') return null;
  final repo = ref.read(transporterRepositoryProvider);
  return await repo.getById(id);
});

class TransporterFormScreen extends ConsumerStatefulWidget {
  final String id;
  const TransporterFormScreen({super.key, required this.id});

  @override
  ConsumerState<TransporterFormScreen> createState() =>
      _TransporterFormScreenState();
}

class _TransporterFormScreenState extends ConsumerState<TransporterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final _nameCtrl = TextEditingController();
  final _documentCtrl = TextEditingController();
  final _ieCtrl = TextEditingController(); // Inscrição Estadual
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _complementCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zipCodeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool get isEditing => widget.id != 'novo';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _documentCtrl.dispose();
    _ieCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _numberCtrl.dispose();
    _complementCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCodeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _loadData(Transporter tran) {
    if (_nameCtrl.text.isNotEmpty) return;
    _nameCtrl.text = tran.name;
    _documentCtrl.text = tran.document ?? '';
    _ieCtrl.text = tran.stateRegistration ?? '';
    _phoneCtrl.text = tran.phone ?? '';
    _emailCtrl.text = tran.email ?? '';
    _addressCtrl.text = tran.address ?? '';
    _numberCtrl.text = tran.number ?? '';
    _complementCtrl.text = tran.complement ?? '';
    _neighborhoodCtrl.text = tran.neighborhood ?? '';
    _cityCtrl.text = tran.city ?? '';
    _stateCtrl.text = tran.state ?? '';
    _zipCodeCtrl.text = tran.zipCode ?? '';
    _notesCtrl.text = tran.notes ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final orgId = ref.read(currentOrgIdProvider);
      if (orgId == null) throw Exception('Organização não identificada');
      final repo = ref.read(transporterRepositoryProvider);

      final data = {
        'organization_id': orgId,
        'name': _nameCtrl.text.trim(),
        'document': _documentCtrl.text.trim().isEmpty
            ? null
            : _documentCtrl.text.replaceAll(RegExp(r'\D'), ''),
        'state_registration': _ieCtrl.text.trim().isEmpty
            ? null
            : _ieCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim().isEmpty
            ? null
            : _addressCtrl.text.trim(),
        'number': _numberCtrl.text.trim().isEmpty
            ? null
            : _numberCtrl.text.trim(),
        'complement': _complementCtrl.text.trim().isEmpty
            ? null
            : _complementCtrl.text.trim(),
        'neighborhood': _neighborhoodCtrl.text.trim().isEmpty
            ? null
            : _neighborhoodCtrl.text.trim(),
        'city': _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim().isEmpty
            ? null
            : _stateCtrl.text.trim().toUpperCase(),
        'zip_code': _zipCodeCtrl.text.trim().isEmpty
            ? null
            : _zipCodeCtrl.text.trim(),
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      };

      if (isEditing) {
        await repo.update(widget.id, data);
      } else {
        await repo.create(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transportadora salva com sucesso!')),
        );
        ref.invalidate(transportersProvider);
        context.pop();
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
      final asyncData = ref.watch(transporterDetailProvider(widget.id));
      return asyncData.when(
        data: (tran) {
          if (tran != null) _loadData(tran);
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
      title: isEditing ? 'Editar Transportadora' : 'Nova Transportadora',
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
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Razão Social / Nome*',
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _documentCtrl,
                      decoration: const InputDecoration(labelText: 'CNPJ/CPF'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _ieCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Inscrição Estadual',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Telefone'),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              const Text(
                'Endereço',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _zipCodeCtrl,
                      decoration: const InputDecoration(labelText: 'CEP'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _neighborhoodCtrl,
                      decoration: const InputDecoration(labelText: 'Bairro'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(labelText: 'Endereço'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _numberCtrl,
                      decoration: const InputDecoration(labelText: 'Nº'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _complementCtrl,
                decoration: const InputDecoration(labelText: 'Complemento'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(labelText: 'Cidade'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _stateCtrl,
                      decoration: const InputDecoration(labelText: 'UF'),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 2,
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observações Internas (Ex: RNTRC)',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
