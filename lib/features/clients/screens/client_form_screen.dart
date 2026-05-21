import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../data/models/client.dart' as app_model;
import '../../../data/repositories/client_repository.dart';
import '../../../providers/organization_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Formulário de criação/edição de cliente — paridade total com web.
/// Organizado em seções expansíveis: Cadastral, Fiscal, Endereço,
/// Endereço de Cobrança, Contato, Dados Adicionais, Comercial.
class ClientFormScreen extends ConsumerStatefulWidget {
  final String? clientId;
  const ClientFormScreen({super.key, this.clientId});

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _isLoadingData = false;
  bool _isFetchingCnpj = false;
  bool _isFetchingCep = false;

  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _cnpjFormatter = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _cepFormatter = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _billingCepFormatter = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // === Dados Cadastrais ===
  final _nameCtrl = TextEditingController();
  final _fantasyNameCtrl = TextEditingController();
  final _documentCtrl = TextEditingController();
  String _tipoPessoa = 'F'; // F=Física, J=Jurídica
  final _codeCtrl = TextEditingController();
  final _clientSinceCtrl = TextEditingController();

  // === Dados Fiscais ===
  final _taxRegimeCtrl = TextEditingController();
  String _ieIndicator = '1'; // 1=Contribuinte, 2=Isento, 9=Não contribuinte
  final _ieCtrl = TextEditingController();
  bool _ieExempt = false;
  final _imCtrl = TextEditingController();
  final _rgCtrl = TextEditingController();
  final _rgEmissorCtrl = TextEditingController();
  bool _isPublicOrg = false;
  final _suframaCtrl = TextEditingController();
  bool _consumidorFinal = false;

  // === Endereço Principal ===
  final _cepCtrl = TextEditingController();
  final _ufCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _complementCtrl = TextEditingController();
  final _codMunicipioCtrl = TextEditingController();

  // === Endereço de Cobrança ===
  final _billingCepCtrl = TextEditingController();
  final _billingUfCtrl = TextEditingController();
  final _billingCityCtrl = TextEditingController();
  final _billingNeighborhoodCtrl = TextEditingController();
  final _billingAddressCtrl = TextEditingController();
  final _billingNumberCtrl = TextEditingController();
  final _billingComplementCtrl = TextEditingController();

  // === Contato ===
  final _emailCtrl = TextEditingController();
  final _nfeEmailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _faxCtrl = TextEditingController();
  final _carrierCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _contactInfoCtrl = TextEditingController();
  final _contactPeopleCtrl = TextEditingController();
  final _contactTypeCtrl = TextEditingController();

  // === Dados Adicionais (PF) ===
  final _civilStatusCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _birthplaceCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _fatherCpfCtrl = TextEditingController();
  final _motherNameCtrl = TextEditingController();
  final _motherCpfCtrl = TextEditingController();

  // === Comercial ===
  final _situationCtrl = TextEditingController();
  final _sellerCtrl = TextEditingController();
  final _defaultOperationCtrl = TextEditingController();
  String _creditLimitType = 'unlimited';
  final _creditLimitCtrl = TextEditingController();
  final _paymentConditionCtrl = TextEditingController();
  String _category = 'Regular';
  final _nextVisitCtrl = TextEditingController();

  // === Observações ===
  final _notesCtrl = TextEditingController();

  bool get isEditing => widget.clientId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) _loadClient();
  }

  @override
  void dispose() {
    // Cadastrais
    _nameCtrl.dispose();
    _fantasyNameCtrl.dispose();
    _documentCtrl.dispose();
    _codeCtrl.dispose();
    _clientSinceCtrl.dispose();
    // Fiscais
    _taxRegimeCtrl.dispose();
    _ieCtrl.dispose();
    _imCtrl.dispose();
    _rgCtrl.dispose();
    _rgEmissorCtrl.dispose();
    _suframaCtrl.dispose();
    // Endereço
    _cepCtrl.dispose();
    _ufCtrl.dispose();
    _cityCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _addressCtrl.dispose();
    _numberCtrl.dispose();
    _complementCtrl.dispose();
    _codMunicipioCtrl.dispose();
    // Cobrança
    _billingCepCtrl.dispose();
    _billingUfCtrl.dispose();
    _billingCityCtrl.dispose();
    _billingNeighborhoodCtrl.dispose();
    _billingAddressCtrl.dispose();
    _billingNumberCtrl.dispose();
    _billingComplementCtrl.dispose();
    // Contato
    _emailCtrl.dispose();
    _nfeEmailCtrl.dispose();
    _phoneCtrl.dispose();
    _mobileCtrl.dispose();
    _faxCtrl.dispose();
    _carrierCtrl.dispose();
    _websiteCtrl.dispose();
    _contactInfoCtrl.dispose();
    _contactPeopleCtrl.dispose();
    _contactTypeCtrl.dispose();
    // Dados adicionais
    _civilStatusCtrl.dispose();
    _professionCtrl.dispose();
    _genderCtrl.dispose();
    _birthDateCtrl.dispose();
    _birthplaceCtrl.dispose();
    _fatherNameCtrl.dispose();
    _fatherCpfCtrl.dispose();
    _motherNameCtrl.dispose();
    _motherCpfCtrl.dispose();
    // Comercial
    _situationCtrl.dispose();
    _sellerCtrl.dispose();
    _defaultOperationCtrl.dispose();
    _creditLimitCtrl.dispose();
    _paymentConditionCtrl.dispose();
    _nextVisitCtrl.dispose();
    // Observações
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadClient() async {
    setState(() => _isLoadingData = true);
    try {
      final ClientRepository repo = ref.read(clientRepositoryProvider);
      final app_model.ClientModel? c = await repo.getById(widget.clientId!);
      if (c != null && mounted) {
        // Cadastrais
        _nameCtrl.text = c.name;
        _fantasyNameCtrl.text = c.fantasyName ?? '';
        _documentCtrl.text = c.document ?? '';
        _tipoPessoa = c.tipoPessoa ?? 'F';
        _codeCtrl.text = c.code ?? '';
        _clientSinceCtrl.text = c.clientSince ?? '';
        // Fiscais
        _taxRegimeCtrl.text = c.taxRegime ?? '';
        _ieIndicator = c.ieIndicator ?? '1';
        _ieCtrl.text = c.ie ?? '';
        _ieExempt = c.ieExempt ?? false;
        _imCtrl.text = c.im ?? '';
        _rgCtrl.text = c.rg ?? '';
        _rgEmissorCtrl.text = c.rgEmissor ?? '';
        _isPublicOrg = c.isPublicOrg ?? false;
        _suframaCtrl.text = c.suframa ?? '';
        _consumidorFinal = c.consumidorFinal ?? false;
        // Endereço
        _cepCtrl.text = c.cep ?? '';
        _ufCtrl.text = c.uf ?? '';
        _cityCtrl.text = c.city ?? '';
        _neighborhoodCtrl.text = c.neighborhood ?? '';
        _addressCtrl.text = c.address ?? '';
        _numberCtrl.text = c.number ?? '';
        _complementCtrl.text = c.complement ?? '';
        _codMunicipioCtrl.text = c.codMunicipio ?? '';
        // Cobrança
        _billingCepCtrl.text = c.billingCep ?? '';
        _billingUfCtrl.text = c.billingUf ?? '';
        _billingCityCtrl.text = c.billingCity ?? '';
        _billingNeighborhoodCtrl.text = c.billingNeighborhood ?? '';
        _billingAddressCtrl.text = c.billingAddress ?? '';
        _billingNumberCtrl.text = c.billingNumber ?? '';
        _billingComplementCtrl.text = c.billingComplement ?? '';
        // Contato
        _emailCtrl.text = c.email ?? '';
        _nfeEmailCtrl.text = c.nfeEmail ?? '';
        _phoneCtrl.text = c.phone ?? '';
        _mobileCtrl.text = c.mobile ?? '';
        _faxCtrl.text = c.fax ?? '';
        _carrierCtrl.text = c.carrier ?? '';
        _websiteCtrl.text = c.website ?? '';
        _contactInfoCtrl.text = c.contactInfo ?? '';
        _contactPeopleCtrl.text = c.contactPeople ?? '';
        _contactTypeCtrl.text = c.contactType ?? '';
        // Dados adicionais
        _civilStatusCtrl.text = c.civilStatus ?? '';
        _professionCtrl.text = c.profession ?? '';
        _genderCtrl.text = c.gender ?? '';
        _birthDateCtrl.text = c.birthDate ?? '';
        _birthplaceCtrl.text = c.birthplace ?? '';
        _fatherNameCtrl.text = c.fatherName ?? '';
        _fatherCpfCtrl.text = c.fatherCpf ?? '';
        _motherNameCtrl.text = c.motherName ?? '';
        _motherCpfCtrl.text = c.motherCpf ?? '';
        // Comercial
        _situationCtrl.text = c.situation ?? '';
        _sellerCtrl.text = c.seller ?? '';
        _defaultOperationCtrl.text = c.defaultOperation ?? '';
        _creditLimitType = c.creditLimitType ?? 'unlimited';
        _creditLimitCtrl.text = c.creditLimit != null
            ? c.creditLimit!.toStringAsFixed(2)
            : '';
        _paymentConditionCtrl.text = c.paymentCondition ?? '';
        _category = c.category ?? 'Regular';
        _nextVisitCtrl.text = c.nextVisit ?? '';
        // Obs
        _notesCtrl.text = c.notes ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingData = false);
  }

  String? _trimOrNull(TextEditingController ctrl) {
    final v = ctrl.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final orgId = ref.read(currentOrgIdProvider);
      if (orgId == null) return;
      final repo = ref.read(clientRepositoryProvider);
      final data = {
        'organization_id': orgId,
        // Cadastrais
        'name': _nameCtrl.text.trim(),
        'fantasy_name': _trimOrNull(_fantasyNameCtrl),
        'document': _trimOrNull(_documentCtrl),
        'tipo_pessoa': _tipoPessoa,
        'status': 'ativo',
        'client_since': _trimOrNull(_clientSinceCtrl),
        // Fiscais
        'tax_regime': _trimOrNull(_taxRegimeCtrl),
        'ie_indicator': _ieIndicator,
        'ie': _trimOrNull(_ieCtrl),
        'ie_exempt': _ieExempt,
        'im': _trimOrNull(_imCtrl),
        'rg': _trimOrNull(_rgCtrl),
        'rg_emissor': _trimOrNull(_rgEmissorCtrl),
        'is_public_org': _isPublicOrg,
        'suframa': _trimOrNull(_suframaCtrl),
        'consumidor_final': _consumidorFinal,
        'cod_pais': '1058',
        // Endereço
        'cep': _trimOrNull(_cepCtrl),
        'uf': _trimOrNull(_ufCtrl),
        'city': _trimOrNull(_cityCtrl),
        'neighborhood': _trimOrNull(_neighborhoodCtrl),
        'address': _trimOrNull(_addressCtrl),
        'number': _trimOrNull(_numberCtrl),
        'complement': _trimOrNull(_complementCtrl),
        'cod_municipio': _trimOrNull(_codMunicipioCtrl),
        // Cobrança
        'billing_cep': _trimOrNull(_billingCepCtrl),
        'billing_uf': _trimOrNull(_billingUfCtrl),
        'billing_city': _trimOrNull(_billingCityCtrl),
        'billing_neighborhood': _trimOrNull(_billingNeighborhoodCtrl),
        'billing_address': _trimOrNull(_billingAddressCtrl),
        'billing_number': _trimOrNull(_billingNumberCtrl),
        'billing_complement': _trimOrNull(_billingComplementCtrl),
        // Contato
        'email': _trimOrNull(_emailCtrl),
        'nfe_email': _trimOrNull(_nfeEmailCtrl),
        'phone': _trimOrNull(_phoneCtrl),
        'mobile': _trimOrNull(_mobileCtrl),
        'fax': _trimOrNull(_faxCtrl),
        'carrier': _trimOrNull(_carrierCtrl),
        'website': _trimOrNull(_websiteCtrl),
        'contact_info': _trimOrNull(_contactInfoCtrl),
        'contact_people': _trimOrNull(_contactPeopleCtrl),
        'contact_type': _trimOrNull(_contactTypeCtrl),
        // Dados adicionais
        'civil_status': _trimOrNull(_civilStatusCtrl),
        'profession': _trimOrNull(_professionCtrl),
        'gender': _trimOrNull(_genderCtrl),
        'birth_date': _trimOrNull(_birthDateCtrl),
        'birthplace': _trimOrNull(_birthplaceCtrl),
        'father_name': _trimOrNull(_fatherNameCtrl),
        'father_cpf': _trimOrNull(_fatherCpfCtrl),
        'mother_name': _trimOrNull(_motherNameCtrl),
        'mother_cpf': _trimOrNull(_motherCpfCtrl),
        // Comercial
        'situation': _trimOrNull(_situationCtrl),
        'seller': _trimOrNull(_sellerCtrl),
        'default_operation': _trimOrNull(_defaultOperationCtrl),
        'credit_limit_type': _creditLimitType,
        'credit_limit': double.tryParse(_creditLimitCtrl.text),
        'payment_condition': _trimOrNull(_paymentConditionCtrl),
        'category': _category,
        'next_visit': _trimOrNull(_nextVisitCtrl),
        // Obs
        'notes': _trimOrNull(_notesCtrl),
      };

      if (isEditing) {
        await repo.update(widget.clientId!, data);
      } else {
        await repo.create(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Cliente atualizado!' : 'Cliente criado!',
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

  // --- BUSCAR CNPJ (BrasilAPI) ---
  Future<void> _fetchCnpj() async {
    final cnpj = _documentCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cnpj.length != 14) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'CNPJ inválido para busca, limpe e insira 14 dígitos.',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isFetchingCnpj = true);
    try {
      final url = Uri.parse('https://brasilapi.com.br/api/cnpj/v1/$cnpj');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _tipoPessoa = 'J';
          if (data['razao_social'] != null) {
            _nameCtrl.text = data['razao_social'];
          }
          if (data['nome_fantasia'] != null) {
            _fantasyNameCtrl.text = data['nome_fantasia'];
          }
          if (data['cep'] != null) {
            _cepCtrl.text = _cepFormatter.maskText(data['cep'].toString());
            _billingCepCtrl.text = _cepFormatter.maskText(
              data['cep'].toString(),
            );
          }
          if (data['logradouro'] != null) {
            _addressCtrl.text = data['logradouro'];
            _billingAddressCtrl.text = data['logradouro'];
          }
          if (data['numero'] != null) {
            _numberCtrl.text = data['numero'];
            _billingNumberCtrl.text = data['numero'];
          }
          if (data['complemento'] != null) {
            _complementCtrl.text = data['complemento'];
            _billingComplementCtrl.text = data['complemento'];
          }
          if (data['bairro'] != null) {
            _neighborhoodCtrl.text = data['bairro'];
            _billingNeighborhoodCtrl.text = data['bairro'];
          }
          if (data['municipio'] != null) {
            _cityCtrl.text = data['municipio'];
            _billingCityCtrl.text = data['municipio'];
          }
          if (data['uf'] != null) {
            _ufCtrl.text = data['uf'];
            _billingUfCtrl.text = data['uf'];
          }
          if (data['codigo_municipio'] != null) {
            _codMunicipioCtrl.text = data['codigo_municipio'].toString();
          }
          if (data['ddd_telefone_1'] != null) {
            _phoneCtrl.text = data['ddd_telefone_1'];
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dados importados com sucesso!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erro da API: ${response.statusCode} - ${response.body}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Falha na conexão.')));
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingCnpj = false);
      }
    }
  }

  // --- BUSCAR CEP (ViaCEP) ---
  Future<void> _fetchCep(bool isBilling) async {
    final cep = (isBilling ? _billingCepCtrl.text : _cepCtrl.text).replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    if (cep.length != 8) {
      return;
    }

    setState(() => _isFetchingCep = true);
    try {
      final url = Uri.parse('https://viacep.com.br/ws/$cep/json/');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['erro'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('CEP não encontrado.')),
            );
          }
          return;
        }
        setState(() {
          if (isBilling) {
            if (data['logradouro'] != null) {
              _billingAddressCtrl.text = data['logradouro'];
            }
            if (data['bairro'] != null) {
              _billingNeighborhoodCtrl.text = data['bairro'];
            }
            if (data['localidade'] != null) {
              _billingCityCtrl.text = data['localidade'];
            }
            if (data['uf'] != null) {
              _billingUfCtrl.text = data['uf'];
            }
          } else {
            if (data['logradouro'] != null) {
              _addressCtrl.text = data['logradouro'];
            }
            if (data['bairro'] != null) {
              _neighborhoodCtrl.text = data['bairro'];
            }
            if (data['localidade'] != null) {
              _cityCtrl.text = data['localidade'];
            }
            if (data['uf'] != null) {
              _ufCtrl.text = data['uf'];
            }
            if (data['ibge'] != null) {
              _codMunicipioCtrl.text = data['ibge'];
            }
          }
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha na conexão com ViaCEP.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingCep = false);
      }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Cliente' : 'Novo Cliente'),
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
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // === TIPO PESSOA ===
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'F', label: Text('Pessoa Física')),
                  ButtonSegment(value: 'J', label: Text('Pessoa Jurídica')),
                ],
                selected: {_tipoPessoa},
                onSelectionChanged: (v) =>
                    setState(() => _tipoPessoa = v.first),
              ),
              const SizedBox(height: 16),

              // === DADOS CADASTRAIS ===
              _buildSection(
                'Dados Cadastrais',
                Icons.person,
                initiallyExpanded: true,
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: _tipoPessoa == 'J'
                          ? 'Razão Social *'
                          : 'Nome Completo *',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Nome obrigatório'
                        : null,
                  ),
                  if (_tipoPessoa == 'J') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fantasyNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nome Fantasia',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _documentCtrl,
                    decoration: InputDecoration(
                      labelText: _tipoPessoa == 'J' ? 'CNPJ' : 'CPF',
                      suffixIcon: _tipoPessoa == 'J'
                          ? IconButton(
                              icon: _isFetchingCnpj
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.search),
                              onPressed: _isFetchingCnpj ? null : _fetchCnpj,
                            )
                          : null,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      _tipoPessoa == 'J' ? _cnpjFormatter : _cpfFormatter,
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(labelText: 'Código'),
                    enabled: false,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _clientSinceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cliente Desde',
                      hintText: 'dd/mm/aaaa',
                    ),
                    keyboardType: TextInputType.datetime,
                  ),
                ],
              ),

              // === DADOS FISCAIS ===
              _buildSection(
                'Dados Fiscais',
                Icons.receipt_long,
                children: [
                  TextFormField(
                    controller: _taxRegimeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Regime Tributário',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _ieIndicator,
                    decoration: const InputDecoration(
                      labelText: 'Indicador IE',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: '1',
                        child: Text('1 - Contribuinte'),
                      ),
                      DropdownMenuItem(value: '2', child: Text('2 - Isento')),
                      DropdownMenuItem(
                        value: '9',
                        child: Text('9 - Não contribuinte'),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _ieIndicator = v ?? '1');
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ieCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Inscrição Estadual',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('IE Isento'),
                    value: _ieExempt,
                    onChanged: (v) => setState(() => _ieExempt = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  TextFormField(
                    controller: _imCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Inscrição Municipal',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_tipoPessoa == 'F') ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _rgCtrl,
                            decoration: const InputDecoration(labelText: 'RG'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _rgEmissorCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Órgão Emissor',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  SwitchListTile(
                    title: const Text('Órgão Público'),
                    value: _isPublicOrg,
                    onChanged: (v) => setState(() => _isPublicOrg = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  TextFormField(
                    controller: _suframaCtrl,
                    decoration: const InputDecoration(labelText: 'SUFRAMA'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Consumidor Final'),
                    value: _consumidorFinal,
                    onChanged: (v) => setState(() => _consumidorFinal = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),

              // === ENDEREÇO ===
              _buildSection(
                'Endereço',
                Icons.location_on,
                children: [
                  TextFormField(
                    controller: _cepCtrl,
                    decoration: InputDecoration(
                      labelText: 'CEP',
                      suffixIcon: IconButton(
                        icon: _isFetchingCep
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.search),
                        onPressed: _isFetchingCep
                            ? null
                            : () => _fetchCep(false),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [_cepFormatter],
                    onChanged: (val) {
                      if (val.replaceAll(RegExp(r'[^0-9]'), '').length == 8) {
                        _fetchCep(false);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(labelText: 'Logradouro'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _neighborhoodCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Bairro',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _numberCtrl,
                          decoration: const InputDecoration(labelText: 'Nº'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _cityCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Cidade',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _ufCtrl,
                          decoration: const InputDecoration(labelText: 'UF'),
                          maxLength: 2,
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _complementCtrl,
                    decoration: const InputDecoration(labelText: 'Complemento'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _codMunicipioCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cód. Município',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),

              // === ENDEREÇO DE COBRANÇA ===
              _buildSection(
                'Endereço de Cobrança',
                Icons.account_balance,
                children: [
                  TextFormField(
                    controller: _billingCepCtrl,
                    decoration: InputDecoration(
                      labelText: 'CEP',
                      suffixIcon: IconButton(
                        icon: _isFetchingCep
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.search),
                        onPressed: _isFetchingCep
                            ? null
                            : () => _fetchCep(true),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [_billingCepFormatter],
                    onChanged: (val) {
                      if (val.replaceAll(RegExp(r'[^0-9]'), '').length == 8) {
                        _fetchCep(true);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _billingAddressCtrl,
                    decoration: const InputDecoration(labelText: 'Logradouro'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _billingNeighborhoodCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Bairro',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _billingNumberCtrl,
                          decoration: const InputDecoration(labelText: 'Nº'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _billingCityCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Cidade',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _billingUfCtrl,
                          decoration: const InputDecoration(labelText: 'UF'),
                          maxLength: 2,
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _billingComplementCtrl,
                    decoration: const InputDecoration(labelText: 'Complemento'),
                  ),
                ],
              ),

              // === CONTATO ===
              _buildSection(
                'Contato',
                Icons.contact_phone,
                children: [
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nfeEmailCtrl,
                    decoration: const InputDecoration(labelText: 'E-mail NF-e'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Telefone',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _mobileCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Celular',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _faxCtrl,
                          decoration: const InputDecoration(labelText: 'Fax'),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _carrierCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Operadora',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _websiteCtrl,
                    decoration: const InputDecoration(labelText: 'Website'),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contactPeopleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Pessoa de Contato',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contactInfoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Informações de Contato',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contactTypeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Contato',
                    ),
                  ),
                ],
              ),

              // === DADOS ADICIONAIS (PF) ===
              if (_tipoPessoa == 'F')
                _buildSection(
                  'Dados Adicionais',
                  Icons.info_outline,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _civilStatusCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Estado Civil',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _genderCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Gênero',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _professionCtrl,
                      decoration: const InputDecoration(labelText: 'Profissão'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _birthDateCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Data de Nascimento',
                              hintText: 'dd/mm/aaaa',
                            ),
                            keyboardType: TextInputType.datetime,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _birthplaceCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Naturalidade',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _fatherNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nome do Pai',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _fatherCpfCtrl,
                            decoration: const InputDecoration(
                              labelText: 'CPF do Pai',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _motherNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nome da Mãe',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _motherCpfCtrl,
                            decoration: const InputDecoration(
                              labelText: 'CPF da Mãe',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              // === COMERCIAL ===
              _buildSection(
                'Comercial',
                Icons.business_center,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: const [
                      DropdownMenuItem(value: 'VIP', child: Text('VIP')),
                      DropdownMenuItem(
                        value: 'Premium',
                        child: Text('Premium'),
                      ),
                      DropdownMenuItem(
                        value: 'Regular',
                        child: Text('Regular'),
                      ),
                      DropdownMenuItem(value: 'Novo', child: Text('Novo')),
                    ],
                    onChanged: (v) {
                      setState(() => _category = v ?? 'Regular');
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _situationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Situação',
                      hintText: 'Ativo / Inativo / Bloqueado',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _sellerCtrl,
                    decoration: const InputDecoration(labelText: 'Vendedor'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _defaultOperationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Natureza da Operação',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _creditLimitType,
                    decoration: const InputDecoration(
                      labelText: 'Limite de Crédito',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'unlimited',
                        child: Text('Ilimitado'),
                      ),
                      DropdownMenuItem(
                        value: 'zero',
                        child: Text('Sem limite'),
                      ),
                      DropdownMenuItem(
                        value: 'custom',
                        child: Text('Personalizado'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _creditLimitType = v ?? 'unlimited'),
                  ),
                  if (_creditLimitType == 'custom') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _creditLimitCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Valor do Limite (R\$)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _paymentConditionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Condição de Pagamento',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nextVisitCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Próxima Visita',
                      hintText: 'dd/mm/aaaa',
                    ),
                    keyboardType: TextInputType.datetime,
                  ),
                ],
              ),

              // === OBSERVAÇÕES ===
              _buildSection(
                'Observações',
                Icons.notes,
                children: [
                  TextFormField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(labelText: 'Observações'),
                    maxLines: 4,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon, {
    bool initiallyExpanded = false,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(icon, size: 20),
        title: Text(title),
        initiallyExpanded: initiallyExpanded,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: children,
      ),
    );
  }
}
