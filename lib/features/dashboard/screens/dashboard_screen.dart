import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/organization_provider.dart';
import '../../../providers/permission_provider.dart';
import '../../../providers/billing_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/common_widgets.dart';

final dashboardStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return {};

  final results = await Future.wait([
    supabase.from('clients').select('id').eq('organization_id', orgId),
    supabase.from('vehicles').select('id').eq('organization_id', orgId),
    supabase.from('products').select('id').eq('organization_id', orgId),
    supabase.from('ordens_servico').select('id').eq('organization_id', orgId),
    supabase
        .from('ordens_servico')
        .select('id')
        .eq('organization_id', orgId)
        .eq('status', 'aberta'),
  ]);

  return {
    'clientes': (results[0] as List).length,
    'veiculos': (results[1] as List).length,
    'produtos': (results[2] as List).length,
    'os_total': (results[3] as List).length,
    'os_abertas': (results[4] as List).length,
  };
});

final todayRevenueProvider = FutureProvider<double>((ref) async {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return 0;

  final today = DateTime.now();
  final startOfDay = DateTime(
    today.year,
    today.month,
    today.day,
  ).toIso8601String();

  final response = await supabase
      .from('cash_movements')
      .select('amount')
      .eq('organization_id', orgId)
      .inFilter('type', ['sale', 'deposit'])
      .gte('created_at', startOfDay);

  double total = 0;
  for (final row in (response as List)) {
    final val = row['amount'];
    if (val is num) total += val.toDouble();
  }
  return total;
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final revenue = ref.watch(todayRevenueProvider);
    final permissions = ref.watch(permissionProvider);
    final billing = ref.watch(billingProvider);
    final org = ref.watch(currentOrganizationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final todayLabel = DateFormat(
      "EEEE, dd 'de' MMMM",
      'pt_BR',
    ).format(DateTime.now());
    final screenWidth = MediaQuery.sizeOf(context).width;
    final quickCrossAxisCount = screenWidth >= 950
        ? 4
        : screenWidth >= 720
        ? 3
        : 2;
    final quickAspectRatio = screenWidth >= 950
        ? 1.34
        : screenWidth >= 720
        ? 1.26
        : 1.14;

    final quickActions = <_QuickActionData>[
      if (permissions.canCreate('ordens_servico'))
        _QuickActionData(
          icon: Icons.add_circle_rounded,
          label: 'Nova OS',
          subtitle: 'Abrir ordem de serviço',
          badge: 'Operação',
          colorA: AppColors.brandBlue,
          colorB: const Color(0xFF1C67AB),
          onTap: () => context.push('/ordens-servico/nova'),
        ),
      if (permissions.canView('pdv') && billing.hasFeature('pdv'))
        _QuickActionData(
          icon: Icons.point_of_sale_rounded,
          label: 'Abrir PDV',
          subtitle: 'Atendimento no caixa',
          badge: 'Venda',
          colorA: AppColors.brandGreen,
          colorB: const Color(0xFF0F8D8A),
          onTap: () => context.push('/pdv'),
        ),
      if (permissions.canCreate('clientes'))
        _QuickActionData(
          icon: Icons.person_add_rounded,
          label: 'Novo cliente',
          subtitle: 'Cadastrar contato',
          badge: 'Cadastro',
          colorA: AppColors.info,
          colorB: const Color(0xFF166C90),
          onTap: () => context.push('/clientes/novo'),
        ),
      if (permissions.canView('caixa') && billing.hasFeature('caixa'))
        _QuickActionData(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Movimentar caixa',
          subtitle: 'Entradas e saídas',
          badge: 'Financeiro',
          colorA: const Color(0xFF4B5D7A),
          colorB: const Color(0xFF344762),
          onTap: () => context.push('/caixa'),
        ),
    ];

    final moduleChips = [
      if (billing.hasFeature('assistente_ia'))
        const _ModuleChip(
          label: 'Assistente IA',
          icon: Icons.smart_toy_rounded,
          route: '/assistente',
        ),
      const _ModuleChip(
        label: 'Busca',
        icon: Icons.search_rounded,
        route: '/busca',
      ),
      if (billing.hasFeature('relatorios'))
        const _ModuleChip(
          label: 'Relatorios',
          icon: Icons.bar_chart_rounded,
          route: '/relatorios',
        ),
      const _ModuleChip(
        label: 'Auditoria',
        icon: Icons.fact_check_rounded,
        route: '/auditoria',
      ),
      if (billing.hasFeature('automacoes'))
        const _ModuleChip(
          label: 'Automacoes',
          icon: Icons.auto_awesome_rounded,
          route: '/automacoes',
        ),
      if (billing.hasFeature('conciliacao_bancaria'))
        const _ModuleChip(
          label: 'Conciliacao',
          icon: Icons.balance_rounded,
          route: '/conciliacao',
        ),
      if (billing.hasFeature('nfe'))
        const _ModuleChip(
          label: 'Notas',
          icon: Icons.receipt_long_rounded,
          route: '/notas',
        ),
    ];

    return AppScaffold(
      title: 'Dashboard',
      subtitle: 'Operacao em tempo real da sua empresa',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(todayRevenueProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
          children: [
            org.when(
              data: (organization) => _CompanyBanner(
                companyName: organization?.name ?? 'Empresa ativa',
                planName: billing.planName,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            revenue.when(
              data: (value) => _RevenueHero(
                amount: value,
                todayLabel: todayLabel,
                isDark: isDark,
              ),
              loading: () => const _RevenueHeroLoading(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            const _SectionLabel(
              title: 'Indicadores da operação',
              subtitle: 'Resumo de clientes, estoque e ordens abertas',
            ),
            const SizedBox(height: 10),
            stats.when(
              data: (data) {
                final cards = <Widget>[
                  if (permissions.canView('ordens_servico'))
                    StatCard(
                      title: 'OS abertas',
                      value: '${data['os_abertas'] ?? 0}',
                      icon: Icons.build_rounded,
                      color: AppColors.warning,
                      subtitle: 'Atendimento em andamento',
                      onTap: () => context.push('/ordens-servico'),
                    ),
                  if (permissions.canView('clientes'))
                    StatCard(
                      title: 'Clientes',
                      value: '${data['clientes'] ?? 0}',
                      icon: Icons.people_rounded,
                      color: AppColors.brandBlue,
                      subtitle: 'Base ativa cadastrada',
                      onTap: () => context.push('/clientes'),
                    ),
                  if (permissions.canView('veiculos'))
                    StatCard(
                      title: 'Veiculos',
                      value: '${data['veiculos'] ?? 0}',
                      icon: Icons.directions_car_rounded,
                      color: AppColors.info,
                      subtitle: 'Frota vinculada',
                      onTap: () => context.push('/veiculos'),
                    ),
                  if (permissions.canView('produtos'))
                    StatCard(
                      title: 'Produtos',
                      value: '${data['produtos'] ?? 0}',
                      icon: Icons.inventory_2_rounded,
                      color: AppColors.success,
                      subtitle: 'Itens no estoque',
                      onTap: () => context.push('/produtos'),
                    ),
                ];

                if (cards.isEmpty) {
                  return const EmptyState(
                    icon: Icons.visibility_off_rounded,
                    title: 'Sem indicadores disponíveis',
                    subtitle:
                        'Seu usuário não possui módulos com leitura no momento.',
                  );
                }

                final width = MediaQuery.sizeOf(context).width;
                final crossAxisCount = width >= 900
                    ? 4
                    : width >= 700
                    ? 3
                    : 2;
                final indicatorAspectRatio = width >= 900
                    ? 1.22
                    : width >= 700
                    ? 1.12
                    : 1.02;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cards.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: indicatorAspectRatio,
                  ),
                  itemBuilder: (_, index) => cards[index],
                );
              },
              loading: () =>
                  const LoadingIndicator(message: 'Carregando indicadores...'),
              error: (error, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Erro ao carregar indicadores',
                subtitle: error.toString(),
              ),
            ),
            const SizedBox(height: 18),
            const _SectionLabel(
              title: 'Atalhos rápidos',
              subtitle: 'Ações frequentes para acelerar a operação',
            ),
            const SizedBox(height: 10),
            if (quickActions.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('Nenhum atalho disponível para seu perfil.'),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: quickActions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: quickCrossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: quickAspectRatio,
                ),
                itemBuilder: (_, index) {
                  final action = quickActions[index];
                  return _QuickActionButton(data: action);
                },
              ),
            const SizedBox(height: 18),
            const _SectionLabel(
              title: 'Módulos web no mobile',
              subtitle: 'Acesso rápido aos recursos do painel web',
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: moduleChips),
            const SizedBox(height: 16),
            _NavigationCard(
              icon: Icons.admin_panel_settings_rounded,
              title: 'Admin dashboard',
              subtitle: 'Acesso rápido para painéis administrativos.',
              onTap: () => context.push('/admin-dashboard'),
            ),
            const SizedBox(height: 10),
            _NavigationCard(
              icon: Icons.settings_rounded,
              title: 'Configurações e funções',
              subtitle:
                  'Fiscal, certificado, usuários, checklist e recursos avançados.',
              onTap: () => context.push('/configuracoes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionLabel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.brandGreen : AppColors.brandBlue,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'PAINEL',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12.1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CompanyBanner extends StatelessWidget {
  final String companyName;
  final String planName;

  const _CompanyBanner({required this.companyName, required this.planName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withAlpha(isDark ? 220 : 250),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.business_rounded, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Plano $planName',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueHero extends StatelessWidget {
  final double amount;
  final String todayLabel;
  final bool isDark;

  const _RevenueHero({
    required this.amount,
    required this.todayLabel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1B9B8F), Color(0xFF166D8F)]
              : const [Color(0xFF159B8A), Color(0xFF1A7FA6)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.brandGreen : AppColors.brandBlue)
                .withAlpha(70),
            blurRadius: 24,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(36),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Faturamento do dia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      todayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withAlpha(220),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatCurrency(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueHeroLoading extends StatelessWidget {
  const _RevenueHeroLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final String subtitle;
  final String badge;
  final Color colorA;
  final Color colorB;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.badge,
    required this.colorA,
    required this.colorB,
    required this.onTap,
  });
}

class _QuickActionButton extends StatefulWidget {
  final _QuickActionData data;

  const _QuickActionButton({required this.data});

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final radius = BorderRadius.circular(22);

    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      scale: _pressed ? 0.985 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: data.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          splashColor: Colors.white.withAlpha(38),
          highlightColor: Colors.white.withAlpha(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [data.colorA, data.colorB],
              ),
              border: Border.all(color: Colors.white.withAlpha(84), width: 0.7),
              boxShadow: [
                BoxShadow(
                  color: data.colorA.withAlpha(_pressed ? 76 : 112),
                  blurRadius: _pressed ? 11 : 20,
                  offset: Offset(0, _pressed ? 4 : 10),
                ),
                BoxShadow(
                  color: Colors.black.withAlpha(_pressed ? 26 : 42),
                  blurRadius: _pressed ? 8 : 15,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -26,
                  right: -18,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(24),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -34,
                  left: -16,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withAlpha(16),
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(34),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withAlpha(90),
                        width: 0.8,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_outward_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white.withAlpha(36),
                              border: Border.all(
                                color: Colors.white.withAlpha(95),
                                width: 0.9,
                              ),
                            ),
                            child: Icon(
                              data.icon,
                              color: Colors.white,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 34),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: Colors.white.withAlpha(34),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      data.badge,
                                      maxLines: 1,
                                      softWrap: false,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.35,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        data.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          letterSpacing: -0.1,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        data.subtitle,
                        style: TextStyle(
                          color: Colors.white.withAlpha(228),
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white.withAlpha(28),
                          border: Border.all(
                            color: Colors.white.withAlpha(70),
                            width: 0.7,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Acessar agora',
                              style: TextStyle(
                                color: Colors.white.withAlpha(245),
                                fontWeight: FontWeight.w700,
                                fontSize: 11.3,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String route;

  const _ModuleChip({
    required this.label,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ActionChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      backgroundColor: Theme.of(context).cardColor,
      side: BorderSide(
        color: isDark
            ? AppColors.darkBorderStrong
            : AppColors.lightBorderStrong,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onPressed: () => context.push(route),
    );
  }
}

class _NavigationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavigationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.brandGreen : AppColors.brandBlue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).dividerColor),
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 26 : 8),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                bottom: 0,
                child: Container(
                  width: 6,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(18),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [accentColor, accentColor.withAlpha(90)],
                    ),
                  ),
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: accentColor.withAlpha(isDark ? 30 : 18),
                    border: Border.all(color: accentColor.withAlpha(60)),
                  ),
                  child: Icon(icon, color: accentColor),
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    color: accentColor.withAlpha(isDark ? 22 : 12),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: accentColor.withAlpha(210),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
