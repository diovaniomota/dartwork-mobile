import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/supplier.dart';
import '../../../data/repositories/supplier_repository.dart';
import '../../../providers/organization_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/common_widgets.dart';

final supplierRepositoryProvider = Provider((ref) => SupplierRepository());

final suppliersProvider = FutureProvider.family<List<Supplier>, String?>((
  ref,
  search,
) async {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return [];
  final repo = ref.read(supplierRepositoryProvider);
  return await repo.getAll(orgId, search: search);
});

final supplierDetailProvider = FutureProvider.family<Supplier?, String>((
  ref,
  id,
) async {
  if (id == 'novo') return null;
  final repo = ref.read(supplierRepositoryProvider);
  return await repo.getById(id);
});

class SupplierFormScreen extends ConsumerStatefulWidget {
  final String id;
  const SupplierFormScreen({super.key, required this.id});

  @override
  ConsumerState<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends ConsumerState<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final _nameCtrl = TextEditingController();
  final _documentCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
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
    _contactCtrl.dispose();
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

  void _loadData(Supplier supplier) {
    if (_nameCtrl.text.isNotEmpty) return;
    _nameCtrl.text = supplier.name;
    _documentCtrl.text = supplier.document ?? '';
    _contactCtrl.text = supplier.contactName ?? '';
    _phoneCtrl.text = supplier.phone ?? '';
    _emailCtrl.text = supplier.email ?? '';
    _addressCtrl.text = supplier.address ?? '';
    _numberCtrl.text = supplier.number ?? '';
    _complementCtrl.text = supplier.complement ?? '';
    _neighborhoodCtrl.text = supplier.neighborhood ?? '';
    _cityCtrl.text = supplier.city ?? '';
    _stateCtrl.text = supplier.state ?? '';
    _zipCodeCtrl.text = supplier.zipCode ?? '';
    _notesCtrl.text = supplier.notes ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final orgId = ref.read(currentOrgIdProvider);
      if (orgId == null) throw Exception('Organização não encontrada');
      final repo = ref.read(supplierRepositoryProvider);

      final data = {
        'organization_id': orgId,
        'name': _nameCtrl.text.trim(),
        'document': _documentCtrl.text.trim().isEmpty
            ? null
            : _documentCtrl.text.replaceAll(RegExp(r'\D'), ''),
        'contact_name': _contactCtrl.text.trim().isEmpty
            ? null
            : _contactCtrl.text.trim(),
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
          SnackBar(content: Text('Fornecedor salvo com sucesso!')),
        );
        ref.invalidate(suppliersProvider);
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
      final asyncData = ref.watch(supplierDetailProvider(widget.id));
      return asyncData.when(
        data: (supplier) {
          if (supplier != null) _loadData(supplier);
          return _buildForm();
        },
        loading: () =>
            const AppScaffold(title: 'Carregando...', body: LoadingIndicator()),
        error: (e, _) => AppScaffold(
          title: 'Erro',
          body: EmptyState(
            icon: Icons.error,
            title: 'Falha ao carregar',
            subtitle: '$e',
          ),
        ),
      );
    }

    return _buildForm();
  }

  Widget _buildForm() {
    return AppScaffold(
      title: isEditing ? 'Editar Fornecedor' : 'Novo Fornecedor',
      actions: [
        if (_isSaving)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
            tooltip: 'Salvar',
          ),
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
              TextFormField(
                controller: _documentCtrl,
                decoration: const InputDecoration(labelText: 'CNPJ/CPF'),
                keyboardType: TextInputType.number,
                // inputFormatters: [CnpjCpfInputFormatter()],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactCtrl,
                decoration: const InputDecoration(labelText: 'Nome de Contato'),
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
                  labelText: 'Observações Internas',
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
