import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/service_order.dart';

/// Aba de visão geral da OS — espelha a aba "Detalhes" do desktop.
class OsDetailsTab extends StatelessWidget {
  final ServiceOrder order;

  const OsDetailsTab({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Cliente / veículo
        _Section(
          title: 'Cliente e veículo',
          icon: Icons.person_outline,
          children: [
            _row('Cliente', order.clientName ?? 'Sem cliente', theme),
            if (order.veiculoPlaca != null)
              _row('Placa', order.veiculoPlaca!, theme),
            if (order.veiculoModelo != null)
              _row('Veículo', order.veiculoModelo!, theme),
            if (order.tecnicoResponsavel != null)
              _row('Técnico', order.tecnicoResponsavel!, theme),
          ],
        ),

        // Problema / diagnóstico
        if (_hasAny([order.descricaoProblema, order.diagnostico, order.observacoes]))
          _Section(
            title: 'Atendimento',
            icon: Icons.build_outlined,
            children: [
              if (_notEmpty(order.descricaoProblema))
                _block('Problema relatado', order.descricaoProblema!, theme),
              if (_notEmpty(order.diagnostico))
                _block('Diagnóstico', order.diagnostico!, theme),
              if (_notEmpty(order.observacoes))
                _block('Observações', order.observacoes!, theme),
            ],
          ),

        // Veículo - medições
        if (order.kmEntrada != null ||
            order.kmSaida != null ||
            _notEmpty(order.tanqueNivel))
          _Section(
            title: 'Medições',
            icon: Icons.speed_outlined,
            children: [
              if (order.kmEntrada != null)
                _row('KM entrada', '${order.kmEntrada} km', theme),
              if (order.kmSaida != null)
                _row('KM saída', '${order.kmSaida} km', theme),
              if (_notEmpty(order.tanqueNivel))
                _row('Nível do tanque', order.tanqueNivel!, theme),
            ],
          ),

        // Datas
        _Section(
          title: 'Datas',
          icon: Icons.event_outlined,
          children: [
            if (order.dataAbertura != null)
              _row('Abertura', dateFmt.format(order.dataAbertura!), theme),
            if (order.dataPrevisao != null)
              _row('Previsão', dateFmt.format(order.dataPrevisao!), theme),
            if (order.dataFechamento != null)
              _row('Fechamento', dateFmt.format(order.dataFechamento!), theme),
            if (order.createdAt != null)
              _row('Criada em', dateFmt.format(order.createdAt!), theme),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  bool _notEmpty(String? v) => v != null && v.trim().isNotEmpty;
  bool _hasAny(List<String?> values) => values.any(_notEmpty);

  Widget _row(String label, String value, ThemeData theme) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ),
            Expanded(
              child: Text(value,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _block(String label, String value, ThemeData theme) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 2),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        ),
      );
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }
}
