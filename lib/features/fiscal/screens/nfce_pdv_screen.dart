import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/services/fiscal_api_service.dart';
import '../../../providers/organization_provider.dart';
import '../../../providers/company_settings_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_colors.dart';
import 'dart:async';
import '../../../data/models/company_settings.dart';
import '../widgets/non_fiscal_receipt_dialog.dart';

/// Item no carrinho do PDV NFC-e.
class NfceCartItem {
  final Product product;
  double quantity;

  NfceCartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

/// Tela de PDV para emissão de NFC-e (Modelo 65).
class NfcePdvScreen extends ConsumerStatefulWidget {
  const NfcePdvScreen({super.key});

  @override
  ConsumerState<NfcePdvScreen> createState() => _NfcePdvScreenState();
}

class _NfcePdvScreenState extends ConsumerState<NfcePdvScreen> {
  final _searchCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _cart = <NfceCartItem>[];
  List<Product> _searchResults = [];
  Timer? _debounce;
  bool _isEmitting = false;

  double get cartTotal => _cart.fold(0, (sum, item) => sum + item.total);

  @override
  void dispose() {
    _searchCtrl.dispose();
    _cpfCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _searchProducts(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.trim().isEmpty) {
        setState(() {
          _searchResults = [];
        });
        return;
      }
      final orgId = ref.read(currentOrgIdProvider);
      if (orgId == null) return;
      final repo = ProductRepository();
      final results = await repo.getAll(orgId, search: query);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    });
  }

  void _addToCart(Product product) {
    setState(() {
      final existing = _cart.indexWhere(
        (item) => item.product.id == product.id,
      );
      if (existing >= 0) {
        _cart[existing].quantity++;
      } else {
        _cart.add(NfceCartItem(product: product));
      }
      _searchCtrl.clear();
      _searchResults = [];
    });
  }

  void _removeFromCart(int index) {
    setState(() => _cart.removeAt(index));
  }

  void _updateQuantity(int index, double qty) {
    if (qty <= 0) {
      _removeFromCart(index);
      return;
    }
    setState(() => _cart[index].quantity = qty);
  }

  Future<void> _emitNfce() async {
    if (_cart.isEmpty) return;

    final method = await _showPaymentDialog();
    if (method == null) return;

    setState(() => _isEmitting = true);
    try {
      final api = ref.read(fiscalApiProvider);
      final settings = await ref.read(companySettingsProvider.future);

      if (settings == null) {
        throw Exception(
          'Configurações da empresa não encontradas. Verifique o cadastro fiscal no Painel Web.',
        );
      }

      // Payload completo para NFC-e (Focus NFe via Vercel Proxy)
      final payload = {
        'ambiente': settings.ambiente == '1' ? 'producao' : 'homologacao',
        'infNFe': {
          'ide': {
            'cUF': int.tryParse(settings.codigoUf ?? '35') ?? 35,
            'natOp': settings.logradouro ?? 'Venda de Mercadoria',
            'mod': 65,
            'serie': int.tryParse(settings.serieNfce ?? '1') ?? 1,
            'nNF': settings.proximaNfce ?? 1,
            'dhEmi': DateTime.now().toIso8601String(),
            'tpNF': 1,
            'idDest': 1,
            'tpImp': 4,
            'tpEmis': 1,
            'finNFe': 1,
            'indFinal': 1,
            'indPres': 1,
            'procEmi': 0,
            'verProc': settings.verProc ?? '1.0.0',
          },
          'emit': {
            'CNPJ': settings.cnpj?.replaceAll(RegExp(r'\D'), '') ?? '',
            'xNome': settings.razaoSocial,
            'xFant': settings.nomeFantasia ?? settings.razaoSocial,
            'IE':
                settings.inscricaoEstadual?.replaceAll(RegExp(r'\D'), '') ?? '',
            'CRT': int.tryParse(settings.regimeTributario ?? '1') ?? 1,
            'enderEmit': {
              'xLgr': settings.logradouro,
              'nro': settings.numero,
              'xBairro': settings.bairro,
              'cMun': settings.codigoMunicipio,
              'xMun': settings.cidade,
              'UF': settings.uf,
              'CEP': settings.cep?.replaceAll(RegExp(r'\D'), '') ?? '',
              'cPais': 1058,
              'xPais': 'BRASIL',
            },
          },
          'dest': _cpfCtrl.text.isNotEmpty
              ? {
                  'CPF': _cpfCtrl.text.replaceAll(RegExp(r'\D'), ''),
                  'xNome': 'CONSUMIDOR IDENTIFICADO',
                  'indIEDest': 9,
                }
              : null,
          'det': _cart
              .asMap()
              .entries
              .map(
                (entry) => {
                  'nItem': entry.key + 1,
                  'prod': {
                    'cProd':
                        entry.value.product.sku ??
                        entry.value.product.id.toString(),
                    'xProd': entry.value.product.name,
                    'NCM': entry.value.product.ncm ?? '00000000',
                    'CFOP': entry.value.product.cfopDentro ?? '5102',
                    'uCom': entry.value.product.unidade ?? 'UN',
                    'qCom': entry.value.quantity,
                    'vUnCom': entry.value.product.price,
                    'vProd': entry.value.total,
                    'uTrib': entry.value.product.unidade ?? 'UN',
                    'qTrib': entry.value.quantity,
                    'vUnTrib': entry.value.product.price,
                  },
                  'imposto': {
                    'ICMS': {
                      'ICMSSN102': {'orig': 0, 'CSOSN': '102'},
                    },
                    'PIS': {
                      'PISNT': {'CST': '07'},
                    },
                    'COFINS': {
                      'COFINSNT': {'CST': '07'},
                    },
                  },
                },
              )
              .toList(),
          'pag': {
            'detPag': [
              {'tPag': method, 'vPag': cartTotal},
            ],
          },
          'transp': {'modFrete': 9},
          'total': {
            'ICMSTot': {
              'vBC': 0,
              'vICMS': 0,
              'vICMSDeson': 0,
              'vFCP': 0,
              'vBCST': 0,
              'vST': 0,
              'vFCPST': 0,
              'vFCPSTRet': 0,
              'vProd': cartTotal,
              'vFrete': 0,
              'vSeg': 0,
              'vDesc': 0,
              'vII': 0,
              'vIPI': 0,
              'vIPIDevol': 0,
              'vPIS': 0,
              'vCOFINS': 0,
              'vOutro': 0,
              'vNF': cartTotal,
            },
          },
        },
      };

      final String refId = 'NFCE-${DateTime.now().millisecondsSinceEpoch}';

      final result = await api.emitirNfce(refId, payload);
      final responseData = result['data'] ?? {};
      final pdfUrl =
          responseData['caminho_danfe_pdf'] ??
          responseData['caminho_danfe'] ??
          responseData['caminho_xml_pdf'];

      if (mounted) {
        _showSuccessDialog(
          saleId: refId,
          company: settings,
          paymentMethod: method,
          pdfUrl: pdfUrl?.toString(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na emissão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isEmitting = false);
    }
  }

  Future<String?> _showPaymentDialog() {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Pagamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Total: ${formatCurrency(cartTotal)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ...[
              {'id': '01', 'label': 'Dinheiro', 'icon': Icons.money},
              {
                'id': '03',
                'label': 'Cartão de Crédito',
                'icon': Icons.credit_card,
              },
              {
                'id': '04',
                'label': 'Cartão de Débito',
                'icon': Icons.credit_card,
              },
              {'id': '17', 'label': 'PIX', 'icon': Icons.qr_code},
            ].map(
              (p) => ListTile(
                leading: Icon(p['icon'] as IconData, color: AppColors.primary),
                title: Text(p['label'] as String),
                onTap: () => Navigator.pop(context, p['id']),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog({
    required String saleId,
    required CompanySettings company,
    required String paymentMethod,
    String? pdfUrl,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NonFiscalReceiptDialog(
        saleId: saleId,
        company: company,
        items: _cart
            .map(
              (item) => NonFiscalReceiptItem(
                description: item.product.name,
                quantity: item.quantity,
                unitPrice: item.product.price,
                total: item.total,
              ),
            )
            .toList(),
        total: cartTotal,
        paymentMethod: _paymentMethodLabelFromCode(paymentMethod),
        pdfUrl: pdfUrl,
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _cart.clear();
          _cpfCtrl.clear();
        });
      }
    });
  }

  String _paymentMethodLabelFromCode(String code) {
    switch (code) {
      case '01':
        return 'Dinheiro';
      case '03':
        return 'Cartão de Crédito';
      case '04':
        return 'Cartão de Débito';
      case '17':
        return 'PIX';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Emitir NFC-e (PDV)',
      body: Column(
        children: [
          // CPF Consumidor
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _cpfCtrl,
              decoration: const InputDecoration(
                hintText: 'CPF na Nota (Opcional)',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ),

          // Busca de produto
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Buscar produto ou código...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchProducts,
            ),
          ),

          // Resultados da busca
          if (_searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 4,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, i) {
                    final p = _searchResults[i];
                    return ListTile(
                      title: Text(p.name),
                      subtitle: Text(formatCurrency(p.price)),
                      trailing: const Icon(
                        Icons.add_circle,
                        color: AppColors.primary,
                      ),
                      onTap: () => _addToCart(p),
                    );
                  },
                ),
              ),
            ),

          // Carrinho
          Expanded(
            child: _cart.isEmpty
                ? const EmptyState(
                    icon: Icons.shopping_basket_outlined,
                    title: 'Carrinho vazio',
                    subtitle: 'Adicione itens para emitir o cupom',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _cart.length,
                    itemBuilder: (context, i) {
                      final item = _cart[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(formatCurrency(item.product.price)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _updateQuantity(i, item.quantity - 1),
                                  ),
                                  Text(
                                    item.quantity.toStringAsFixed(0),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _updateQuantity(i, item.quantity + 1),
                                  ),
                                ],
                              ),
                              Text(
                                formatCurrency(item.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Checkout
          if (_cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'TOTAL DO CUPOM',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          formatCurrency(cartTotal),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _isEmitting ? null : _emitNfce,
                      icon: _isEmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        _isEmitting ? 'Emitindo...' : 'Finalizar Cupom',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
