import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/fiscal_api_service.dart';
import '../../../shared/widgets/client_picker.dart';

class NfseFormScreen extends ConsumerStatefulWidget {
  const NfseFormScreen({super.key});

  @override
  ConsumerState<NfseFormScreen> createState() => _NfseFormScreenState();
}

class _NfseFormScreenState extends ConsumerState<NfseFormScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Controladores básicos (Draft Inicial)
  final _tomadorCnpjController = TextEditingController();
  final _tomadorNomeController = TextEditingController();

  final _servicoDescricaoController = TextEditingController();
  final _servicoValorController = TextEditingController();

  final _issController = TextEditingController();

  @override
  void dispose() {
    _tomadorCnpjController.dispose();
    _tomadorNomeController.dispose();
    _servicoDescricaoController.dispose();
    _servicoValorController.dispose();
    _issController.dispose();
    super.dispose();
  }

  void _showClientPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClientPicker(
        onSelected: (client) {
          setState(() {
            _tomadorNomeController.text = client.name;
            _tomadorCnpjController.text = client.document ?? '';
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
        'servico': {
          'descricao': _servicoDescricaoController.text,
          'valor': _servicoValorController.text,
          'iss': _issController.text,
        },
        'tomador': {
          'documento': _tomadorCnpjController.text,
          'nome': _tomadorNomeController.text,
        },
      };

      final String refId = 'NFSE_${DateTime.now().millisecondsSinceEpoch}';
      await api.emitirNfse(refId, payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NFS-e emitida com sucesso!'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Nova NFS-e')),
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
                            isLast ? 'EMITIR NFS-e' : 'PRÓXIMO',
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
            title: const Text('Tomador'),
            content: Column(
              children: [
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
                              'Dados do Tomador',
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
                          controller: _tomadorCnpjController,
                          decoration: const InputDecoration(
                            labelText: 'CPF/CNPJ do Tomador',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _tomadorNomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome / Razão Social',
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
            title: const Text('Serviço'),
            content: Column(
              children: [
                TextFormField(
                  controller: _servicoDescricaoController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Discriminação do Serviço',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _servicoValorController,
                  decoration: const InputDecoration(
                    labelText: 'Valor do Serviço (R\$)',
                    border: OutlineInputBorder(),
                    prefixText: 'R\$ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Impostos'),
            content: Column(
              children: [
                TextFormField(
                  controller: _issController,
                  decoration: const InputDecoration(
                    labelText: 'Aliquota ISS (%)',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Card(
                  color: Colors.amberAccent,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Aviso: Certifique-se de que os dados informados estão de acordo com o portal da prefeitura.',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }
}
