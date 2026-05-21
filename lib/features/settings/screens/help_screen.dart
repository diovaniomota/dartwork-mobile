import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import 'human_support_screen.dart';
import 'legal_documents_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _supportPhoneDigits = '5548988583186';
  static const _supportEmail = 'contato@dartsistemas.com';
  static const _supportIntroMessage = 'Olá! Preciso de suporte no Work ERP.';

  void _openSupportChat(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HumanSupportScreen()));
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final encodedText = Uri.encodeComponent(_supportIntroMessage);
    await _launchWithFallback(
      context,
      openingMessage: 'Abrindo WhatsApp...',
      errorMessage: 'Não foi possível abrir o WhatsApp.',
      candidates: [
        Uri.parse(
          'whatsapp://send?phone=$_supportPhoneDigits&text=$encodedText',
        ),
        Uri.parse('https://wa.me/$_supportPhoneDigits?text=$encodedText'),
      ],
    );
  }

  Future<void> _openEmail(BuildContext context) async {
    final subject = Uri.encodeComponent('Suporte Work ERP');
    final body = Uri.encodeComponent(_supportIntroMessage);
    await _launchWithFallback(
      context,
      openingMessage: 'Abrindo cliente de E-mail...',
      errorMessage: 'Não foi possível abrir o E-mail.',
      candidates: [
        Uri.parse('mailto:$_supportEmail?subject=$subject&body=$body'),
        Uri.parse(
          'https://mail.google.com/mail/?view=cm&to=$_supportEmail&su=$subject&body=$body',
        ),
      ],
    );
  }

  Future<void> _openKnowledgeBase(BuildContext context) async {
    await _launchWithFallback(
      context,
      openingMessage: 'Abrindo base de conhecimento...',
      errorMessage: 'Não foi possível abrir a base de conhecimento.',
      candidates: [Uri.parse(AppConstants.webAppUrl)],
    );
  }

  Future<void> _openVideoTutorials(BuildContext context) async {
    await _launchWithFallback(
      context,
      openingMessage: 'Abrindo tutoriais em vídeo...',
      errorMessage: 'Não foi possível abrir os tutoriais.',
      candidates: [
        Uri.parse(
          'https://www.youtube.com/results?search_query=Work+ERP+DartSistemas',
        ),
      ],
    );
  }

  void _openTerms(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TermsOfUseScreen()));
  }

  void _openPrivacyPolicy(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
  }

  Future<void> _launchWithFallback(
    BuildContext context, {
    required String openingMessage,
    required String errorMessage,
    required List<Uri> candidates,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(openingMessage)));

    for (final uri in candidates) {
      try {
        final didLaunch = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (didLaunch) return;
      } catch (_) {
        // Tenta próximo fallback.
      }
    }

    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de Ajuda'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brandBlue, AppColors.brandGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.support_agent, size: 48, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Como podemos ajudar?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Encontre respostas rápidas ou fale com nosso time.',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Suporte Direto
            const Text(
              'Suporte Direto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.withAlpha(50)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.brandGreen,
                  child: Icon(Icons.support_agent, color: Colors.white),
                ),
                title: const Text('Suporte Humano'),
                subtitle: const Text('Atendimento direto por pessoa real'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _openSupportChat(context),
              ),
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.withAlpha(50)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.chat, color: Colors.white),
                ),
                title: const Text('WhatsApp'),
                subtitle: const Text('Atendimento comercial e técnico'),
                trailing: const Icon(Icons.open_in_new, size: 16),
                onTap: () => _openWhatsApp(context),
              ),
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.withAlpha(50)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.email, color: Colors.white),
                ),
                title: const Text('E-mail'),
                subtitle: const Text('contato@dartsistemas.com'),
                trailing: const Icon(Icons.open_in_new, size: 16),
                onTap: () => _openEmail(context),
              ),
            ),

            const SizedBox(height: 32),

            // Links Úteis
            const Text(
              'Links Úteis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildLinkTile(
              'Base de Conhecimento',
              Icons.menu_book,
              onTap: () => _openKnowledgeBase(context),
            ),
            const Divider(height: 1),
            _buildLinkTile(
              'Tutoriais em Vídeo',
              Icons.play_circle_outline,
              onTap: () => _openVideoTutorials(context),
            ),
            const Divider(height: 1),
            _buildLinkTile(
              'Termos de Uso',
              Icons.description,
              onTap: () => _openTerms(context),
            ),
            const Divider(height: 1),
            _buildLinkTile(
              'Política de Privacidade',
              Icons.privacy_tip,
              onTap: () => _openPrivacyPolicy(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTile(
    String title,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
