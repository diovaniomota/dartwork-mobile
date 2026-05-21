import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/transporter.dart';
import '../../../data/repositories/transporter_repository.dart';
import '../../../providers/organization_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/common_widgets.dart';

final transporterRepositoryProvider = Provider(
  (ref) => TransporterRepository(),
);

final transportersProvider = FutureProvider.family<List<Transporter>, String?>((
  ref,
  search,
) async {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return [];
  final repo = ref.read(transporterRepositoryProvider);
  return await repo.getAll(orgId, search: search);
});

class TransportersScreen extends ConsumerStatefulWidget {
  const TransportersScreen({super.key});

  @override
  ConsumerState<TransportersScreen> createState() => _TransportersScreenState();
}

class _TransportersScreenState extends ConsumerState<TransportersScreen> {
  final _searchCtrl = TextEditingController();
  String? _searchQuery;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() => _searchQuery = value.isEmpty ? null : value);
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(transportersProvider(_searchQuery));

    return AppScaffold(
      title: 'Transportadoras',
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transportadoras/novo'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar transportadora...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearch('');
                        },
                      )
                    : null,
              ),
              onSubmitted: _onSearch,
            ),
          ),
          Expanded(
            child: asyncData.when(
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: 'Nenhuma transportadora',
                    subtitle: 'Use o botão + para adicionar',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(transportersProvider(_searchQuery)),
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final item = list[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withAlpha(30),
                            child: Icon(
                              Icons.local_shipping,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.document != null &&
                                  item.document!.isNotEmpty)
                                Text('CNPJ: ${item.document}'),
                              if (item.city != null && item.state != null)
                                Text('${item.city} - ${item.state}'),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              context.push('/transportadoras/${item.id}'),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const LoadingIndicator(),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Erro de listagem',
                subtitle: e.toString(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
