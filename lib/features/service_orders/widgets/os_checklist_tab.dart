import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/service_order.dart';
import '../../../data/repositories/service_order_repository.dart';
import '../../../providers/organization_provider.dart';

class OsChecklistTab extends ConsumerStatefulWidget {
  final ServiceOrder order;
  final VoidCallback onChanged;

  const OsChecklistTab({
    super.key,
    required this.order,
    required this.onChanged,
  });

  @override
  ConsumerState<OsChecklistTab> createState() => _OsChecklistTabState();
}

class _OsChecklistTabState extends ConsumerState<OsChecklistTab> {
  final _repo = ServiceOrderRepository();
  final _kmCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _tanqueNivel;
  Map<String, String?> _items = {};
  List<String> _itemNames = [];

  static const _fuelLevels = ['Vazio', '1/4', '1/2', '3/4', 'Cheio'];

  bool get _isReadOnly => const [
        'finalizada',
        'faturada',
        'cancelada',
      ].contains(widget.order.status.toLowerCase());

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _kmCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final orgId =
        ref.read(currentOrgIdProvider) ?? widget.order.organizationId;

    final customItems = await _repo.getChecklistItems(orgId);
    final itemsMap = <String, String?>{for (final n in customItems) n: null};

    final existing = await _repo.getChecklist(widget.order.id, orgId);
    if (existing != null) {
      final savedItems =
          existing['items'] as Map<String, dynamic>? ?? {};
      for (final entry in savedItems.entries) {
        if (itemsMap.containsKey(entry.key)) {
          itemsMap[entry.key] = entry.value?.toString();
        }
      }
      _obsCtrl.text = existing['observacoes']?.toString() ?? '';
    }

    if (widget.order.kmEntrada != null) {
      _kmCtrl.text = widget.order.kmEntrada.toString();
    }

    if (mounted) {
      setState(() {
        _itemNames = customItems;
        _items = itemsMap;
        _tanqueNivel = widget.order.tanqueNivel;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final orgId =
          ref.read(currentOrgIdProvider) ?? widget.order.organizationId;
      final kmValue = int.tryParse(_kmCtrl.text.trim());

      await _repo.saveChecklist(
        widget.order.id,
        orgId,
        items: _items.map((k, v) => MapEntry(k, v ?? '')),
        observacoes:
            _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
        kmEntrada: kmValue,
        tanqueNivel: _tanqueNivel,
      );

      widget.onChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Checklist salvo!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao salvar: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleStatus(String item, String status) {
    if (_isReadOnly) return;
    setState(() {
      _items[item] = _items[item] == status ? null : status;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
          children: [
            _MedicoesCard(
              kmCtrl: _kmCtrl,
              tanqueNivel: _tanqueNivel,
              fuelLevels: _fuelLevels,
              readOnly: _isReadOnly,
              onFuelTap: (level) =>
                  setState(() => _tanqueNivel = level),
            ),
            _InspecaoCard(
              itemNames: _itemNames,
              items: _items,
              readOnly: _isReadOnly,
              onToggle: _toggleStatus,
            ),
            _ObsCard(ctrl: _obsCtrl, readOnly: _isReadOnly),
          ],
        ),
        if (!_isReadOnly)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Salvando...' : 'Salvar Checklist'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _MedicoesCard extends StatelessWidget {
  final TextEditingController kmCtrl;
  final String? tanqueNivel;
  final List<String> fuelLevels;
  final bool readOnly;
  final ValueChanged<String> onFuelTap;

  const _MedicoesCard({
    required this.kmCtrl,
    required this.tanqueNivel,
    required this.fuelLevels,
    required this.readOnly,
    required this.onFuelTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTitle(
                icon: Icons.speed_outlined, title: 'Medições', theme: theme),
            const Divider(height: 18),
            Text('Quilometragem',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 6),
            TextFormField(
              controller: kmCtrl,
              readOnly: readOnly,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '0',
                suffixText: 'KM',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),
            Text('Nível de combustível',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 8),
            Row(
              children: fuelLevels.map((level) {
                final selected = tanqueNivel == level;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: readOnly ? null : () => onFuelTap(level),
                      borderRadius: BorderRadius.circular(6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: selected
                              ? theme.colorScheme.primary
                              : null,
                          border: Border.all(
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          level,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: selected
                                ? theme.colorScheme.onPrimary
                                : null,
                            fontWeight:
                                selected ? FontWeight.w600 : null,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InspecaoCard extends StatelessWidget {
  final List<String> itemNames;
  final Map<String, String?> items;
  final bool readOnly;
  final void Function(String item, String status) onToggle;

  const _InspecaoCard({
    required this.itemNames,
    required this.items,
    required this.readOnly,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist_rounded,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Inspeção Visual',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Icon(Icons.check_circle,
                    size: 13, color: Colors.green.shade600),
                const SizedBox(width: 2),
                Text('OK',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontSize: 10)),
                const SizedBox(width: 6),
                Icon(Icons.warning_amber_rounded,
                    size: 13, color: Colors.orange.shade600),
                const SizedBox(width: 2),
                Text('Aten.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontSize: 10)),
                const SizedBox(width: 6),
                Icon(Icons.cancel, size: 13, color: Colors.red.shade600),
                const SizedBox(width: 2),
                Text('Ruim',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontSize: 10)),
              ],
            ),
            const Divider(height: 18),
            for (final item in itemNames)
              _ItemRow(
                item: item,
                status: items[item],
                readOnly: readOnly,
                onToggle: (s) => onToggle(item, s),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final String item;
  final String? status;
  final bool readOnly;
  final ValueChanged<String> onToggle;

  const _ItemRow({
    required this.item,
    required this.status,
    required this.readOnly,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color? border;
    Color? bg;
    if (status == 'ok') {
      border = Colors.green.shade600;
      bg = Colors.green.withValues(alpha: 0.07);
    } else if (status == 'atencao') {
      border = Colors.orange.shade600;
      bg = Colors.orange.withValues(alpha: 0.07);
    } else if (status == 'ruim') {
      border = Colors.red.shade600;
      bg = Colors.red.withValues(alpha: 0.07);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border ?? theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(item,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          _Btn(
            icon: Icons.check_circle_outline,
            activeIcon: Icons.check_circle,
            color: Colors.green.shade600,
            active: status == 'ok',
            onTap: () => onToggle('ok'),
          ),
          const SizedBox(width: 4),
          _Btn(
            icon: Icons.warning_amber_outlined,
            activeIcon: Icons.warning_amber_rounded,
            color: Colors.orange.shade600,
            active: status == 'atencao',
            onTap: () => onToggle('atencao'),
          ),
          const SizedBox(width: 4),
          _Btn(
            icon: Icons.cancel_outlined,
            activeIcon: Icons.cancel,
            color: Colors.red.shade600,
            active: status == 'ruim',
            onTap: () => onToggle('ruim'),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _Btn({
    required this.icon,
    required this.activeIcon,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : null,
          border: Border.all(
              color: active ? color : Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          active ? activeIcon : icon,
          size: 20,
          color: active
              ? color
              : Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _ObsCard extends StatelessWidget {
  final TextEditingController ctrl;
  final bool readOnly;

  const _ObsCard({required this.ctrl, required this.readOnly});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTitle(
                icon: Icons.notes_outlined,
                title: 'Observações',
                theme: theme),
            const Divider(height: 18),
            TextFormField(
              controller: ctrl,
              readOnly: readOnly,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Observações adicionais da inspeção...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final ThemeData theme;

  const _CardTitle(
      {required this.icon, required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
