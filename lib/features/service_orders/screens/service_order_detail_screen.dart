import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/service_order.dart';
import '../../../data/repositories/service_order_repository.dart';
import '../../../providers/permission_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../widgets/os_checklist_tab.dart';
import '../widgets/os_details_tab.dart';
import '../widgets/os_items_tab.dart';
import '../widgets/os_payment_tab.dart';

class ServiceOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  final int initialTab;

  const ServiceOrderDetailScreen({
    super.key,
    required this.orderId,
    this.initialTab = 0,
  });

  @override
  ConsumerState<ServiceOrderDetailScreen> createState() =>
      _ServiceOrderDetailScreenState();
}

class _ServiceOrderDetailScreenState
    extends ConsumerState<ServiceOrderDetailScreen>
    with SingleTickerProviderStateMixin {
  final _repo = ServiceOrderRepository();
  final _dateFmt = DateFormat('dd/MM/yyyy');

  ServiceOrder? _order;
  bool _loading = true;
  String? _error;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
        length: 5, vsync: this, initialIndex: widget.initialTab);
    _loadOrder();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await _repo.getById(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  /// Roteia a ação escolhida no menu suspenso.
  Future<void> _onMenuAction(String action) async {
    switch (action) {
      case 'estornar':
        await _estornarOS();
      case 'reabrir':
        await _reabrirOS();
      default:
        await _changeStatus(action);
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    final order = _order;
    if (order == null) return;

    String label;
    switch (newStatus) {
      case 'em_andamento':
        label = 'Em Andamento';
      case 'cancelada':
        label = 'Cancelada';
      default:
        label = newStatus;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alterar status'),
        content: Text('Mudar status para "$label"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await _repo.updateStatus(order.id, order.organizationId, newStatus);
      _loadOrder();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Estorna OS finalizada/faturada (reverte estoque, financeiro e caixa).
  Future<void> _estornarOS() async {
    final order = _order;
    if (order == null) return;

    final reason = await _askReason(
      title: 'Estornar OS',
      message:
          'O estorno reverte estoque, financeiro e caixa desta OS. Informe o motivo:',
      confirmLabel: 'Estornar',
      confirmColor: Colors.deepOrange,
    );
    if (reason == null || !mounted) return;

    setState(() => _loading = true);
    try {
      await _repo.estornar(order.id, order.organizationId, reason);
      await _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('OS estornada com sucesso.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao estornar: ${_clean(e)}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Reabre OS estornada (volta para em andamento).
  Future<void> _reabrirOS() async {
    final order = _order;
    if (order == null) return;

    final reason = await _askReason(
      title: 'Reabrir OS',
      message: 'A OS voltará para "Em Andamento". Informe o motivo (opcional):',
      confirmLabel: 'Reabrir',
      confirmColor: Colors.blue,
      required: false,
    );
    if (reason == null || !mounted) return;

    setState(() => _loading = true);
    try {
      await _repo.reabrir(order.id, order.organizationId, reason: reason);
      await _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('OS reaberta com sucesso.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao reabrir: ${_clean(e)}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Diálogo para capturar um motivo. Retorna null se cancelado.
  Future<String?> _askReason({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    bool required = true,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String? error;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 3,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Motivo',
                    border: const OutlineInputBorder(),
                    errorText: error,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: confirmColor),
                onPressed: () {
                  final text = controller.text.trim();
                  if (required && text.isEmpty) {
                    setLocal(() => error = 'Informe o motivo');
                    return;
                  }
                  Navigator.pop(ctx, text);
                },
                child: Text(confirmLabel),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    return result;
  }

  String _clean(Object e) =>
      e.toString().replaceFirst('Exception: ', '').trim();

  List<PopupMenuEntry<String>> _buildMenuItems(ServiceOrder order) {
    final status = order.status.toLowerCase();
    final items = <PopupMenuEntry<String>>[];

    if (status == 'aberta') {
      items.add(const PopupMenuItem(
          value: 'em_andamento',
          child: ListTile(
              leading: Icon(Icons.play_arrow_rounded, color: Colors.blue),
              title: Text('Iniciar atendimento'),
              contentPadding: EdgeInsets.zero)));
    }

    // Estornar: somente OS finalizada/faturada/encerrada.
    if (['finalizada', 'faturada', 'encerrada'].contains(status)) {
      items.add(const PopupMenuItem(
          value: 'estornar',
          child: ListTile(
              leading: Icon(Icons.undo_rounded, color: Colors.deepOrange),
              title: Text('Estornar OS'),
              contentPadding: EdgeInsets.zero)));
    }

    // Reabrir: somente OS estornada.
    if (status == 'estornada') {
      items.add(const PopupMenuItem(
          value: 'reabrir',
          child: ListTile(
              leading: Icon(Icons.refresh_rounded, color: Colors.blue),
              title: Text('Reabrir OS'),
              contentPadding: EdgeInsets.zero)));
    }

    if (!['finalizada', 'faturada', 'estornada', 'cancelada', 'encerrada']
        .contains(status)) {
      items.add(const PopupMenuItem(
          value: 'cancelada',
          child: ListTile(
              leading: Icon(Icons.cancel_outlined, color: Colors.red),
              title: Text('Cancelar OS'),
              contentPadding: EdgeInsets.zero)));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final permissions = ref.watch(permissionProvider);

    if (_loading) return const Scaffold(body: LoadingIndicator());

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ordem de Serviço')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: _loadOrder, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
    }

    final order = _order;
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ordem de Serviço')),
        body: const Center(child: Text('OS não encontrada')),
      );
    }

    final status = order.status.toLowerCase();
    final canEdit = permissions.canEdit('ordens_servico') &&
        !['finalizada', 'faturada', 'estornada'].contains(status);
    final menuItems = _buildMenuItems(order);

    return Scaffold(
      appBar: AppBar(
        title: Text('OS #${order.id.substring(0, 8).toUpperCase()}'),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () => context
                  .push('/ordens-servico/${order.id}/editar')
                  .then((_) => _loadOrder()),
            ),
          if (menuItems.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: _onMenuAction,
              itemBuilder: (_) => menuItems,
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Detalhes'),
            Tab(icon: Icon(Icons.build_outlined), text: 'Itens'),
            Tab(icon: Icon(Icons.checklist_rounded), text: 'Checklist'),
            Tab(icon: Icon(Icons.payment_outlined), text: 'Pagamento'),
            Tab(icon: Icon(Icons.photo_library_outlined), text: 'Fotos'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header card — info da OS
          _buildHeader(theme, order),
          // Tabs
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                OsDetailsTab(order: order),
                OsItemsTab(order: order, onChanged: _loadOrder),
                OsChecklistTab(order: order, onChanged: _loadOrder),
                OsPaymentTab(order: order, onChanged: _loadOrder),
                _PhotosTab(order: order, repo: _repo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ServiceOrder order) {
    final statusColor = _statusColor(order.status);
    final dateFmt = _dateFmt;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha:0.06),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.clientName != null)
                      Text(order.clientName!,
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    if (order.veiculoPlaca != null)
                      Text(
                        [order.veiculoPlaca, order.veiculoModelo]
                            .where((s) => s != null && s.isNotEmpty)
                            .join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(order.statusLabel,
                    style: TextStyle(
                        color: statusColor, fontWeight: FontWeight.w600)),
                backgroundColor: statusColor.withValues(alpha:0.12),
                side: BorderSide(color: statusColor.withValues(alpha:0.3)),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ],
          ),
          if (order.descricaoProblema != null) ...[
            const SizedBox(height: 4),
            Text(
              order.descricaoProblema!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha:0.7)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              if (order.createdAt != null)
                _infoChip(Icons.calendar_today_outlined,
                    dateFmt.format(order.createdAt!), theme),
              if (order.dataPrevisao != null) ...[
                const SizedBox(width: 8),
                _infoChip(Icons.schedule_outlined,
                    dateFmt.format(order.dataPrevisao!), theme),
              ],
              if (order.tecnicoResponsavel != null) ...[
                const SizedBox(width: 8),
                _infoChip(Icons.person_outline,
                    order.tecnicoResponsavel!, theme),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, ThemeData theme) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13,
              color: theme.colorScheme.onSurface.withValues(alpha:0.5)),
          const SizedBox(width: 3),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha:0.6))),
        ],
      );

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aberta':
        return Colors.blue;
      case 'em_andamento':
        return Colors.orange;
      case 'finalizada':
        return Colors.green;
      case 'faturada':
        return Colors.purple;
      case 'cancelada':
        return Colors.red;
      case 'estornada':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

// ---------------------------------------------------------------------------
// Aba de fotos (inline pois é simples)
// ---------------------------------------------------------------------------
class _PhotosTab extends ConsumerStatefulWidget {
  final ServiceOrder order;
  final ServiceOrderRepository repo;

  const _PhotosTab({required this.order, required this.repo});

  @override
  ConsumerState<_PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends ConsumerState<_PhotosTab> {
  List<dynamic> _photos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await widget.repo.getPhotos(
          organizationId: widget.order.organizationId,
          orderId: widget.order.id);
      if (mounted) {
        setState(() {
          _photos = p;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.3)),
            const SizedBox(height: 8),
            Text('Nenhuma foto',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha:0.5))),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => context
                  .push('/ordens-servico/${widget.order.id}/editar')
                  .then((_) => _load()),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Adicionar fotos'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, mainAxisSpacing: 4, crossAxisSpacing: 4),
      itemCount: _photos.length,
      itemBuilder: (_, i) {
        final photo = _photos[i];
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: photo.signedUrl != null
              ? Image.network(photo.signedUrl!, fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => const ColoredBox(
                        color: Color(0xFFEEEEEE),
                        child:
                            Center(child: Icon(Icons.broken_image_outlined)),
                      ))
              : const ColoredBox(
                  color: Color(0xFFEEEEEE),
                  child: Center(child: Icon(Icons.image_outlined)),
                ),
        );
      },
    );
  }
}
