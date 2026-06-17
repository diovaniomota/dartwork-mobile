import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/organization_provider.dart';
import '../../core/utils/billing_access.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/clients/screens/clients_screen.dart';
import '../../features/clients/screens/client_form_screen.dart';
import '../../features/suppliers/screens/suppliers_screen.dart';
import '../../features/suppliers/screens/supplier_form_screen.dart';
import '../../features/financial/screens/financial_screen.dart';
import '../../features/financial/screens/financial_form_screen.dart';
import '../../features/transport/screens/transporters_screen.dart';
import '../../features/transport/screens/transporter_form_screen.dart';
import '../../features/sales/screens/sales_screen.dart';
import '../../features/sales/screens/sale_form_screen.dart';
import '../../features/vehicles/screens/vehicles_screen.dart';
import '../../features/vehicles/screens/vehicle_form_screen.dart';
import '../../features/products/screens/products_screen.dart';
import '../../features/products/screens/product_form_screen.dart';
import '../../features/service_orders/screens/service_orders_screen.dart';
import '../../features/service_orders/screens/service_order_form_screen.dart';
import '../../features/service_orders/screens/service_order_detail_screen.dart';
import '../../features/fiscal/screens/fiscal_screen.dart';
import '../../features/fiscal/screens/nfe_form_screen.dart';
import '../../features/fiscal/screens/nfce_pdv_screen.dart';
import '../../features/fiscal/screens/nfse_form_screen.dart';
import '../../features/pdv/screens/pdv_screen.dart';
import '../../features/cash_register/screens/cash_register_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/profile_screen.dart';
import '../../features/settings/screens/fiscal_settings_screen.dart';
import '../../features/settings/screens/company_screen.dart';
import '../../features/settings/screens/plan_screen.dart';
import '../../features/settings/screens/help_screen.dart';
import '../../features/settings/screens/certificate_screen.dart';
import '../../features/settings/screens/users_screen.dart';
import '../../features/settings/screens/accountant_screen.dart';
import '../../features/settings/screens/checklist_settings_screen.dart';
import '../../features/settings/screens/advanced_settings_screen.dart';
import '../../features/purchases/screens/purchases_screen.dart';
import '../../features/purchases/screens/purchase_form_screen.dart';
import '../../features/budgets/screens/budgets_screen.dart';
import '../../features/budgets/screens/budget_form_screen.dart';
import '../../features/modules/screens/global_search_screen.dart';
import '../../features/modules/screens/reports_screen.dart';
import '../../features/modules/screens/module_center_screen.dart';
import '../../features/modules/screens/audit_screen.dart';
import '../../features/modules/screens/blocked_screen.dart';
import '../../features/modules/screens/mobile_blocked_screen.dart';
import '../../features/assistant/screens/assistant_screen.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerRefreshNotifierProvider = Provider<_RouterRefreshNotifier>((ref) {
  final notifier = _RouterRefreshNotifier();

  ref.listen(authStateProvider, (previous, next) => notifier.refresh());
  ref.listen(userProfileProvider, (previous, next) => notifier.refresh());
  ref.listen(
    currentOrganizationProvider,
    (previous, next) => notifier.refresh(),
  );

  ref.onDispose(notifier.dispose);
  return notifier;
});

/// Provider do GoRouter com guarda de autenticação.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final userProfile = ref.read(userProfileProvider);
      final organizationAsync = ref.read(currentOrganizationProvider);

      if (authState.isLoading) return null;

      final isLoggedIn = authState.value != null;
      final isLoginRoute = state.matchedLocation == '/login';
      final isBlockedRoute = state.matchedLocation == '/blocked';
      final isMobileBlockedRoute = state.matchedLocation == '/mobile-bloqueado';
      final isPlanRoute =
          state.matchedLocation == '/configuracoes/plano' ||
          state.matchedLocation == '/planos' ||
          state.matchedLocation == '/cadastro/pagamento';

      if (!isLoggedIn && !isLoginRoute) return '/login';

      if (isLoggedIn) {
        final isSuperAdmin = userProfile.valueOrNull?.isSuperAdmin == true;
        final org = organizationAsync.valueOrNull;

        if (!isSuperAdmin && shouldBlockByBillingPolicy(org)) {
          if (!isBlockedRoute && !isPlanRoute) return '/blocked';
        } else if (!isSuperAdmin && shouldBlockByMobileAccess(org)) {
          // Acesso mobile não liberado para esta organização
          if (!isMobileBlockedRoute) return '/mobile-bloqueado';
        } else if (isBlockedRoute || isMobileBlockedRoute) {
          return '/';
        }

        if (isLoginRoute) return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/blocked',
        builder: (context, state) => const BlockedScreen(),
      ),
      GoRoute(
        path: '/mobile-bloqueado',
        builder: (context, state) => const MobileBlockedScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(
        path: '/assistente',
        builder: (context, state) => const AssistantScreen(),
      ),

      // Dashboards/Admin
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) => const ModuleCenterScreen(
          title: 'Admin Dashboard',
          subtitle: 'Gestão avançada de organizações e métricas globais.',
          heroIcon: Icons.admin_panel_settings_rounded,
          bullets: [
            'Acompanhe indicadores de uso e operação.',
            'Acesse rapidamente módulos críticos de gestão.',
            'Use as telas administrativas já disponíveis no app.',
          ],
          shortcuts: [
            ModuleShortcut(
              title: 'Relatórios',
              description: 'Visão consolidada do negócio.',
              route: '/relatorios',
              icon: Icons.insights_rounded,
            ),
            ModuleShortcut(
              title: 'Usuários e Equipe',
              description: 'Gerencie perfis e permissões.',
              route: '/equipe',
              icon: Icons.groups_2_rounded,
            ),
            ModuleShortcut(
              title: 'Configurações',
              description: 'Defina parâmetros da operação.',
              route: '/configuracoes',
              icon: Icons.settings_rounded,
            ),
          ],
        ),
      ),
      GoRoute(
        path: '/admin/clientes',
        builder: (context, state) => const ClientsScreen(),
      ),

      // Busca e relatórios
      GoRoute(
        path: '/busca',
        builder: (context, state) => const GlobalSearchScreen(),
      ),
      GoRoute(
        path: '/relatorios',
        builder: (context, state) => const ReportsScreen(),
      ),

      // Módulos equivalentes ao web
      GoRoute(
        path: '/equipe',
        builder: (context, state) => const UsersScreen(),
      ),
      GoRoute(
        path: '/auditoria',
        builder: (context, state) => const AuditScreen(),
      ),
      GoRoute(
        path: '/automacoes',
        builder: (context, state) => const ModuleCenterScreen(
          title: 'Automações',
          subtitle: 'Central de fluxos automáticos do ERP.',
          heroIcon: Icons.auto_awesome_rounded,
          bullets: [
            'Configure processos de cobrança e faturamento.',
            'Defina estratégias por módulo e operação.',
            'Ajuste recursos avançados conforme o plano.',
          ],
          shortcuts: [
            ModuleShortcut(
              title: 'Configurações Avançadas',
              description: 'Ajustes técnicos e operacionais.',
              route: '/configuracoes/avancadas',
              icon: Icons.tune_rounded,
            ),
            ModuleShortcut(
              title: 'Fiscal',
              description: 'Parâmetros de emissão e tributação.',
              route: '/configuracoes/fiscal',
              icon: Icons.receipt_long_rounded,
            ),
            ModuleShortcut(
              title: 'Checklist',
              description: 'Padronize processos internos.',
              route: '/configuracoes/checklist',
              icon: Icons.checklist_rounded,
            ),
          ],
        ),
      ),
      GoRoute(
        path: '/conciliacao',
        builder: (context, state) => const ModuleCenterScreen(
          title: 'Conciliação',
          subtitle: 'Concilie caixa, pagar e receber com visão integrada.',
          heroIcon: Icons.balance_rounded,
          bullets: [
            'Compare títulos pendentes e movimentações.',
            'Acesse rapidamente os lançamentos financeiros.',
            'Use a análise mensal para identificar desvios.',
          ],
          shortcuts: [
            ModuleShortcut(
              title: 'Contas a Receber',
              description: 'Controle de receitas em aberto.',
              route: '/receber',
              icon: Icons.arrow_downward_rounded,
            ),
            ModuleShortcut(
              title: 'Contas a Pagar',
              description: 'Controle de despesas em aberto.',
              route: '/pagar',
              icon: Icons.arrow_upward_rounded,
            ),
            ModuleShortcut(
              title: 'Caixa',
              description: 'Movimentações e saldo operacional.',
              route: '/caixa',
              icon: Icons.point_of_sale_rounded,
            ),
          ],
        ),
      ),
      GoRoute(
        path: '/indicacoes',
        builder: (context, state) => const ModuleCenterScreen(
          title: 'Indicações',
          subtitle: 'Acompanhe crescimento por rede de indicação.',
          heroIcon: Icons.how_to_reg_rounded,
          bullets: [
            'Monitore entrada de novos clientes.',
            'Acompanhe métricas comerciais relacionadas.',
            'Use o dashboard de vendas para follow-up.',
          ],
          shortcuts: [
            ModuleShortcut(
              title: 'Clientes',
              description: 'Cadastros e relacionamento.',
              route: '/clientes',
              icon: Icons.people_rounded,
            ),
            ModuleShortcut(
              title: 'Vendas',
              description: 'Conversão e resultado comercial.',
              route: '/vendas',
              icon: Icons.shopping_bag_rounded,
            ),
          ],
        ),
      ),
      GoRoute(
        path: '/sugestoes',
        builder: (context, state) => const ModuleCenterScreen(
          title: 'Sugestões',
          subtitle: 'Canal para evolução contínua do seu processo.',
          heroIcon: Icons.lightbulb_outline_rounded,
          bullets: [
            'Registre melhorias para o fluxo operacional.',
            'Use os atalhos para validar impactos rapidamente.',
            'Centralize feedback com o time.',
          ],
          shortcuts: [
            ModuleShortcut(
              title: 'Relatórios',
              description: 'Valide impactos por indicadores.',
              route: '/relatorios',
              icon: Icons.query_stats_rounded,
            ),
            ModuleShortcut(
              title: 'Busca Global',
              description: 'Investigação rápida de dados.',
              route: '/busca',
              icon: Icons.search_rounded,
            ),
          ],
        ),
      ),

      // Rotas de alias da versão web
      GoRoute(
        path: '/perfil',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(path: '/planos', builder: (context, state) => const PlanScreen()),
      GoRoute(
        path: '/cadastro',
        builder: (context, state) => const CompanyScreen(),
      ),
      GoRoute(
        path: '/cadastro/pagamento',
        builder: (context, state) => const PlanScreen(),
      ),

      // Clientes
      GoRoute(
        path: '/clientes',
        builder: (context, state) => const ClientsScreen(),
      ),
      GoRoute(
        path: '/clientes/novo',
        builder: (context, state) => const ClientFormScreen(),
      ),
      GoRoute(
        path: '/clientes/:id',
        builder: (context, state) =>
            ClientFormScreen(clientId: state.pathParameters['id']),
      ),

      // Fornecedores
      GoRoute(
        path: '/fornecedores',
        builder: (context, state) => const SuppliersScreen(),
      ),
      GoRoute(
        path: '/fornecedores/novo',
        builder: (context, state) => const SupplierFormScreen(id: 'novo'),
      ),
      GoRoute(
        path: '/fornecedores/:id',
        builder: (context, state) =>
            SupplierFormScreen(id: state.pathParameters['id']!),
      ),

      // Vendas
      GoRoute(
        path: '/vendas',
        builder: (context, state) => const SalesScreen(),
      ),
      GoRoute(
        path: '/vendas/novo',
        builder: (context, state) => const SaleFormScreen(id: 'novo'),
      ),
      GoRoute(
        path: '/vendas/:id',
        builder: (context, state) =>
            SaleFormScreen(id: state.pathParameters['id']!),
      ),

      // Transportadoras
      GoRoute(
        path: '/transportadoras',
        builder: (context, state) => const TransportersScreen(),
      ),
      GoRoute(
        path: '/transportadoras/novo',
        name: 'transporterCreate',
        builder: (context, state) => const TransporterFormScreen(id: 'novo'),
      ),
      GoRoute(
        path: '/transportadoras/:id',
        name: 'transporterForm',
        builder: (context, state) =>
            TransporterFormScreen(id: state.pathParameters['id']!),
      ),

      // Compras
      GoRoute(
        path: '/compras',
        builder: (context, state) => const PurchasesScreen(),
      ),
      GoRoute(
        path: '/compras/nova',
        builder: (context, state) => const PurchaseFormScreen(),
      ),
      GoRoute(
        path: '/compras/novo',
        builder: (context, state) => const PurchaseFormScreen(),
      ),
      GoRoute(
        path: '/compras/:id',
        builder: (context, state) =>
            PurchaseFormScreen(purchaseId: state.pathParameters['id']),
      ),

      // Orçamentos Digitais
      GoRoute(
        path: '/orcamentos',
        builder: (context, state) => const BudgetsScreen(),
      ),
      GoRoute(
        path: '/orcamentos/novo',
        builder: (context, state) => const BudgetFormScreen(),
      ),
      GoRoute(
        path: '/orcamentos/:id',
        builder: (context, state) =>
            BudgetFormScreen(budgetId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/orcamentos/aprovar/:token',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          final shortToken = token.length > 12
              ? '${token.substring(0, 12)}...'
              : token;
          return ModuleCenterScreen(
            title: 'Aprovação de Orçamento',
            subtitle: 'Token recebido: $shortToken',
            heroIcon: Icons.verified_rounded,
            bullets: const [
              'A aprovação por token é centralizada no fluxo web.',
              'No mobile você pode revisar e atualizar orçamentos.',
              'Use os atalhos para acessar o módulo operacional.',
            ],
            shortcuts: const [
              ModuleShortcut(
                title: 'Orçamentos',
                description: 'Lista e edição de orçamentos.',
                route: '/orcamentos',
                icon: Icons.request_quote_rounded,
              ),
              ModuleShortcut(
                title: 'Ordens de Serviço',
                description: 'Converter e acompanhar execução.',
                route: '/ordens-servico',
                icon: Icons.build_rounded,
              ),
            ],
          );
        },
      ),

      // Fiscal e notas
      GoRoute(
        path: '/notas',
        builder: (context, state) => const ModuleCenterScreen(
          title: 'Notas',
          subtitle: 'Central fiscal com emissão e gestão de documentos.',
          heroIcon: Icons.receipt_rounded,
          bullets: [
            'Gerencie NF-e, NFC-e e NFS-e em um único fluxo.',
            'Acesse atalhos de emissão direta.',
            'Monitore documentos pelo painel fiscal.',
          ],
          shortcuts: [
            ModuleShortcut(
              title: 'NF-e',
              description: 'Notas de produto (modelo 55).',
              route: '/nfe',
              icon: Icons.receipt_long_rounded,
            ),
            ModuleShortcut(
              title: 'NFC-e',
              description: 'Consumidor final no PDV (modelo 65).',
              route: '/nfce',
              icon: Icons.point_of_sale_rounded,
            ),
            ModuleShortcut(
              title: 'NFS-e',
              description: 'Notas de serviço.',
              route: '/nfse',
              icon: Icons.room_service_rounded,
            ),
          ],
        ),
      ),
      GoRoute(
        path: '/notas/emitir',
        builder: (context, state) => const ModuleCenterScreen(
          title: 'Emitir Nota',
          subtitle: 'Escolha o tipo de documento fiscal para emissão.',
          heroIcon: Icons.edit_document,
          shortcuts: [
            ModuleShortcut(
              title: 'Nova NF-e',
              description: 'Emitir nota fiscal eletrônica.',
              route: '/nfe/novo',
              icon: Icons.description_rounded,
            ),
            ModuleShortcut(
              title: 'Nova NFC-e',
              description: 'Emitir venda ao consumidor.',
              route: '/nfce/novo',
              icon: Icons.receipt_rounded,
            ),
            ModuleShortcut(
              title: 'Nova NFS-e',
              description: 'Emitir serviço eletrônico.',
              route: '/nfse/novo',
              icon: Icons.design_services_rounded,
            ),
          ],
        ),
      ),
      GoRoute(
        path: '/fiscal/naturezas',
        builder: (context, state) => const ModuleCenterScreen(
          title: 'Naturezas Fiscais',
          subtitle: 'Gerencie classificações e regras fiscais.',
          heroIcon: Icons.rule_rounded,
          shortcuts: [
            ModuleShortcut(
              title: 'Configuração Fiscal',
              description: 'Parâmetros de tributação da empresa.',
              route: '/configuracoes/fiscal',
              icon: Icons.settings_suggest_rounded,
            ),
            ModuleShortcut(
              title: 'NFE',
              description: 'Aplicar regras em emissão de produtos.',
              route: '/nfe',
              icon: Icons.receipt_long_rounded,
            ),
          ],
        ),
      ),
      GoRoute(
        path: '/nfe',
        name: 'nfeList',
        builder: (context, state) => const FiscalScreen(tipoModelo: '55'),
      ),
      GoRoute(
        path: '/nfce',
        name: 'nfceList',
        builder: (context, state) => const FiscalScreen(tipoModelo: '65'),
      ),
      GoRoute(
        path: '/nfse',
        name: 'nfseList',
        builder: (context, state) => const FiscalScreen(tipoModelo: 'nfse'),
      ),
      GoRoute(
        path: '/nfe/novo',
        name: 'nfeForm',
        builder: (context, state) => const NfeFormScreen(tipoModelo: '55'),
      ),
      GoRoute(
        path: '/nfe/nova',
        builder: (context, state) => const NfeFormScreen(tipoModelo: '55'),
      ),
      GoRoute(
        path: '/nfce/novo',
        name: 'nfceForm',
        builder: (context, state) => const NfcePdvScreen(),
      ),
      GoRoute(
        path: '/nfce/nova',
        builder: (context, state) => const NfcePdvScreen(),
      ),
      GoRoute(
        path: '/nfce/emitir',
        builder: (context, state) => const NfcePdvScreen(),
      ),
      GoRoute(
        path: '/nfse/novo',
        name: 'nfseForm',
        builder: (context, state) => const NfseFormScreen(),
      ),
      GoRoute(
        path: '/nfse/emitir',
        builder: (context, state) => const NfseFormScreen(),
      ),
      GoRoute(
        path: '/nfse-teste',
        builder: (context, state) => const NfseFormScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const LoginScreen(),
      ),

      // Veículos
      GoRoute(
        path: '/veiculos',
        builder: (context, state) => const VehiclesScreen(),
      ),
      GoRoute(
        path: '/veiculos/novo',
        builder: (context, state) => const VehicleFormScreen(),
      ),
      GoRoute(
        path: '/veiculos/:id',
        builder: (context, state) =>
            VehicleFormScreen(vehicleId: state.pathParameters['id']),
      ),

      // Financeiro (rotas novas + aliases /pagar e /receber)
      GoRoute(
        path: '/financeiro/:type',
        builder: (context, state) =>
            FinancialScreen(type: state.pathParameters['type']!),
      ),
      GoRoute(
        path: '/financeiro/:type/:id',
        builder: (context, state) => FinancialFormScreen(
          type: state.pathParameters['type']!,
          id: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/receber',
        builder: (context, state) => const FinancialScreen(type: 'receivable'),
      ),
      GoRoute(
        path: '/receber/novo',
        builder: (context, state) =>
            const FinancialFormScreen(type: 'receivable', id: 'novo'),
      ),
      GoRoute(
        path: '/pagar',
        builder: (context, state) => const FinancialScreen(type: 'payable'),
      ),
      GoRoute(
        path: '/pagar/novo',
        builder: (context, state) =>
            const FinancialFormScreen(type: 'payable', id: 'novo'),
      ),
      GoRoute(
        path: '/pagar/editar/:id',
        builder: (context, state) => FinancialFormScreen(
          type: 'payable',
          id: state.pathParameters['id']!,
        ),
      ),

      // Produtos
      GoRoute(
        path: '/produtos',
        builder: (context, state) => const ProductsScreen(),
      ),
      GoRoute(
        path: '/produtos/novo',
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        path: '/produtos/:id',
        builder: (context, state) =>
            ProductFormScreen(productId: state.pathParameters['id']),
      ),

      // Ordens de serviço
      GoRoute(
        path: '/ordens-servico',
        builder: (context, state) => const ServiceOrdersScreen(),
      ),
      GoRoute(
        path: '/ordens-servico/nova',
        builder: (context, state) => const ServiceOrderFormScreen(),
      ),
      GoRoute(
        path: '/ordens-servico/kanban',
        builder: (context, state) => const ServiceOrdersScreen(),
      ),
      GoRoute(
        path: '/ordens-servico/:id/editar',
        builder: (context, state) =>
            ServiceOrderFormScreen(orderId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/ordens-servico/:id',
        builder: (context, state) =>
            ServiceOrderDetailScreen(orderId: state.pathParameters['id']!),
      ),

      // PDV e caixa
      GoRoute(path: '/pdv', builder: (context, state) => const PdvScreen()),
      GoRoute(
        path: '/caixa',
        builder: (context, state) => const CashRegisterScreen(),
      ),
      GoRoute(
        path: '/caixa/movimentacoes',
        builder: (context, state) => const CashRegisterScreen(),
      ),

      // Configurações e subtelas
      GoRoute(
        path: '/configuracoes',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'perfil',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'fiscal',
            builder: (context, state) => const FiscalSettingsScreen(),
          ),
          GoRoute(
            path: 'empresa',
            builder: (context, state) => const CompanyScreen(),
          ),
          GoRoute(
            path: 'plano',
            builder: (context, state) => const PlanScreen(),
          ),
          GoRoute(
            path: 'ajuda',
            builder: (context, state) => const HelpScreen(),
          ),
          GoRoute(
            path: 'certificado',
            builder: (context, state) => const CertificateScreen(),
          ),
          GoRoute(
            path: 'usuarios',
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: 'contador',
            builder: (context, state) => const AccountantScreen(),
          ),
          GoRoute(
            path: 'checklist',
            builder: (context, state) => const ChecklistSettingsScreen(),
          ),
          GoRoute(
            path: 'avancadas',
            builder: (context, state) => const AdvancedSettingsScreen(),
          ),
          GoRoute(
            path: 'funcoes',
            builder: (context, state) => const AdvancedSettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
