import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/organization_provider.dart';

class FiscalSettingsScreen extends ConsumerStatefulWidget {
  const FiscalSettingsScreen({super.key});

  @override
  ConsumerState<FiscalSettingsScreen> createState() =>
      _FiscalSettingsScreenState();
}

class _FiscalSettingsScreenState extends ConsumerState<FiscalSettingsScreen> {
  final _naturezaCtrl = TextEditingController();
  final _serieCtrl = TextEditingController();

  bool _isLoading = false;
  String _environment = 'homologacao'; // homologacao ou producao

  @override
  void initState() {
    super.initState();
    final org = ref.read(currentOrganizationProvider).value;
    if (org != null) {
      _naturezaCtrl.text = org.raw['fiscal_natureza_padrao']?.toString() ?? '';
      _serieCtrl.text = org.raw['fiscal_serie_padrao']?.toString() ?? '1';
      _environment = org.raw['fiscal_environment']?.toString() ?? 'homologacao';
    }
  }

  @override
  void dispose() {
    _naturezaCtrl.dispose();
    _serieCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId == null) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(organizationRepositoryProvider);
      await repo.update(orgId, {
        'fiscal_environment': _environment,
        'fiscal_natureza_padrao': _naturezaCtrl.text.trim(),
        'fiscal_serie_padrao': _serieCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configurações fiscais atualizadas!')),
        );
        ref.invalidate(currentOrganizationProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: \$e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas Fiscais'),
        leading: const BackButton(),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ambiente de Emissão',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'homologacao',
                  label: Text('Homologação (Testes)'),
                  icon: Icon(Icons.science),
                ),
                ButtonSegment(
                  value: 'producao',
                  label: Text('Produção (Valendo)'),
                  icon: Icon(Icons.domain_verification),
                ),
              ],
              selected: {_environment},
              onSelectionChanged: (newSelection) {
                setState(() => _environment = newSelection.first);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return _environment == 'producao'
                        ? Colors.green.withAlpha(50)
                        : Colors.orange.withAlpha(50);
                  }
                  return Colors.transparent;
                }),
              ),
            ),

            const Divider(height: 32),

            const Text(
              'CFOPs Padrão e Tributação',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _naturezaCtrl,
              decoration: const InputDecoration(
                labelText: 'Natureza de Operação (Venda Padrão)',
                hintText: 'Ex: Venda de Mercadoria',
                prefixIcon: Icon(Icons.text_snippet),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _serieCtrl,
              decoration: const InputDecoration(
                labelText: 'Série NF-e Padrão',
                hintText: 'Ex: 1',
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
