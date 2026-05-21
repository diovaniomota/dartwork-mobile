import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AccountantScreen extends StatelessWidget {
  const AccountantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acesso do Contador'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.account_balance_outlined,
              size: 64,
              color: AppColors.brandBlue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Acesso Habilitado',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gerencie o acesso do seu escritório de contabilidade ao portal de XMLs.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.blue.shade50,
                border: Border.all(
                  color: isDark
                      ? Colors.blue.withValues(alpha: 0.3)
                      : Colors.blue.shade200,
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
                      color: AppColors.brandBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildHelpItem(
                    Icons.security,
                    'Acesso Limitado',
                    'O contador não tem acesso ao seu financeiro, apenas aos XMLs fiscais.',
                  ),
                  _buildHelpItem(
                    Icons.download_rounded,
                    'Download em Lote',
                    'Eles poderão baixar todas as NF-es e NFC-es do mês em um clique.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Para convidar ou remover contadores, acesse o painel Web da aplicação pelo navegador do seu computador.',
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.brandBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
