import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/permission_provider.dart';
import '../../providers/billing_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/organization_provider.dart';

/// Main drawer with module navigation.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final organizationAsync = ref.watch(currentOrganizationProvider);
    final permissions = ref.watch(permissionProvider);
    final billing = ref.watch(billingProvider);
    final currentPath = GoRouterState.of(context).matchedLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sections = _buildSections();

    return Drawer(
      backgroundColor: Colors.transparent,
      width: 318,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBg : AppColors.lightBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 60 : 18),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandBlue.withAlpha(55),
                        blurRadius: 20,
                        offset: const Offset(0, 9),
                      ),
                    ],
                  ),
                  child: userAsync.when(
                    data: (user) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(34),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withAlpha(80),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(user?.name),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: organizationAsync.when(
                                data: (org) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      org?.name ?? 'Work ERP',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      billing.planName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(210),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (_, _) => const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?.name ?? 'Usuário',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withAlpha(205),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    loading: () => const SizedBox(
                      height: 88,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white70,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    error: (_, _) => const Text(
                      'Erro ao carregar perfil',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    children: [
                      for (final section in sections) ...[
                        _SectionTitle(section.title),
                        for (final item in section.items)
                          if (_canDisplay(item, permissions, billing))
                            _NavItem(
                              icon: item.icon,
                              label: item.label,
                              path: item.path,
                              currentPath: currentPath,
                              activeMatches: item.activeMatches,
                            ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
                  child: _NavItem(
                    icon: Icons.settings_rounded,
                    label: 'Configurações',
                    path: '/configuracoes',
                    currentPath: currentPath,
                    activeMatches: const ['/configuracoes'],
                    isPinned: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await ref.read(authNotifierProvider.notifier).signOut();
                      },
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.danger,
                        size: 18,
                      ),
                      label: const Text(
                        'Sair da conta',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.danger.withAlpha(95)),
                        backgroundColor: AppColors.danger.withAlpha(14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _canDisplay(
    _DrawerItemData item,
    PermissionChecker permissions,
    BillingChecker billing,
  ) {
    if (item.adminOnly && !permissions.isAdmin) return false;
    if (item.permissionModule != null &&
        !permissions.canView(item.permissionModule!)) {
      return false;
    }
    if (item.billingFeature != null &&
        !billing.hasFeature(item.billingFeature!)) {
      return false;
    }
    return true;
  }

  List<_DrawerSectionData> _buildSections() {
    return [
      const _DrawerSectionData(
        title: 'PRINCIPAL',
        items: [
          _DrawerItemData(
            label: 'Dashboard',
            path: '/',
            icon: Icons.dashboard_rounded,
          ),
          _DrawerItemData(
            label: 'Assistente IA',
            path: '/assistente',
            icon: Icons.smart_toy_rounded,
            billingFeature: 'assistente_ia',
          ),
          _DrawerItemData(
            label: 'Busca Global',
            path: '/busca',
            icon: Icons.search_rounded,
          ),
          _DrawerItemData(
            label: 'Relatórios',
            path: '/relatorios',
            icon: Icons.insights_rounded,
            billingFeature: 'relatorios',
          ),
        ],
      ),
      const _DrawerSectionData(
        title: 'CADASTROS',
        items: [
          _DrawerItemData(
            label: 'Clientes',
            path: '/clientes',
            icon: Icons.people_rounded,
            permissionModule: 'clientes',
            billingFeature: 'clientes',
          ),
          _DrawerItemData(
            label: 'Veículos',
            path: '/veiculos',
            icon: Icons.directions_car_rounded,
            permissionModule: 'veiculos',
            billingFeature: 'veiculos',
          ),
          _DrawerItemData(
            label: 'Produtos',
            path: '/produtos',
            icon: Icons.inventory_2_rounded,
            permissionModule: 'produtos',
            billingFeature: 'produtos',
          ),
          _DrawerItemData(
            label: 'Fornecedores',
            path: '/fornecedores',
            icon: Icons.store_rounded,
            billingFeature: 'fornecedores',
          ),
          _DrawerItemData(
            label: 'Transportadoras',
            path: '/transportadoras',
            icon: Icons.local_shipping_rounded,
            billingFeature: 'transportadoras',
          ),
        ],
      ),
      const _DrawerSectionData(
        title: 'OPERAÇÕES',
        items: [
          _DrawerItemData(
            label: 'Ordens de Serviço',
            path: '/ordens-servico',
            icon: Icons.build_rounded,
            permissionModule: 'ordens_servico',
            billingFeature: 'ordens_servico',
          ),
          _DrawerItemData(
            label: 'Vendas',
            path: '/vendas',
            icon: Icons.shopping_bag_rounded,
            billingFeature: 'vendas',
          ),
          _DrawerItemData(
            label: 'Orçamentos',
            path: '/orcamentos',
            icon: Icons.request_quote_rounded,
            billingFeature: 'orcamentos',
          ),
          _DrawerItemData(
            label: 'Compras',
            path: '/compras',
            icon: Icons.inventory_rounded,
            billingFeature: 'compras',
          ),
          _DrawerItemData(
            label: 'PDV',
            path: '/pdv',
            icon: Icons.point_of_sale_rounded,
            permissionModule: 'pdv',
            billingFeature: 'pdv',
          ),
          _DrawerItemData(
            label: 'Caixa',
            path: '/caixa',
            icon: Icons.account_balance_wallet_rounded,
            permissionModule: 'caixa',
            billingFeature: 'caixa',
          ),
        ],
      ),
      const _DrawerSectionData(
        title: 'FINANCEIRO E FISCAL',
        items: [
          _DrawerItemData(
            label: 'Contas a Receber',
            path: '/receber',
            icon: Icons.arrow_downward_rounded,
            activeMatches: ['/financeiro/receivable'],
            billingFeature: 'contas_receber',
          ),
          _DrawerItemData(
            label: 'Contas a Pagar',
            path: '/pagar',
            icon: Icons.arrow_upward_rounded,
            activeMatches: ['/financeiro/payable'],
            billingFeature: 'contas_pagar',
          ),
          _DrawerItemData(
            label: 'Conciliação',
            path: '/conciliacao',
            icon: Icons.balance_rounded,
            billingFeature: 'conciliacao_bancaria',
          ),
          _DrawerItemData(
            label: 'Notas',
            path: '/notas',
            icon: Icons.receipt_rounded,
            activeMatches: ['/nfe', '/nfce', '/nfse'],
            billingFeature: 'nfe',
          ),
        ],
      ),
      const _DrawerSectionData(
        title: 'GESTÃO',
        items: [
          _DrawerItemData(
            label: 'Equipe',
            path: '/equipe',
            icon: Icons.groups_rounded,
            billingFeature: 'equipe',
          ),
          _DrawerItemData(
            label: 'Auditoria',
            path: '/auditoria',
            icon: Icons.fact_check_rounded,
          ),
          _DrawerItemData(
            label: 'Automações',
            path: '/automacoes',
            icon: Icons.auto_awesome_rounded,
            billingFeature: 'automacoes',
          ),
          _DrawerItemData(
            label: 'Indicações',
            path: '/indicacoes',
            icon: Icons.diversity_3_rounded,
          ),
          _DrawerItemData(
            label: 'Sugestões',
            path: '/sugestoes',
            icon: Icons.lightbulb_outline_rounded,
            billingFeature: 'sugestoes',
          ),
          _DrawerItemData(
            label: 'Admin Dashboard',
            path: '/admin-dashboard',
            icon: Icons.admin_panel_settings_rounded,
            adminOnly: true,
          ),
        ],
      ),
    ];
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final String currentPath;
  final List<String> activeMatches;
  final bool isPinned;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.currentPath,
    this.activeMatches = const [],
    this.isPinned = false,
  });

  @override
  Widget build(BuildContext context) {
    final candidates = <String>[path, ...activeMatches];
    final isActive = candidates.any(
      (candidate) =>
          currentPath == candidate || currentPath.startsWith('$candidate/'),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.brandGreen : AppColors.brandBlue;

    final tileBg = isActive
        ? activeColor.withAlpha(isDark ? 40 : 24)
        : Colors.transparent;

    final tileBorder = isActive
        ? activeColor.withAlpha(isDark ? 145 : 105)
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder).withAlpha(
            isPinned ? 150 : 0,
          );

    final textColor = isActive
        ? activeColor
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Material(
        color: tileBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context);
            if (!isActive) {
              GoRouter.of(context).go(path);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tileBorder, width: 1),
            ),
            child: Row(
              children: [
                Icon(icon, size: 19, color: textColor),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isActive)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: activeColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerSectionData {
  final String title;
  final List<_DrawerItemData> items;

  const _DrawerSectionData({required this.title, required this.items});
}

class _DrawerItemData {
  final String label;
  final String path;
  final IconData icon;
  final String? permissionModule;
  final String? billingFeature;
  final bool adminOnly;
  final List<String> activeMatches;

  const _DrawerItemData({
    required this.label,
    required this.path,
    required this.icon,
    this.permissionModule,
    this.billingFeature,
    this.adminOnly = false,
    this.activeMatches = const [],
  });
}
