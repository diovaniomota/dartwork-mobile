import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/fiscal_api_service.dart';
import '../../../shared/widgets/client_picker.dart';
import '../../../shared/widgets/sale_picker.dart';

class NfeFormScreen extends ConsumerStatefulWidget {
  final String tipoModelo; // '55' = NFe, '65' = NFCe

  const NfeFormScreen({super.key, required this.tipoModelo});

  @override
  ConsumerState<NfeFormScreen> createState() => _NfeFormScreenState();
}

class _NfeFormScreenState extends ConsumerState<NfeFormScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Controllers básicos para a Nfe
  final _clienteNomeController = TextEditingController();
  final _clienteDocController = TextEditingController();

  // Uma Venda NFe tem vários itens. Na versão mobile simplificada
  // permitiremos vincular uma Venda existente ou adicionar um Valor livre.
  final _valorTotalController = TextEditingController();

  final _naturezaOperacaoController = TextEditingController(
    text: 'Venda de Mercadoria',
  );

  @override
  void dispose() {
    _clienteNomeController.dispose();
    _clienteDocController.dispose();
    _valorTotalController.dispose();
    _naturezaOperacaoController.dispose();
    super.dispose();
  }

  void _showClientPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ClientPicker(
        onSelected: (client) {
          setState(() {
            _clienteNomeController.text = client.name;
            _clienteDocController.text = client.document ?? '';
          });
        },
      ),
    );
  }

  void _showSalePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SalePicker(
        onSelected: (sale) {
          setState(() {
            _valorTotalController.text = sale.total.toStringAsFixed(2);
            _clienteNomeController.text = sale.clientName ?? '';
          });
        },
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(fiscalApiProvider);

      final payload = {
        'natureza_operacao': _naturezaOperacaoController.text,
        'valor_total': _valorTotalController.text,
        'destinatario': {
          'documento': _clienteDocController.text,
          'nome': _clienteNomeController.text,
        },
      };

      final String refId = DateTime.now().millisecondsSinceEpoch.toString();

      await api.emitirNfePayload(refId, payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nota Fiscal enviada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Emitir NF-e';

    return Scaffold(
      appBar: AppBar(title: const Text(title), leading: const BackButton()),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep += 1);
          } else {
            _submit();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        controlsBuilder: (context, details) {
          final isLast = _currentStep == 2;
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLast
                          ? Colors.green
                          : Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading && isLast
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isLast ? 'EMITIR NOTA' : 'PRÓXIMO',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('VOLTAR'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Dados'),
            content: Column(
              children: [
                TextFormField(
                  controller: _naturezaOperacaoController,
                  decoration: const InputDecoration(
                    labelText: 'Natureza da Operação',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Destinatário',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              onPressed: _showClientPicker,
                              icon: const Icon(Icons.search),
                              label: const Text('Selecionar'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _clienteDocController,
                          decoration: const InputDecoration(
                            labelText: 'CNPJ/CPF',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _clienteNomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome Completo / Razão',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Itens'),
            content: Column(
              children: [
                const SizedBox(
                  width: double.infinity,
                  child: Card(
                    color: Colors.blueAccent,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Dica: No Mobile, você pode emitir a nota com um valor genérico base se os produtos estiverem pré-cadastrados, ou importar de uma Venda.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _valorTotalController,
                  decoration: const InputDecoration(
                    labelText: 'Valor Total Bruto (R\$)',
                    border: OutlineInputBorder(),
                    prefixText: 'R\$ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _showSalePicker,
                  icon: const Icon(Icons.download),
                  label: const Text('Importar Cadastro de Venda'),
                ),
              ],
            ),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Resumo'),
            content: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Text(
                  'Tributação será calculada com base na configuração da empresa no Painel Web (Simples Nacional / Lucro Presumido).',
                ),
              ),
            ),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }
}
