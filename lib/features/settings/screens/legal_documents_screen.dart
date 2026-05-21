import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  static const _sections = <LegalSectionData>[
    LegalSectionData(
      title: '1. Aceitação dos Termos',
      paragraphs: [
        'Ao criar uma conta e utilizar a plataforma Work ERP ("Plataforma"), operada por DartSoft Sistemas LTDA ("DartSoft", "nós"), você ("Usuário", "Cliente") concorda integralmente com estes Termos de Uso. Caso não concorde, não utilize a Plataforma.',
      ],
    ),
    LegalSectionData(
      title: '2. Descrição do Serviço',
      paragraphs: [
        'A DartSoft oferece uma plataforma de gestão empresarial (ERP) voltada para micro e pequenas empresas.',
      ],
      bullets: [
        'Gestão comercial e ponto de venda (PDV).',
        'Controle financeiro e movimentações de caixa.',
        'Cadastro de clientes, produtos e estoque.',
        'Emissão fiscal (NF-e, NFC-e).',
        'Ordens de serviço.',
        'Contas a pagar e a receber.',
      ],
    ),
    LegalSectionData(
      title: '3. Período de Teste',
      paragraphs: [
        'Ao se cadastrar, o Usuário recebe um período gratuito de 7 (sete) dias corridos para testar as funcionalidades do plano selecionado. Ao término do período de teste, o acesso poderá ser suspenso até a configuração de uma assinatura.',
      ],
    ),
    LegalSectionData(
      title: '4. Planos e Pagamento',
      bullets: [
        'Os planos e valores são apresentados na plataforma.',
        'A cobrança é mensal e recorrente, conforme o plano contratado.',
        'A DartSoft pode alterar preços com aviso prévio.',
        'O não pagamento pode resultar em suspensão temporária do acesso.',
      ],
    ),
    LegalSectionData(
      title: '5. Cancelamento',
      paragraphs: [
        'O Usuário pode cancelar a assinatura no painel. O acesso permanece ativo até o fim do período já pago.',
        'Após o cancelamento, os dados podem ser mantidos por até 90 (noventa) dias antes da exclusão definitiva, observadas obrigações legais.',
      ],
    ),
    LegalSectionData(
      title: '6. Responsabilidades do Usuário',
      bullets: [
        'Manter a confidencialidade das credenciais de acesso.',
        'Fornecer dados verdadeiros e atualizados.',
        'Utilizar a plataforma em conformidade com a legislação vigente.',
        'Não usar o serviço para atividades ilícitas, fraudulentas ou que violem direitos de terceiros.',
        'Assumir responsabilidade pelos dados inseridos no sistema.',
      ],
    ),
    LegalSectionData(
      title: '7. Propriedade Intelectual',
      paragraphs: [
        'Software, design, logotipos, textos e demais conteúdos da plataforma são de propriedade da DartSoft Sistemas LTDA. É proibida a reprodução, distribuição ou engenharia reversa sem autorização prévia por escrito.',
      ],
    ),
    LegalSectionData(
      title: '8. Disponibilidade do Serviço',
      paragraphs: [
        'A DartSoft emprega melhores esforços para manter o serviço disponível, porém não garante disponibilidade ininterrupta. Podem ocorrer manutenções programadas e indisponibilidades temporárias.',
      ],
    ),
    LegalSectionData(
      title: '9. Limitação de Responsabilidade',
      paragraphs: [
        'A DartSoft não se responsabiliza por danos indiretos, incidentais ou consequenciais decorrentes do uso da plataforma, incluindo perda de dados, lucros cessantes ou interrupção de negócios, nos limites legais aplicáveis.',
      ],
    ),
    LegalSectionData(
      title: '10. Alterações nos Termos',
      paragraphs: [
        'Os Termos podem ser atualizados periodicamente. Alterações relevantes serão comunicadas pelos canais oficiais da plataforma.',
      ],
    ),
    LegalSectionData(
      title: '11. Foro e Legislação',
      paragraphs: [
        'Estes Termos são regidos pelas leis da República Federativa do Brasil. Em caso de controvérsia, aplica-se o foro competente conforme legislação vigente.',
      ],
    ),
    LegalSectionData(
      title: '12. Contato',
      paragraphs: [
        'Em caso de dúvidas sobre estes Termos, entre em contato: contato@dartsistemas.com',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Termos de Uso',
      subtitle: 'Condições para uso da plataforma Work ERP.',
      lastUpdated: '17 de fevereiro de 2026',
      sections: _sections,
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = <LegalSectionData>[
    LegalSectionData(
      title: '1. Introdução',
      paragraphs: [
        'A DartSoft Sistemas LTDA se compromete com a proteção dos dados pessoais dos usuários da plataforma Work ERP, em conformidade com a LGPD (Lei nº 13.709/2018).',
      ],
    ),
    LegalSectionData(
      title: '2. Dados Coletados',
      bullets: [
        'Dados de cadastro: nome, e-mail, telefone e informações de autenticação.',
        'Dados da empresa: razão social, nome fantasia, CNPJ, inscrições e endereço.',
        'Dados de uso: informações inseridas no sistema (clientes, produtos, vendas, movimentações e ordens de serviço).',
        'Dados técnicos: IP, dispositivo, páginas acessadas e horários de acesso para segurança e melhoria contínua.',
      ],
    ),
    LegalSectionData(
      title: '3. Finalidade do Tratamento',
      bullets: [
        'Criar e manter a conta do Usuário.',
        'Prestar os serviços contratados.',
        'Enviar comunicações operacionais e de suporte.',
        'Processar faturamento e pagamentos.',
        'Cumprir obrigações legais e regulatórias.',
        'Melhorar continuamente a plataforma.',
      ],
    ),
    LegalSectionData(
      title: '4. Compartilhamento de Dados',
      paragraphs: [
        'Os dados podem ser compartilhados com provedores de infraestrutura, processadores de pagamento e autoridades quando exigido por lei.',
        'A DartSoft não vende, aluga ou comercializa dados pessoais de usuários.',
      ],
    ),
    LegalSectionData(
      title: '5. Armazenamento e Segurança',
      bullets: [
        'Uso de conexões seguras (HTTPS/TLS) e controles de acesso.',
        'Aplicação de boas práticas de monitoramento e backup.',
        'Apesar dos esforços, nenhum sistema é 100% imune a incidentes.',
      ],
    ),
    LegalSectionData(
      title: '6. Retenção de Dados',
      bullets: [
        'Dados mantidos enquanto a conta estiver ativa.',
        'Após cancelamento, retenção por período necessário para reativação e obrigações legais.',
        'Dados fiscais e contábeis podem ter retenção ampliada por exigência normativa.',
      ],
    ),
    LegalSectionData(
      title: '7. Direitos do Titular (LGPD)',
      bullets: [
        'Confirmar a existência de tratamento.',
        'Acessar, corrigir ou atualizar dados pessoais.',
        'Solicitar anonimização, bloqueio ou eliminação, quando aplicável.',
        'Revogar consentimento e solicitar portabilidade, quando aplicável.',
        'Obter informações sobre compartilhamento de dados.',
      ],
      paragraphs: [
        'Para exercer seus direitos, entre em contato: contato@dartsistemas.com',
      ],
    ),
    LegalSectionData(
      title: '8. Cookies e Tecnologias Similares',
      paragraphs: [
        'A plataforma utiliza cookies e armazenamento local para autenticação, preferências e funcionamento do sistema. Não há uso de rastreamento publicitário próprio para venda de dados.',
      ],
    ),
    LegalSectionData(
      title: '9. Alterações desta Política',
      paragraphs: [
        'Esta Política pode ser atualizada periodicamente. Recomenda-se revisão frequente para ciência das mudanças.',
      ],
    ),
    LegalSectionData(
      title: '10. Contato',
      paragraphs: [
        'Para assuntos de privacidade e proteção de dados: contato@dartsistemas.com',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Política de Privacidade',
      subtitle: 'Como tratamos dados pessoais no Work ERP.',
      lastUpdated: '17 de fevereiro de 2026',
      sections: _sections,
    );
  }
}

class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String lastUpdated;
  final List<LegalSectionData> sections;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.lastUpdated,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(title: Text(title), leading: const BackButton()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Theme.of(context).cardColor,
              border: Border.all(
                color: Theme.of(context).dividerColor.withAlpha(90),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(color: subtitleColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Última atualização: $lastUpdated',
                  style: textTheme.bodySmall?.copyWith(
                    color: subtitleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...sections.map((section) => _LegalSectionCard(section: section)),
        ],
      ),
    );
  }
}

class _LegalSectionCard extends StatelessWidget {
  final LegalSectionData section;

  const _LegalSectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bodyStyle = textTheme.bodyMedium;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...section.paragraphs.map(
              (paragraph) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(paragraph, style: bodyStyle?.copyWith(height: 1.4)),
              ),
            ),
            ...section.bullets.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text('• '),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: bodyStyle?.copyWith(height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegalSectionData {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const LegalSectionData({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });
}
