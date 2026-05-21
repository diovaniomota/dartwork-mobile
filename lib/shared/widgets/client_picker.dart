import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/client.dart';
import '../../data/repositories/client_repository.dart';
import '../../providers/auth_provider.dart';

class ClientPicker extends ConsumerStatefulWidget {
  final Function(ClientModel) onSelected;

  const ClientPicker({super.key, required this.onSelected});

  @override
  ConsumerState<ClientPicker> createState() => _ClientPickerState();
}

class _ClientPickerState extends ConsumerState<ClientPicker> {
  String _search = '';
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final orgId = ref.watch(userProfileProvider).value?.organizationId ?? '';
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Selecionar Cliente', style: theme.textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nome, documento...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _search = '';
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (val) => setState(() => _search = val),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<ClientModel>>(
              future: ref
                  .read(clientRepositoryProvider)
                  .getAll(orgId, search: _search),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }

                final clients = snapshot.data ?? [];

                if (clients.isEmpty) {
                  return const Center(
                    child: Text('Nenhum cliente encontrado.'),
                  );
                }

                return ListView.separated(
                  itemCount: clients.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    final displayName = client.displayName;
                    final normalizedDisplayName = displayName.trim();
                    final initial = normalizedDisplayName.isNotEmpty
                        ? normalizedDisplayName.substring(0, 1).toUpperCase()
                        : '?';

                    return ListTile(
                      title: Text(displayName),
                      subtitle: Text(client.document ?? 'Sem documento'),
                      leading: CircleAvatar(child: Text(initial)),
                      onTap: () {
                        widget.onSelected(client);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
