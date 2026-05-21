import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/ai_chat_service.dart';
import '../../../providers/organization_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _chatService = AiChatService();
  final List<_AiMessage> _messages = [
    const _AiMessage(
      role: _AiRole.assistant,
      text:
          'Olá! Sou o Assistente IA do Work ERP.\n\nPosso te ajudar com fluxo de notas fiscais, PDV, financeiro, produtos, clientes e configurações.',
    ),
  ];
  bool _sending = false;

  static const List<String> _quickPrompts = [
    'Como emitir NF-e?',
    'Minha nota foi rejeitada',
    'Como abrir e fechar caixa?',
    'Como cadastrar produto com NCM?',
    'Como lançar contas a pagar?',
    'Como usar crediário no PDV?',
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  String _buildCompanyContext() {
    final organization = ref.read(currentOrganizationProvider).value;
    if (organization == null) return '';

    final enabledFeatures = organization.enabledFeatures.join(', ');
    return '''
Contexto da organização atual:
- Razão social: ${organization.razaoSocial ?? organization.name}
- CNPJ: ${organization.cnpj ?? 'N/A'}
- Plano: ${organization.planName ?? organization.planCode ?? 'N/A'}
- Módulos habilitados: ${enabledFeatures.isNotEmpty ? enabledFeatures : 'não informado'}
''';
  }

  String _stripActionTokens(String raw) {
    return raw
        .replaceAll(RegExp(r'\[NAVIGATE:.*?\]'), '')
        .replaceAll(RegExp(r'\[\s*ACTION\s*:.*?\]'), '')
        .trim();
  }

  String? _extractNavigatePath(String raw) {
    final match = RegExp(r'\[NAVIGATE:(.*?)\]').firstMatch(raw);
    final path = match?.group(1)?.trim() ?? '';
    if (path.isEmpty || !path.startsWith('/')) return null;
    return path;
  }

  Future<void> _send([String? customText]) async {
    if (_sending) return;
    if (!mounted) return;

    final text = (customText ?? _inputCtrl.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_AiMessage(role: _AiRole.user, text: text));
      _sending = true;
    });
    _inputCtrl.clear();
    _scrollToBottom();

    try {
      final payloadMessages = _messages
          .where((msg) => msg.text.trim().isNotEmpty)
          .map(
            (msg) => <String, String>{
              'role': msg.role == _AiRole.user ? 'user' : 'assistant',
              'content': msg.text,
            },
          )
          .toList();

      final rawReply = await _chatService.sendMessage(
        messages: payloadMessages,
        currentRoute: '/assistente',
        companyContext: _buildCompanyContext(),
      );

      final navigateTo = _extractNavigatePath(rawReply);
      final cleanReply = _stripActionTokens(rawReply);

      if (!mounted) return;
      setState(() {
        _messages.add(
          _AiMessage(
            role: _AiRole.assistant,
            text: cleanReply.isNotEmpty
                ? cleanReply
                : 'Posso te guiar para uma tela do sistema. Toque em "Ir para tela".',
            navigateTo: navigateTo,
          ),
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _AiMessage(
            role: _AiRole.assistant,
            text: 'Erro ao consultar IA: $error',
            isError: true,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quickChipLabelColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final quickChipBgColor = isDark
        ? AppColors.darkCard.withAlpha(185)
        : Colors.white;
    final quickChipBorderColor = isDark
        ? AppColors.darkBorder.withAlpha(170)
        : AppColors.lightBorder;

    return AppScaffold(
      title: 'Assistente IA',
      subtitle: 'Mesmo assistente inteligente do painel web',
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Theme.of(context).cardColor,
              border: Border.all(
                color: Theme.of(context).dividerColor.withAlpha(90),
              ),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickPrompts
                  .map(
                    (prompt) => ActionChip(
                      label: Text(
                        prompt,
                        style: TextStyle(
                          color: quickChipLabelColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      backgroundColor: quickChipBgColor,
                      side: BorderSide(color: quickChipBorderColor, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                      pressElevation: 0.5,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      onPressed: () => _send(prompt),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              itemCount: _messages.length + (_sending ? 1 : 0),
              itemBuilder: (context, index) {
                if (_sending && index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(label: Text('Pensando...')),
                    ),
                  );
                }

                final msg = _messages[index];
                final user = msg.role == _AiRole.user;
                final bubbleColor = user
                    ? Theme.of(context).colorScheme.primary
                    : (msg.isError
                          ? Colors.red.withAlpha(28)
                          : Theme.of(context).cardColor);
                final textColor = user
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color;

                return Align(
                  alignment: user
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.86,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(12),
                      border: user
                          ? null
                          : Border.all(
                              color: Theme.of(
                                context,
                              ).dividerColor.withAlpha(70),
                            ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          msg.text,
                          style: TextStyle(color: textColor, height: 1.35),
                        ),
                        if (!user &&
                            msg.navigateTo != null &&
                            msg.navigateTo!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          FilledButton.tonalIcon(
                            onPressed: () => context.go(msg.navigateTo!),
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: Text('Ir para ${msg.navigateTo}'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Pergunte algo sobre o Work ERP...',
                        prefixIcon: Icon(Icons.smart_toy_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _sending ? null : _send,
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _AiRole { user, assistant }

class _AiMessage {
  final _AiRole role;
  final String text;
  final String? navigateTo;
  final bool isError;

  const _AiMessage({
    required this.role,
    required this.text,
    this.navigateTo,
    this.isError = false,
  });
}
