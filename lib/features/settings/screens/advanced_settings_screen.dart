import 'package:flutter/material.dart';

class AdvancedSettingsScreen extends StatelessWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações Avançadas'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.settings_suggest, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Parâmetros do Sistema',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configurações de bloqueio de estoque, limite de caixa, crediário e regras padrão do PDV.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.orange.withValues(alpha: 0.1)
                    : Colors.orange.shade50,
                border: Border.all(
                  color: isDark
                      ? Colors.orange.withValues(alpha: 0.3)
                      : Colors.orange.shade200,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Como funciona?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'As Configurações Avançadas contêm regras críticas do negócio (ex: não permitir venda sem estoque, fechar caixa diário, etc).\\n\\nPara garantir que toda a equipe (vendedores e mecânicos) siga as mesmas regras, essas restrições globais só podem ser modificadas pelo Gestor/Administrador acessando o painel Web da aplicação pelo navegador do seu computador.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
