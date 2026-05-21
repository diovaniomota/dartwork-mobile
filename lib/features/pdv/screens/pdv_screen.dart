import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/product.dart';
import '../../../data/models/company_settings.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/pdv_repository.dart';
import '../../../providers/organization_provider.dart';
import '../../../providers/company_settings_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../fiscal/widgets/non_fiscal_receipt_dialog.dart';
import 'dart:async';

/// Item no carrinho do PDV.
class CartItem {
  final Product product;
  double quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

/// Tela do PDV (Ponto de Venda).
class PdvScreen extends ConsumerStatefulWidget {
  const PdvScreen({super.key});

  @override
  ConsumerState<PdvScreen> createState() => _PdvScreenState();
}

class _PdvScreenState extends ConsumerState<PdvScreen> {
  final _searchCtrl = TextEditingController();
  final _cart = <CartItem>[];
  List<Product> _searchResults = [];
  Timer? _debounce;
  bool _isFinishing = false;

  double get cartTotal => _cart.fold(0, (sum, item) => sum + item.total);

  String _resolveSellerName({
    String? profileName,
    String? email,
    String fallback = '',
  }) {
    final normalizedProfileName = profileName?.trim();
    if (normalizedProfileName != null && normalizedProfileName.isNotEmpty) {
      return normalizedProfileName;
    }

    final normalizedEmail = email?.trim();
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      final alias = normalizedEmail.split('@').first.trim();
      if (alias.isNotEmpty) return alias;
    }

    return fallback;
  }

  String _resolveLoggedSellerName({String fallback = ''}) {
    final profile = ref.read(userProfileProvider).value;
    return _resolveSellerName(
      profileName: profile?.name,
      email: supabase.auth.currentUser?.email,
      fallback: fallback,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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
        _cart.add(CartItem(product: product));
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

  Future<void> _finishSale() async {
    if (_cart.isEmpty) return;

    final sellerName = _resolveLoggedSellerName();
    if (sellerName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível identificar o vendedor (usuário logado).',
            ),
          ),
        );
      }
      return;
    }

    final method = await _showPaymentDialog();
    if (method == null) return;

    setState(() => _isFinishing = true);
    try {
      final orgId = ref.read(currentOrgIdProvider);
      if (orgId == null) return;

      final repo = ref.read(pdvRepositoryProvider);
      final totalSnapshot = cartTotal;
      final receiptItems = _cart
          .map(
            (item) => NonFiscalReceiptItem(
              description: item.product.name,
              quantity: item.quantity,
              unitPrice: item.product.price,
              total: item.total,
            ),
          )
          .toList();

      final saleData = {
        'organization_id': orgId,
        'total_value': totalSnapshot,
        'seller_name': sellerName,
        'payment_method': method,
        'status': 'completed',
      };
      final items = _cart
          .map(
            (item) => <String, dynamic>{
              'product_id': item.product.id,
              'name': item.product.name,
              'quantity': item.quantity,
              'unit_price': item.product.price,
              'total_price': item.total,
            },
          )
          .toList();

      final createdSale = await repo.createSale(saleData, items);
      CompanySettings? companySettings;
      try {
        companySettings = await ref.read(companySettingsProvider.future);
      } catch (_) {
        companySettings = null;
      }
      final companyForReceipt =
          companySettings ??
          CompanySettings(
            id: 'local',
            organizationId: orgId,
            razaoSocial: 'DARTWORK ERP',
            nomeFantasia: 'DARTWORK ERP',
          );

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => NonFiscalReceiptDialog(
            saleId: createdSale.id,
            company: companyForReceipt,
            items: receiptItems,
            total: totalSnapshot,
            paymentMethod: _paymentLabel(method),
          ),
        );

        if (mounted) {
          setState(() {
            _cart.clear();
            _searchCtrl.clear();
            _searchResults = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _isFinishing = false);
    }
  }

  Future<String?> _showPaymentDialog() {
    final sellerName = _resolveLoggedSellerName(
      fallback: 'Vendedor não identificado',
    );
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forma de Pagamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Total: ${formatCurrency(cartTotal)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Vendedor: $sellerName',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...['dinheiro', 'pix', 'cartao_credito', 'cartao_debito'].map(
              (method) => ListTile(
                leading: Icon(_paymentIcon(method)),
                title: Text(_paymentLabel(method)),
                onTap: () => Navigator.pop(context, method),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _paymentIcon(String method) {
    switch (method) {
      case 'dinheiro':
        return Icons.money;
      case 'pix':
        return Icons.qr_code;
      case 'cartao_credito':
        return Icons.credit_card;
      case 'cartao_debito':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'dinheiro':
        return 'Dinheiro';
      case 'pix':
        return 'PIX';
      case 'cartao_credito':
        return 'Cartão de Crédito';
      case 'cartao_debito':
        return 'Cartão de Débito';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider).value;
    final sellerNameDisplay = _resolveSellerName(
      profileName: userProfile?.name,
      email: supabase.auth.currentUser?.email,
      fallback: 'Vendedor não identificado',
    );

    return AppScaffold(
      title: 'PDV',
      body: Column(
        children: [
          // Busca de produto
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Buscar produto ou código de barras...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchProducts,
            ),
          ),

          // Resultados da busca
          if (_searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, i) {
                    final p = _searchResults[i];
                    return ListTile(
                      dense: true,
                      title: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(formatCurrency(p.price)),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: AppColors.primary,
                        ),
                        onPressed: () => _addToCart(p),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Carrinho
          Expanded(
            child: _cart.isEmpty
                ? const EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Carrinho vazio',
                    subtitle: 'Busque e adicione produtos',
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
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      formatCurrency(item.product.price),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    onPressed: () =>
                                        _updateQuantity(i, item.quantity - 1),
                                    iconSize: 20,
                                  ),
                                  Text(
                                    item.quantity.toStringAsFixed(0),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () =>
                                        _updateQuantity(i, item.quantity + 1),
                                    iconSize: 20,
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  formatCurrency(item.total),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Rodapé com total e botão finalizar
          if (_cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withAlpha(100),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vendedor: $sellerNameDisplay',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              formatCurrency(cartTotal),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isFinishing ? null : _finishSale,
                            icon: _isFinishing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: const Text('Finalizar'),
                          ),
                        ),
                      ],
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
