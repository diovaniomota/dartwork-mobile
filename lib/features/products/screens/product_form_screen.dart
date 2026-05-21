import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/organization_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import 'products_screen.dart';

/// Formulário de criação/edição de produto — paridade total com web.
/// Inclui todos os campos fiscais: NCM, CEST, CFOP, ICMS, IPI, PIS, COFINS.
class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;
  const ProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _isLoadingData = false;
  String _itemKind = 'product'; // 'product' ou 'service'

  // Dados Gerais
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _gtinCtrl = TextEditingController();
  final _gtinTributavelCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _descricaoReduzidaCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'UN');
  final _unitTributavelCtrl = TextEditingController();

  // Dados Fiscais
  final _ncmCtrl = TextEditingController();
  final _cestCtrl = TextEditingController();
  int _origem = 0;
  final _pesoBrutoCtrl = TextEditingController();
  final _pesoLiquidoCtrl = TextEditingController();
  final _cfopInternoCtrl = TextEditingController(text: '5102');
  final _cfopExternoCtrl = TextEditingController(text: '6102');

  // Tributação
  final _situacaoTributariaCtrl = TextEditingController();
  final _cstIcmsCtrl = TextEditingController();
  final _csosnCtrl = TextEditingController(text: '102');
  final _aliqIcmsCtrl = TextEditingController();
  final _reducaoBcCtrl = TextEditingController();
  final _cstIpiCtrl = TextEditingController(text: '99');
  final _aliqIpiCtrl = TextEditingController();
  final _cstPisCtrl = TextEditingController(text: '49');
  final _aliqPisCtrl = TextEditingController();
  final _cstCofinsCtrl = TextEditingController(text: '49');
  final _aliqCofinsCtrl = TextEditingController();

  bool get isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) _loadProduct();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _gtinCtrl.dispose();
    _gtinTributavelCtrl.dispose();
    _categoryCtrl.dispose();
    _descricaoReduzidaCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    _unitCtrl.dispose();
    _unitTributavelCtrl.dispose();
    _ncmCtrl.dispose();
    _cestCtrl.dispose();
    _pesoBrutoCtrl.dispose();
    _pesoLiquidoCtrl.dispose();
    _cfopInternoCtrl.dispose();
    _cfopExternoCtrl.dispose();
    _situacaoTributariaCtrl.dispose();
    _cstIcmsCtrl.dispose();
    _csosnCtrl.dispose();
    _aliqIcmsCtrl.dispose();
    _reducaoBcCtrl.dispose();
    _cstIpiCtrl.dispose();
    _aliqIpiCtrl.dispose();
    _cstPisCtrl.dispose();
    _aliqPisCtrl.dispose();
    _cstCofinsCtrl.dispose();
    _aliqCofinsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoadingData = true);
    try {
      final repo = ref.read(productRepositoryProvider);
      final p = await repo.getById(widget.productId!);
      if (p != null && mounted) {
        _nameCtrl.text = p.name;
        _brandCtrl.text = p.brand ?? '';
        _gtinCtrl.text = p.gtin ?? '';
        _gtinTributavelCtrl.text = p.gtinTributavel ?? '';
        _categoryCtrl.text = p.category ?? '';
        _descricaoReduzidaCtrl.text = p.descricaoReduzida ?? '';
        _priceCtrl.text = p.price > 0 ? p.price.toStringAsFixed(2) : '';
        _costCtrl.text = p.costPrice > 0 ? p.costPrice.toStringAsFixed(2) : '';
        _stockCtrl.text = p.stock > 0 ? p.stock.toString() : '';
        _minStockCtrl.text = p.minStock > 0 ? p.minStock.toString() : '';
        _unitCtrl.text = p.unidade ?? 'UN';
        _unitTributavelCtrl.text = p.unidadeTributavel ?? '';
        _ncmCtrl.text = p.ncm ?? '';
        _cestCtrl.text = p.cest ?? '';
        _origem = p.origem;
        _pesoBrutoCtrl.text =
            p.pesoBruto > 0 ? p.pesoBruto.toStringAsFixed(3) : '';
        _pesoLiquidoCtrl.text =
            p.pesoLiquido > 0 ? p.pesoLiquido.toStringAsFixed(3) : '';
        _cfopInternoCtrl.text = p.cfopInterno ?? p.cfopDentro ?? '5102';
        _cfopExternoCtrl.text = p.cfopExterno ?? p.cfopFora ?? '6102';
        _situacaoTributariaCtrl.text = p.situacaoTributaria ?? '';
        _cstIcmsCtrl.text = p.cstIcms ?? '';
        _csosnCtrl.text = p.csosn ?? '102';
        _aliqIcmsCtrl.text =
            p.aliqIcms != null ? p.aliqIcms!.toStringAsFixed(2) : '';
        _reducaoBcCtrl.text =
            p.reducaoBc != null ? p.reducaoBc!.toStringAsFixed(2) : '';
        _cstIpiCtrl.text = p.cstIpi ?? '99';
        _aliqIpiCtrl.text =
            p.aliqIpi != null ? p.aliqIpi!.toStringAsFixed(2) : '';
        _cstPisCtrl.text = p.cstPis ?? '49';
        _aliqPisCtrl.text =
            p.aliqPis != null ? p.aliqPis!.toStringAsFixed(2) : '';
        _cstCofinsCtrl.text = p.cstCofins ?? '49';
        _aliqCofinsCtrl.text =
            p.aliqCofins != null ? p.aliqCofins!.toStringAsFixed(2) : '';
        _itemKind = p.isService ? 'service' : 'product';
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingData = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final orgId = ref.read(currentOrgIdProvider);
      if (orgId == null) return;
      final repo = ref.read(productRepositoryProvider);
      final isService = _itemKind == 'service';
      final data = {
        'organization_id': orgId,
        'name': _nameCtrl.text.trim(),
        'brand': _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        'gtin': _gtinCtrl.text.trim().isEmpty ? null : _gtinCtrl.text.trim(),
        'gtin_tributavel': _gtinTributavelCtrl.text.trim().isEmpty
            ? null
            : _gtinTributavelCtrl.text.trim(),
        'category': isService
            ? '09'
            : (_categoryCtrl.text.trim().isEmpty
                ? null
                : _categoryCtrl.text.trim()),
        'descricao_reduzida': _descricaoReduzidaCtrl.text.trim().isEmpty
            ? null
            : _descricaoReduzidaCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text) ?? 0,
        'cost_price': double.tryParse(_costCtrl.text) ?? 0,
        'stock': isService ? 0 : (int.tryParse(_stockCtrl.text) ?? 0),
        'min_stock': isService ? 0 : (int.tryParse(_minStockCtrl.text) ?? 0),
        'unidade':
            _unitCtrl.text.trim().isEmpty ? 'UN' : _unitCtrl.text.trim(),
        'unidade_tributavel': _unitTributavelCtrl.text.trim().isEmpty
            ? null
            : _unitTributavelCtrl.text.trim(),
        'ncm': _ncmCtrl.text.trim().isEmpty ? null : _ncmCtrl.text.trim(),
        'cest': _cestCtrl.text.trim().isEmpty ? null : _cestCtrl.text.trim(),
        'origem': _origem,
        'peso_bruto':
            isService ? 0 : (double.tryParse(_pesoBrutoCtrl.text) ?? 0),
        'peso_liquido':
            isService ? 0 : (double.tryParse(_pesoLiquidoCtrl.text) ?? 0),
        'cfop_interno': _cfopInternoCtrl.text.trim().isEmpty
            ? '5102'
            : _cfopInternoCtrl.text.trim(),
        'cfop_externo': _cfopExternoCtrl.text.trim().isEmpty
            ? '6102'
            : _cfopExternoCtrl.text.trim(),
        'cfop_dentro': _cfopInternoCtrl.text.trim().isEmpty
            ? '5102'
            : _cfopInternoCtrl.text.trim(),
        'cfop_fora': _cfopExternoCtrl.text.trim().isEmpty
            ? '6102'
            : _cfopExternoCtrl.text.trim(),
        'situacao_tributaria': _situacaoTributariaCtrl.text.trim().isEmpty
            ? null
            : _situacaoTributariaCtrl.text.trim(),
        'cst_icms': _cstIcmsCtrl.text.trim().isEmpty
            ? null
            : _cstIcmsCtrl.text.trim(),
        'csosn': _csosnCtrl.text.trim().isEmpty
            ? '102'
            : _csosnCtrl.text.trim(),
        'aliq_icms': double.tryParse(_aliqIcmsCtrl.text),
        'reducao_bc': double.tryParse(_reducaoBcCtrl.text),
        'cst_ipi': _cstIpiCtrl.text.trim().isEmpty
            ? '99'
            : _cstIpiCtrl.text.trim(),
        'aliq_ipi': double.tryParse(_aliqIpiCtrl.text),
        'cst_pis': _cstPisCtrl.text.trim().isEmpty
            ? '49'
            : _cstPisCtrl.text.trim(),
        'aliq_pis': double.tryParse(_aliqPisCtrl.text),
        'cst_cofins': _cstCofinsCtrl.text.trim().isEmpty
            ? '49'
            : _cstCofinsCtrl.text.trim(),
        'aliq_cofins': double.tryParse(_aliqCofinsCtrl.text),
      };
      if (isEditing) {
        await repo.update(widget.productId!, data);
      } else {
        await repo.create(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Produto atualizado!' : 'Produto criado!',
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

  static const _origemOptions = [
    '0 - Nacional',
    '1 - Estrangeira (Importação direta)',
    '2 - Estrangeira (Adquirida no mercado interno)',
    '3 - Nacional (Conteúdo importação > 40%)',
    '4 - Nacional (Processos básicos)',
    '5 - Nacional (Conteúdo importação < 40%)',
    '6 - Estrangeira (Importação direta, sem similar)',
    '7 - Estrangeira (Adquirida, sem similar)',
    '8 - Nacional (Conteúdo importação > 70%)',
  ];

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
        title: Text(isEditing ? 'Editar Produto' : 'Novo Produto'),
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
              // Tipo: Produto ou Serviço
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'product', label: Text('Produto')),
                  ButtonSegment(value: 'service', label: Text('Serviço')),
                ],
                selected: {_itemKind},
                onSelectionChanged: (v) =>
                    setState(() => _itemKind = v.first),
              ),
              const SizedBox(height: 16),

              // === DADOS GERAIS ===
              _sectionTitle('Dados Gerais'),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nome obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brandCtrl,
                decoration: const InputDecoration(labelText: 'Marca'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descricaoReduzidaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descrição Reduzida',
                  helperText: 'Máx. 60 caracteres',
                ),
                maxLength: 60,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _gtinCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código de Barras (GTIN)',
                ),
                keyboardType: TextInputType.number,
                maxLength: 14,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _gtinTributavelCtrl,
                decoration: const InputDecoration(
                  labelText: 'GTIN Tributável',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(labelText: 'Categoria'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Preço (R\$)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _costCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Custo (R\$)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_itemKind == 'product') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Estoque'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _minStockCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Estoque Mín.'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _unitCtrl,
                      decoration: const InputDecoration(labelText: 'Unidade'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitTributavelCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Un. Tributável'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // === DADOS FISCAIS ===
              _sectionTitle('Dados Fiscais'),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _ncmCtrl,
                      decoration: const InputDecoration(labelText: 'NCM'),
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cestCtrl,
                      decoration: const InputDecoration(labelText: 'CEST'),
                      keyboardType: TextInputType.number,
                      maxLength: 7,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _origem,
                decoration: const InputDecoration(labelText: 'Origem'),
                isExpanded: true,
                items: List.generate(
                  _origemOptions.length,
                  (i) => DropdownMenuItem(
                    value: i,
                    child: Text(
                      _origemOptions[i],
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                onChanged: (v) => setState(() => _origem = v ?? 0),
              ),
              const SizedBox(height: 12),
              if (_itemKind == 'product') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _pesoBrutoCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Peso Bruto (kg)'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _pesoLiquidoCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Peso Líquido (kg)'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cfopInternoCtrl,
                      decoration:
                          const InputDecoration(labelText: 'CFOP Interno'),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cfopExternoCtrl,
                      decoration:
                          const InputDecoration(labelText: 'CFOP Externo'),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // === TRIBUTAÇÃO ===
              _sectionTitle('Tributação'),
              TextFormField(
                controller: _situacaoTributariaCtrl,
                decoration:
                    const InputDecoration(labelText: 'Situação Tributária'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cstIcmsCtrl,
                      decoration:
                          const InputDecoration(labelText: 'CST ICMS'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _csosnCtrl,
                      decoration: const InputDecoration(labelText: 'CSOSN'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _aliqIcmsCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Alíq. ICMS (%)'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _reducaoBcCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Redução BC (%)'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
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
                      controller: _cstIpiCtrl,
                      decoration:
                          const InputDecoration(labelText: 'CST IPI'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _aliqIpiCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Alíq. IPI (%)'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
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
                      controller: _cstPisCtrl,
                      decoration:
                          const InputDecoration(labelText: 'CST PIS'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _aliqPisCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Alíq. PIS (%)'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
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
                      controller: _cstCofinsCtrl,
                      decoration:
                          const InputDecoration(labelText: 'CST COFINS'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _aliqCofinsCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Alíq. COFINS (%)'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
