import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../providers/organization_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/common_widgets.dart';

class GlobalSearchResult {
  final List<Map<String, dynamic>> clients;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> vehicles;
  final List<Map<String, dynamic>> serviceOrders;

  const GlobalSearchResult({
    this.clients = const [],
    this.products = const [],
    this.vehicles = const [],
    this.serviceOrders = const [],
  });
}

final globalSearchProvider = FutureProvider.family<GlobalSearchResult, String>((
  ref,
  query,
) async {
  final orgId = ref.watch(currentOrgIdProvider);
  final q = query.trim();

  if (orgId == null || q.length < 2) {
    return const GlobalSearchResult();
  }

  Future<List<Map<String, dynamic>>> safeQuery(
    Future<List<dynamic>> Function() callback,
  ) async {
    try {
      final response = await callback();
      return response.cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }

  final clientsFuture = safeQuery(
    () => supabase
        .from('clients')
        .select('id, name, document, email')
        .eq('organization_id', orgId)
        .or('name.ilike.%$q%,document.ilike.%$q%,email.ilike.%$q%')
        .limit(8),
  );

  final productsFuture = safeQuery(
    () => supabase
        .from('products')
        .select('id, name, sku, gtin, price')
        .eq('organization_id', orgId)
        .or('name.ilike.%$q%,sku.ilike.%$q%,gtin.ilike.%$q%')
        .limit(8),
  );

  final vehiclesFuture = safeQuery(
    () => supabase
        .from('vehicles')
        .select('id, placa, marca, modelo')
        .eq('organization_id', orgId)
        .or('placa.ilike.%$q%,marca.ilike.%$q%,modelo.ilike.%$q%')
        .limit(8),
  );

  // Para OS, fazemos filtro em memória para manter compatibilidade com joins.
  final serviceOrdersRaw = await safeQuery(
    () => supabase
        .from('ordens_servico')
        .select(
          'id, status, created_at, clients(name), vehicles(placa, modelo)',
        )
        .eq('organization_id', orgId)
        .order('created_at', ascending: false)
        .limit(60),
  );

  final searchLower = q.toLowerCase();
  final serviceOrders = serviceOrdersRaw
      .where((row) {
        final id = row['id']?.toString().toLowerCase() ?? '';
        final status = row['status']?.toString().toLowerCase() ?? '';
        final client = row['clients'] is Map<String, dynamic>
            ? (row['clients'] as Map<String, dynamic>)['name']?.toString() ?? ''
            : '';
        final vehicle = row['vehicles'] is Map<String, dynamic>
            ? (row['vehicles'] as Map<String, dynamic>)['placa']?.toString() ??
                  ''
            : '';
        final model = row['vehicles'] is Map<String, dynamic>
            ? (row['vehicles'] as Map<String, dynamic>)['modelo']?.toString() ??
                  ''
            : '';

        return id.contains(searchLower) ||
            status.contains(searchLower) ||
            client.toLowerCase().contains(searchLower) ||
            vehicle.toLowerCase().contains(searchLower) ||
            model.toLowerCase().contains(searchLower);
      })
      .take(8)
      .toList();

  final result = await Future.wait([
    clientsFuture,
    productsFuture,
    vehiclesFuture,
  ]);

  return GlobalSearchResult(
    clients: result[0],
    products: result[1],
    vehicles: result[2],
    serviceOrders: serviceOrders,
  );
});

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResult = ref.watch(globalSearchProvider(_query));
    return AppScaffold(
      title: 'Busca Global',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Buscar por cliente, placa, produto, OS...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar busca',
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          Expanded(
            child: _query.trim().length < 2
                ? const EmptyState(
                    icon: Icons.travel_explore_rounded,
                    title: 'Digite ao menos 2 caracteres',
                    subtitle:
                        'A busca combina clientes, produtos, veículos e ordens de serviço.',
                  )
                : searchResult.when(
                    data: (data) {
                      final hasResults =
                          data.clients.isNotEmpty ||
                          data.products.isNotEmpty ||
                          data.vehicles.isNotEmpty ||
                          data.serviceOrders.isNotEmpty;
                      if (!hasResults) {
                        return const EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'Nada encontrado',
                          subtitle: 'Tente outro termo.',
                        );
                      }
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        children: [
                          _ResultSection(
                            title: 'Clientes',
                            icon: Icons.people_alt_rounded,
                            items: data.clients,
                            itemBuilder: (ctx, row) => _ResultTile(
                              title: row['name']?.toString() ?? 'Cliente',
                              subtitle:
                                  'Doc: ${row['document'] ?? '-'} • ${row['email'] ?? 'sem e-mail'}',
                              icon: Icons.person_rounded,
                              onTap: () =>
                                  context.push('/clientes/${row['id']}'),
                            ),
                          ),
                          _ResultSection(
                            title: 'Produtos',
                            icon: Icons.inventory_2_rounded,
                            items: data.products,
                            itemBuilder: (ctx, row) => _ResultTile(
                              title: row['name']?.toString() ?? 'Produto',
                              subtitle:
                                  'SKU: ${row['sku'] ?? '-'} • GTIN: ${row['gtin'] ?? '-'}',
                              icon: Icons.category_rounded,
                              onTap: () =>
                                  context.push('/produtos/${row['id']}'),
                            ),
                          ),
                          _ResultSection(
                            title: 'Veículos',
                            icon: Icons.directions_car_rounded,
                            items: data.vehicles,
                            itemBuilder: (ctx, row) => _ResultTile(
                              title: row['placa']?.toString() ?? 'Veículo',
                              subtitle:
                                  '${row['marca'] ?? '-'} ${row['modelo'] ?? '-'}',
                              icon: Icons.drive_eta_rounded,
                              onTap: () =>
                                  context.push('/veiculos/${row['id']}'),
                            ),
                          ),
                          _ResultSection(
                            title: 'Ordens de Serviço',
                            icon: Icons.build_circle_rounded,
                            items: data.serviceOrders,
                            itemBuilder: (ctx, row) {
                              final client =
                                  row['clients'] is Map<String, dynamic>
                                  ? (row['clients']
                                                as Map<String, dynamic>)['name']
                                            ?.toString() ??
                                        '-'
                                  : '-';
                              final plate =
                                  row['vehicles'] is Map<String, dynamic>
                                  ? (row['vehicles']
                                                as Map<
                                                  String,
                                                  dynamic
                                                >)['placa']
                                            ?.toString() ??
                                        '-'
                                  : '-';
                              return _ResultTile(
                                title: 'OS ${row['id']}',
                                subtitle:
                                    '$client • Placa: $plate • Status: ${row['status'] ?? '-'}',
                                icon: Icons.build_rounded,
                                onTap: () => context.push(
                                  '/ordens-servico/${row['id']}',
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                    loading: () => const LoadingIndicator(
                      message: 'Buscando resultados...',
                    ),
                    error: (error, _) => EmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Erro na busca',
                      subtitle: error.toString(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> items;
  final Widget Function(BuildContext context, Map<String, dynamic> row)
  itemBuilder;

  const _ResultSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((row) => itemBuilder(context, row)),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ResultTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
