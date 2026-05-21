import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ChecklistSettingsScreen extends StatelessWidget {
  const ChecklistSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist O.S'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.checklist_rtl_rounded,
              size: 64,
              color: AppColors.brandGreen,
            ),
            const SizedBox(height: 16),
            const Text(
              'Configuração de Checklist',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Defina os itens padrões que serão verificados nas Ordens de Serviço (ex: Suspensão, Freios, Bateria).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.green.shade50,
                border: Border.all(
                  color: isDark
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.green.shade200,
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
                      color: AppColors.brandGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Para adicionar ou remover itens permanentes do formulário de checklist da sua oficina, acesse o painel Web da aplicação pelo navegador do seu computador.',
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
