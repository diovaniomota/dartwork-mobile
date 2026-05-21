import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/organization_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/common_widgets.dart';

enum _AuditTab { audit, access }

enum _AuditPeriod { today, last7Days, last30Days, last90Days, all }

class _ActionMeta {
  final String label;
  final Color color;
  final IconData icon;

  const _ActionMeta({
    required this.label,
    required this.color,
    required this.icon,
  });
}

const Map<String, _ActionMeta> _actionMeta = {
  'INSERT': _ActionMeta(
    label: 'Criação',
    color: AppColors.success,
    icon: Icons.add_rounded,
  ),
  'UPDATE': _ActionMeta(
    label: 'Alteração',
    color: AppColors.brandBlue,
    icon: Icons.edit_rounded,
  ),
  'DELETE': _ActionMeta(
    label: 'Exclusão',
    color: AppColors.danger,
    icon: Icons.delete_rounded,
  ),
  'LOGIN': _ActionMeta(
    label: 'Acesso',
    color: Color(0xFF7F56D9),
    icon: Icons.login_rounded,
  ),
  'AUTO_SETTLEMENT': _ActionMeta(
    label: 'Baixa Automática',
    color: AppColors.info,
    icon: Icons.sync_rounded,
  ),
  'APPROVAL_LINK_GENERATED': _ActionMeta(
    label: 'Link de Aprovação',
    color: AppColors.warning,
    icon: Icons.send_rounded,
  ),
  'APPROVAL_DECISION': _ActionMeta(
    label: 'Decisão',
    color: AppColors.success,
    icon: Icons.check_circle_rounded,
  ),
};

const Map<String, String> _tableLabels = {
  'products': 'Produtos',
  'clients': 'Clientes',
  'sales': 'Vendas',
  'ordens_servico': 'Ordens de Serviço',
  'os_itens': 'Itens da O.S.',
  'finance_receivables': 'Contas a Receber',
  'finance_payables': 'Contas a Pagar',
  'finance_transactions': 'Transações Financeiras',
  'organizations': 'Organização',
  'company_settings': 'Configurações',
  'team_goals': 'Metas da Equipe',
  'commission_rules': 'Regras de Comissão',
  'finance_auto_rules': 'Regras Automáticas',
  'digital_quotes': 'Orçamentos Digitais',
  'sessions': 'Acessos',
};

const Map<String, String> _fieldLabels = {
  'name': 'Nome',
  'nome': 'Nome',
  'price': 'Preço de Venda',
  'cost_price': 'Preço de Custo',
  'stock_quantity': 'Estoque',
  'description': 'Descrição',
  'sku': 'SKU',
  'active': 'Ativo',
  'category_id': 'Categoria',
  'organization_id': 'Organização',
  'client_id': 'Cliente',
  'vehicle_id': 'Veículo',
  'status': 'Status',
  'total_amount': 'Valor Total',
  'amount': 'Valor',
  'discount': 'Desconto',
  'email': 'E-mail',
  'phone': 'Telefone',
  'cpf': 'CPF',
  'cnpj': 'CNPJ',
  'address': 'Endereço',
  'city': 'Cidade',
  'state': 'Estado',
  'zip_code': 'CEP',
  'role': 'Perfil',
  'permissions': 'Permissões',
};

class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
  static const int _pageSize = 40;

  _AuditTab _activeTab = _AuditTab.audit;
  _AuditPeriod _periodFilter = _AuditPeriod.last30Days;
  String _tableFilter = '';
  String _actionFilter = '';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentOffset = 0;
  String? _error;
  String? _expandedLogId;
  List<Map<String, dynamic>> _logs = const [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _fetchLogs(reset: true),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs({bool reset = false}) async {
    if (_isLoadingMore) return;
    if (!reset && !_hasMore) return;

    final orgId = ref.read(currentOrgIdProvider);

    if (orgId == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _error = 'Não foi possível identificar a organização ativa.';
        _logs = const [];
      });
      return;
    }

    setState(() {
      if (reset) {
        _isLoading = true;
        _currentOffset = 0;
        _hasMore = true;
        _logs = const [];
      } else {
        _isLoadingMore = true;
      }
      _error = null;
    });

    try {
      List<Map<String, dynamic>> rawRows;

      try {
        rawRows = await _queryLogs(
          orgId: orgId,
          applyServerFilters: true,
          offset: _currentOffset,
          limit: _pageSize,
        );
      } catch (_) {
        rawRows = await _queryLogs(
          orgId: orgId,
          applyServerFilters: false,
          offset: _currentOffset,
          limit: _pageSize,
        );
      }

      final rows = _applyClientFilters(rawRows);

      if (!mounted) return;
      setState(() {
        _logs = reset ? rows : [..._logs, ...rows];
        _currentOffset += rawRows.length;
        _hasMore = rawRows.length == _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      final message = e.toString();
      final missingTable =
          message.contains('audit_logs') &&
          (message.contains('PGRST205') ||
              message.contains('42P01') ||
              message.toLowerCase().contains('does not exist'));

      if (!mounted) return;
      setState(() {
        if (reset) _logs = const [];
        _isLoading = false;
        _isLoadingMore = false;
        _error = missingTable
            ? 'A tabela de auditoria ainda não está habilitada nesta base.'
            : 'Falha ao carregar os registros de auditoria.';
      });
    }
  }

  void _changeTab(_AuditTab tab) {
    if (_activeTab == tab) return;
    setState(() {
      _activeTab = tab;
      _expandedLogId = null;
      if (tab == _AuditTab.access) {
        _tableFilter = '';
        _actionFilter = '';
      } else {
        _tableFilter = '';
        _actionFilter = '';
      }
    });
    _fetchLogs(reset: true);
  }

  void _onSearchChanged(String value) {
    if (_searchQuery == value) return;
    setState(() => _searchQuery = value);

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      _fetchLogs(reset: true);
    });
  }

  DateTime? _periodStartDate() {
    final now = DateTime.now();

    switch (_periodFilter) {
      case _AuditPeriod.today:
        return DateTime(now.year, now.month, now.day);
      case _AuditPeriod.last7Days:
        return now.subtract(const Duration(days: 7));
      case _AuditPeriod.last30Days:
        return now.subtract(const Duration(days: 30));
      case _AuditPeriod.last90Days:
        return now.subtract(const Duration(days: 90));
      case _AuditPeriod.all:
        return null;
    }
  }

  String _periodLabel(_AuditPeriod period) {
    switch (period) {
      case _AuditPeriod.today:
        return 'Hoje';
      case _AuditPeriod.last7Days:
        return 'Últimos 7 dias';
      case _AuditPeriod.last30Days:
        return 'Últimos 30 dias';
      case _AuditPeriod.last90Days:
        return 'Últimos 90 dias';
      case _AuditPeriod.all:
        return 'Todo período';
    }
  }

  String _serverSearchTerm() {
    final term = _searchQuery.trim();
    if (term.isEmpty) return '';

    final safe = term
        .replaceAll(RegExp(r'[,%]'), ' ')
        .replaceAll(RegExp(r'[^a-zA-Z0-9@._\-\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return safe;
  }

  Future<List<Map<String, dynamic>>> _queryLogs({
    required String orgId,
    required bool applyServerFilters,
    required int offset,
    required int limit,
  }) async {
    dynamic query = supabase
        .from('audit_logs')
        .select('*')
        .eq('organization_id', orgId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    if (applyServerFilters) {
      final periodStart = _periodStartDate();
      if (periodStart != null) {
        query = query.gte('created_at', periodStart.toIso8601String());
      }

      if (_activeTab == _AuditTab.access) {
        query = query.eq('table_name', 'sessions');
      } else {
        query = query.neq('table_name', 'sessions');
        if (_tableFilter.isNotEmpty) {
          query = query.eq('table_name', _tableFilter);
        }
        if (_actionFilter.isNotEmpty) {
          query = query.eq('action', _actionFilter);
        }
      }

      final serverSearch = _serverSearchTerm();
      if (serverSearch.isNotEmpty) {
        final like = '%$serverSearch%';
        query = query.or(
          'user_email.ilike.$like,table_name.ilike.$like,record_id.ilike.$like,action.ilike.$like',
        );
      }
    }

    final response = await query;
    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  List<Map<String, dynamic>> _applyClientFilters(
    List<Map<String, dynamic>> rows,
  ) {
    final periodStart = _periodStartDate();
    final searchNeedle = _normalizeText(_searchQuery.trim());

    bool hasSearchMatch(Map<String, dynamic> log) {
      if (searchNeedle.isEmpty) return true;
      final oldData = _asMap(log['old_data']);
      final newData = _asMap(log['new_data']);
      final tokens = <String>[
        (log['user_email'] ?? '').toString(),
        (log['ip_address'] ?? '').toString(),
        (log['table_name'] ?? '').toString(),
        (log['record_id'] ?? '').toString(),
        (log['action'] ?? '').toString(),
        _tableLabel(log['table_name']?.toString()),
        _recordLabel(log),
        ..._extractSearchTokens(oldData),
        ..._extractSearchTokens(newData),
      ];
      return tokens.any(
        (token) => _normalizeText(token).contains(searchNeedle),
      );
    }

    final filtered = rows.where((log) {
      final table = (log['table_name'] ?? '').toString();
      final action = (log['action'] ?? '').toString().toUpperCase();
      final createdAt = _parseDate(log['created_at']?.toString());

      if (_activeTab == _AuditTab.access) {
        if (table != 'sessions') return false;
      } else {
        if (table == 'sessions') return false;
        if (_tableFilter.isNotEmpty && table != _tableFilter) return false;
        if (_actionFilter.isNotEmpty && action != _actionFilter) return false;
      }

      if (periodStart != null) {
        if (createdAt == null || createdAt.isBefore(periodStart)) return false;
      }

      if (!hasSearchMatch(log)) return false;

      return true;
    }).toList();

    filtered.sort((a, b) {
      final aDate = _parseDate(a['created_at']?.toString());
      final bDate = _parseDate(b['created_at']?.toString());
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    return filtered;
  }

  List<String> _extractSearchTokens(Map<String, dynamic> data) {
    const priorityFields = [
      'name',
      'nome',
      'razao_social',
      'email',
      'cpf',
      'cnpj',
      'placa',
      'vehicle_plate',
      'status',
    ];

    final tokens = <String>[];
    for (final field in priorityFields) {
      final value = data[field];
      if (value != null) tokens.add(value.toString());
    }

    return tokens;
  }

  String _normalizeText(String value) {
    final input = value.toLowerCase();

    return input
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _activeTab == _AuditTab.audit
        ? 'Rastreabilidade de alterações por módulo'
        : 'Histórico de acessos ao sistema';

    return AppScaffold(
      title: 'Auditoria',
      subtitle: subtitle,
      body: RefreshIndicator(
        onRefresh: () => _fetchLogs(reset: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            _buildHeaderCard(context),
            const SizedBox(height: 12),
            _buildTabSelector(),
            const SizedBox(height: 10),
            _buildSearchAndPeriod(context),
            if (_activeTab == _AuditTab.audit) ...[
              const SizedBox(height: 10),
              _buildFilters(context),
            ],
            const SizedBox(height: 12),
            _buildSummary(context),
            const SizedBox(height: 12),
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1A305A), Color(0xFF1D4C7C)]
              : const [Color(0xFF1D69AE), Color(0xFF1F8A8B)],
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.brandBlue).withAlpha(60),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(32),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withAlpha(55)),
            ),
            child: const Icon(Icons.fact_check_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Logs de Auditoria',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Quem fez, quando fez e o que foi alterado.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(220),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.3,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _fetchLogs(reset: true),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha(60)),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return SegmentedButton<_AuditTab>(
      segments: const [
        ButtonSegment<_AuditTab>(
          value: _AuditTab.audit,
          icon: Icon(Icons.edit_note_rounded),
          label: Text('Alterações'),
        ),
        ButtonSegment<_AuditTab>(
          value: _AuditTab.access,
          icon: Icon(Icons.login_rounded),
          label: Text('Acessos'),
        ),
      ],
      selected: {_activeTab},
      onSelectionChanged: (selection) => _changeTab(selection.first),
    );
  }

  Widget _buildSearchAndPeriod(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 680;

    if (compact) {
      return Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Buscar por usuário, IP, tabela ou registro',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.trim().isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Limpar busca',
                    ),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<_AuditPeriod>(
            key: ValueKey('period-filter-compact-${_periodFilter.name}'),
            initialValue: _periodFilter,
            decoration: const InputDecoration(
              labelText: 'Período',
              prefixIcon: Icon(Icons.date_range_rounded),
            ),
            isExpanded: true,
            items: _AuditPeriod.values
                .map(
                  (period) => DropdownMenuItem(
                    value: period,
                    child: Text(_periodLabel(period)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null || value == _periodFilter) return;
              setState(() => _periodFilter = value);
              _fetchLogs(reset: true);
            },
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Buscar por usuário, IP, tabela ou registro',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.trim().isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Limpar busca',
                    ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 230,
          child: DropdownButtonFormField<_AuditPeriod>(
            key: ValueKey('period-filter-wide-${_periodFilter.name}'),
            initialValue: _periodFilter,
            decoration: const InputDecoration(
              labelText: 'Período',
              prefixIcon: Icon(Icons.date_range_rounded),
            ),
            isExpanded: true,
            items: _AuditPeriod.values
                .map(
                  (period) => DropdownMenuItem(
                    value: period,
                    child: Text(_periodLabel(period)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null || value == _periodFilter) return;
              setState(() => _periodFilter = value);
              _fetchLogs(reset: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    final tableOptions = _availableTableFilters();
    final actionOptions = _availableActionFilters();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;

        if (compact) {
          return Column(
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey('table-filter-compact-$_tableFilter'),
                initialValue: _tableFilter.isEmpty ? null : _tableFilter,
                decoration: const InputDecoration(
                  labelText: 'Tabela',
                  prefixIcon: Icon(Icons.table_rows_rounded),
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Todas as tabelas'),
                  ),
                  ...tableOptions.map(
                    (table) => DropdownMenuItem(
                      value: table,
                      child: Text(_tableLabel(table)),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _tableFilter = value ?? '');
                  _fetchLogs(reset: true);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                key: ValueKey('action-filter-compact-$_actionFilter'),
                initialValue: _actionFilter.isEmpty ? null : _actionFilter,
                decoration: const InputDecoration(
                  labelText: 'Ação',
                  prefixIcon: Icon(Icons.filter_alt_rounded),
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Todas as ações'),
                  ),
                  ...actionOptions.map(
                    (action) => DropdownMenuItem(
                      value: action,
                      child: Text(_actionLabel(action)),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _actionFilter = value ?? '');
                  _fetchLogs(reset: true);
                },
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey('table-filter-wide-$_tableFilter'),
                initialValue: _tableFilter.isEmpty ? null : _tableFilter,
                decoration: const InputDecoration(
                  labelText: 'Tabela',
                  prefixIcon: Icon(Icons.table_rows_rounded),
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Todas as tabelas'),
                  ),
                  ...tableOptions.map(
                    (table) => DropdownMenuItem(
                      value: table,
                      child: Text(_tableLabel(table)),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _tableFilter = value ?? '');
                  _fetchLogs(reset: true);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey('action-filter-wide-$_actionFilter'),
                initialValue: _actionFilter.isEmpty ? null : _actionFilter,
                decoration: const InputDecoration(
                  labelText: 'Ação',
                  prefixIcon: Icon(Icons.filter_alt_rounded),
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Todas as ações'),
                  ),
                  ...actionOptions.map(
                    (action) => DropdownMenuItem(
                      value: action,
                      child: Text(_actionLabel(action)),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _actionFilter = value ?? '');
                  _fetchLogs(reset: true);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummary(BuildContext context) {
    final now = DateTime.now();
    final todayCount = _logs.where((log) {
      final timestamp = _parseDate(log['created_at']?.toString());
      return timestamp != null &&
          timestamp.year == now.year &&
          timestamp.month == now.month &&
          timestamp.day == now.day;
    }).length;
    final criticalCount = _logs.where((log) {
      final action = (log['action'] ?? '').toString().toUpperCase();
      return action == 'DELETE' || action == 'APPROVAL_DECISION';
    }).length;
    final uniqueUsers = _logs
        .map((log) => (log['user_email'] ?? '').toString().trim())
        .where((email) => email.isNotEmpty)
        .toSet()
        .length;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Hoje',
            value: '$todayCount',
            icon: Icons.today_rounded,
            color: AppColors.brandBlue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            title: 'Usuários',
            value: '$uniqueUsers',
            icon: Icons.people_alt_rounded,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            title: 'Críticos',
            value: '$criticalCount',
            icon: Icons.warning_amber_rounded,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: LoadingIndicator(message: 'Carregando auditoria...'),
      );
    }

    if (_error != null) {
      return EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Não foi possível carregar a auditoria',
        subtitle: _error!,
        action: FilledButton.icon(
          onPressed: () => _fetchLogs(reset: true),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tentar novamente'),
        ),
      );
    }

    if (_logs.isEmpty) {
      return EmptyState(
        icon: Icons.fact_check_outlined,
        title: 'Nenhum registro encontrado',
        subtitle: _activeTab == _AuditTab.access
            ? 'Ainda não há eventos de acesso para os filtros aplicados.'
            : 'Ainda não há alterações para os filtros aplicados.',
      );
    }

    return Column(
      children: [
        ..._logs.map(
          (log) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildLogCard(context, log),
          ),
        ),
        if (_hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: OutlinedButton.icon(
              onPressed: _isLoadingMore ? null : () => _fetchLogs(),
              icon: _isLoadingMore
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more_rounded),
              label: Text(
                _isLoadingMore ? 'Carregando...' : 'Carregar mais registros',
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Fim dos registros para os filtros atuais.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _buildLogCard(BuildContext context, Map<String, dynamic> log) {
    final id = (log['id'] ?? '').toString();
    final action = (log['action'] ?? '').toString().toUpperCase();
    final meta =
        _actionMeta[action] ??
        const _ActionMeta(
          label: 'Evento',
          color: AppColors.lightTextMuted,
          icon: Icons.event_note_rounded,
        );
    final isExpanded = _expandedLogId == id;
    final oldData = _asMap(log['old_data']);
    final newData = _asMap(log['new_data']);
    final changedFields = _resolveChangedFields(log, oldData, newData);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() => _expandedLogId = isExpanded ? null : id);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: meta.color.withAlpha(20),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: meta.color.withAlpha(55)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(meta.icon, size: 14, color: meta.color),
                        const SizedBox(width: 5),
                        Text(
                          meta.label,
                          style: TextStyle(
                            color: meta.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _tableLabel(log['table_name']?.toString()),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                _recordLabel(log),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _MetaPill(
                    icon: Icons.person_outline_rounded,
                    label: (log['user_email'] ?? 'Sistema').toString(),
                  ),
                  _MetaPill(
                    icon: Icons.schedule_rounded,
                    label: _formatDate(log['created_at']?.toString()),
                  ),
                  if ((log['ip_address'] ?? '').toString().isNotEmpty)
                    _MetaPill(
                      icon: Icons.language_rounded,
                      label: (log['ip_address']).toString(),
                    ),
                ],
              ),
              if (isExpanded) ...[
                const Divider(height: 18),
                if (action == 'UPDATE' && changedFields.isNotEmpty)
                  _buildChangesSection(context, changedFields, oldData, newData)
                else
                  _buildSnapshotSection(
                    context,
                    newData.isNotEmpty ? newData : oldData,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangesSection(
    BuildContext context,
    List<String> fields,
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) {
    final visibleFields = fields.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Campos alterados',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...visibleFields.map(
          (field) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: _DiffRow(
              label: _fieldLabels[field] ?? field,
              oldValue: _formatValue(field, oldData[field]),
              newValue: _formatValue(field, newData[field]),
            ),
          ),
        ),
        if (fields.length > visibleFields.length)
          Text(
            '+${fields.length - visibleFields.length} campos adicionais',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _buildSnapshotSection(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    if (data.isEmpty) {
      return Text(
        'Sem detalhes adicionais para este evento.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    final entries = data.entries
        .where((entry) => !_isTechnicalField(entry.key))
        .take(8)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalhes do registro',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 122,
                  child: Text(
                    _fieldLabels[entry.key] ?? entry.key,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatValue(entry.key, entry.value),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<String> _availableTableFilters() {
    final set = <String>{
      ..._tableLabels.keys.where((key) => key != 'sessions'),
      ..._logs
          .map((item) => item['table_name'])
          .whereType<String>()
          .where((table) => table != 'sessions'),
    };
    final list = set.toList();
    list.sort((a, b) => _tableLabel(a).compareTo(_tableLabel(b)));
    return list;
  }

  List<String> _availableActionFilters() {
    final set = <String>{
      ..._actionMeta.keys.where((key) => key != 'LOGIN'),
      ..._logs.map((item) => item['action']).whereType<String>(),
    };
    final list = set.where((value) => value != 'LOGIN').toList();
    list.sort();
    return list;
  }

  List<String> _resolveChangedFields(
    Map<String, dynamic> log,
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) {
    final raw = log['changed_fields'];

    if (raw is List) {
      return raw.map((field) => field.toString()).toList();
    }

    if (raw is Map) {
      return raw.keys.map((field) => field.toString()).toList();
    }

    if ((log['action'] ?? '').toString().toUpperCase() != 'UPDATE') {
      return const [];
    }

    final keys = {...oldData.keys, ...newData.keys}
      ..removeWhere(_isTechnicalField);

    return keys
        .where(
          (key) =>
              _formatValue(key, oldData[key]) !=
              _formatValue(key, newData[key]),
        )
        .toList();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return {};
  }

  String _recordLabel(Map<String, dynamic> log) {
    final action = (log['action'] ?? '').toString().toUpperCase();
    if (action == 'LOGIN') return 'Sessão iniciada';

    final data = _asMap(log['new_data']).isNotEmpty
        ? _asMap(log['new_data'])
        : _asMap(log['old_data']);

    final recordId = (log['record_id'] ?? '').toString();
    final fallbackId = recordId.isEmpty
        ? ''
        : (recordId.length > 10 ? recordId.substring(0, 10) : recordId);

    final name =
        data['name'] ??
        data['nome'] ??
        data['razao_social'] ??
        data['vehicle_plate'] ??
        data['placa'];

    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString();
    }

    return fallbackId.isEmpty
        ? 'Registro sem identificação'
        : 'ID: $fallbackId';
  }

  String _tableLabel(String? tableName) {
    if (tableName == null || tableName.isEmpty) return 'Registro';
    return _tableLabels[tableName] ?? tableName;
  }

  String _actionLabel(String action) {
    return _actionMeta[action]?.label ?? action;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Sem data';
    final date = _parseDate(dateStr);
    if (date == null) return 'Sem data';
    return _dateFormat.format(date.toLocal());
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  bool _isTechnicalField(String field) {
    return field == 'id' ||
        field == 'created_at' ||
        field == 'updated_at' ||
        field == 'organization_id';
  }

  String _formatValue(String key, dynamic value) {
    if (value == null) return 'vazio';

    if (value is bool) return value ? 'Sim' : 'Não';

    if (value is num) {
      final lowerKey = key.toLowerCase();
      if (lowerKey.contains('price') ||
          lowerKey.contains('amount') ||
          lowerKey.contains('valor') ||
          lowerKey.contains('cost') ||
          lowerKey.contains('total')) {
        return NumberFormat.currency(
          locale: 'pt_BR',
          symbol: 'R\$',
        ).format(value);
      }
      return value.toString();
    }

    if (value is String) {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(value)) {
        final date = DateTime.tryParse(value);
        if (date != null) return _dateFormat.format(date.toLocal());
      }
      return value;
    }

    if (value is Map || value is List) {
      return const JsonEncoder.withIndent('  ').convert(value);
    }

    return value.toString();
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: Theme.of(context).cardColor.withAlpha(isDark ? 218 : 252),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 11.2),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).cardColor.withAlpha(isDark ? 190 : 240),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12.5,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiffRow extends StatelessWidget {
  final String label;
  final String oldValue;
  final String newValue;

  const _DiffRow({
    required this.label,
    required this.oldValue,
    required this.newValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  oldValue,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11.5,
                    color: AppColors.danger,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  newValue,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11.5,
                    color: AppColors.success,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
