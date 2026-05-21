import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/digital_quote.dart';
import '../../../data/repositories/digital_quote_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/client_picker.dart';

class BudgetFormScreen extends ConsumerStatefulWidget {
  final String? budgetId;
  const BudgetFormScreen({super.key, this.budgetId});

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;
  DigitalQuote? _loadedBudget;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _clientNameCtrl = TextEditingController();
  final _clientPhoneCtrl = TextEditingController();
  final _clientDocCtrl = TextEditingController();
  final _totalValCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.budgetId != null) {
      _loadBudget();
    }
  }

  Future<void> _loadBudget() async {
    setState(() => _isLoading = true);
    try {
      final budget = await ref
          .read(digitalQuoteRepositoryProvider)
          .getById(widget.budgetId!);
      if (budget != null) {
        _loadedBudget = budget;
        _titleCtrl.text = budget.title ?? '';
        _descCtrl.text = budget.description ?? '';
        _clientNameCtrl.text = budget.clientName ?? '';
        _clientPhoneCtrl.text = budget.clientPhone ?? '';
        _clientDocCtrl.text = budget.clientDocument ?? '';
        _totalValCtrl.text = budget.totalValue.toStringAsFixed(2);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar orçamento: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final orgId = ref.read(userProfileProvider).value?.organizationId;
      if (orgId == null) throw Exception('Sessão inválida');

      final budget = DigitalQuote(
        id: widget.budgetId ?? '',
        organizationId: orgId,
        title: _titleCtrl.text,
        description: _descCtrl.text,
        clientName: _clientNameCtrl.text,
        clientPhone: _clientPhoneCtrl.text,
        clientDocument: _clientDocCtrl.text,
        totalValue:
            double.tryParse(_totalValCtrl.text.replaceAll(',', '.')) ?? 0.0,
        status: 'rascunho',
      );

      final repo = ref.read(digitalQuoteRepositoryProvider);
      if (widget.budgetId != null) {
        await repo.update(widget.budgetId!, budget);
      } else {
        await repo.create(budget);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orçamento salvo com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar orçamento: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _shareBudget() async {
    if (_loadedBudget?.approvalToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salve o orçamento antes de compartilhar.'),
        ),
      );
      return;
    }

    final url =
        '${AppConstants.webAppUrl}/orcamentos/aprovar/${_loadedBudget!.approvalToken}?embed=1';
    final text = 'Olá! Segue o link para aprovação do orçamento: $url';
    final whatsappUrl = Uri.parse(
      'whatsapp://send?text=${Uri.encodeComponent(text)}',
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else {
        throw 'WhatsApp não instalado';
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
        );
      }
    }
  }

  void _showClientPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClientPicker(
        onSelected: (client) {
          setState(() {
            _clientNameCtrl.text = client.name;
            _clientDocCtrl.text = client.document ?? '';
            _clientPhoneCtrl.text = client.phone ?? '';
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.budgetId != null;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carregando...')),
        body: const LoadingIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Orçamento' : 'Novo Orçamento Avulso'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else ...[
            if (isEditing && _loadedBudget?.approvalToken != null)
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareBudget,
                tooltip: 'Vincular via WhatsApp',
              ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _save,
              tooltip: 'Salvar',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Título do Orçamento',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Informe o título' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Descrição/Obs',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Dados do Cliente',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: _showClientPicker,
                            icon: const Icon(Icons.search),
                            label: const Text('Buscar'),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _clientNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Cliente',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Informe o nome' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _clientDocCtrl,
                              decoration: const InputDecoration(
                                labelText: 'CPF/CNPJ',
                                prefixIcon: Icon(Icons.badge),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _clientPhoneCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Telefone',
                                prefixIcon: Icon(Icons.phone),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Valores',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _totalValCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Valor Total',
                          prefixIcon: Icon(Icons.attach_money),
                          prefixText: 'R\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Informe o valor';
                          if (double.tryParse(v.replaceAll(',', '.')) == null) {
                            return 'Valor inválido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Nota: Orçamentos avulsos salvos no aplicativo serão sincronizados com o painel web para aprovação digital.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
