import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

class HumanSupportScreen extends StatefulWidget {
  const HumanSupportScreen({super.key});

  @override
  State<HumanSupportScreen> createState() => _HumanSupportScreenState();
}

class _HumanSupportScreenState extends State<HumanSupportScreen> {
  static const _supportPhoneDigits = '5548988583186';
  static const _supportEmail = 'contato@dartsistemas.com';
  final _messageCtrl = TextEditingController(
    text:
        'Olá! Preciso de atendimento humano no Work ERP. Pode me ajudar, por favor?',
  );

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    final encodedText = Uri.encodeComponent(_messageCtrl.text.trim());
    await _launchWithFallback(
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

  Future<void> _openEmail() async {
    final subject = Uri.encodeComponent('Suporte Humano - Work ERP');
    final body = Uri.encodeComponent(_messageCtrl.text.trim());
    await _launchWithFallback(
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

  Future<void> _launchWithFallback({
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
        // tenta o próximo fallback
      }
    }

    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suporte Humano'),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brandBlue, AppColors.brandGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Atendimento com pessoa real',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Descreva seu problema e envie para o time de suporte pelo canal que preferir.',
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageCtrl,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Mensagem para o suporte',
              alignLabelWithHint: true,
              hintText: 'Descreva o problema com detalhes...',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _openWhatsApp,
            icon: const Icon(Icons.chat),
            label: const Text('Enviar para WhatsApp'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _openEmail,
            icon: const Icon(Icons.email_outlined),
            label: const Text('Enviar por E-mail'),
          ),
        ],
      ),
    );
  }
}
