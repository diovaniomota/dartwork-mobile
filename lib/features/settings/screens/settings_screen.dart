import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/organization_provider.dart';
import '../../../providers/billing_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

/// Tela de configurações (perfil, tema, logout) — visual premium.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;
    final org = ref.watch(currentOrganizationProvider).value;
    final billing = ref.watch(billingProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: ListView(
        children: [
          // Header com gradiente azul→verde
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: const BoxDecoration(gradient: AppColors.brandGradient),
            child: Column(
              children: [
                // Avatar com iniciais
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withAlpha(50),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(user?.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.name ?? 'Usuário',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user?.role.toUpperCase() ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Minha Conta
          _buildSettingsTile(
            context: context,
            icon: Icons.person_rounded,
            color: AppColors.primary,
            title: 'Minha Conta',
            subtitle: 'Dados pessoais e segurança',
            onTap: () => context.push('/configuracoes/perfil'),
          ),
          _buildDivider(isDark),

          // Notas Fiscais
          _buildSettingsTile(
            context: context,
            icon: Icons.receipt_long_rounded,
            color: AppColors.brandGreen,
            title: 'Notas Fiscais',
            subtitle: 'Natureza e Tributação',
            onTap: () => context.push('/configuracoes/fiscal'),
          ),
          _buildDivider(isDark),

          // Naturezas Fiscais
          _buildSettingsTile(
            context: context,
            icon: Icons.rule_rounded,
            color: AppColors.info,
            title: 'Naturezas Fiscais',
            subtitle: 'Gerenciar naturezas de operação',
            onTap: () => context.push('/fiscal/naturezas'),
          ),
          _buildDivider(isDark),

          // Certificado Digital A1
          _buildSettingsTile(
            context: context,
            icon: Icons.security_rounded,
            color: AppColors.danger,
            title: 'Certificado Digital',
            subtitle: 'Enviar Certificado A1 (PFX/P12)',
            onTap: () => context.push('/configuracoes/certificado'),
          ),
          _buildDivider(isDark),

          if (org != null) ...[
            _buildSettingsTile(
              context: context,
              icon: Icons.business_rounded,
              color: AppColors.brandBlue,
              title: 'Empresa',
              subtitle: org.name,
              onTap: () => context.push('/configuracoes/empresa'),
            ),
            _buildDivider(isDark),

            // Equipe / Usuários
            _buildSettingsTile(
              context: context,
              icon: Icons.people_alt_rounded,
              color: AppColors.primary,
              title: 'Equipe e Usuários',
              subtitle: 'Gerenciar permissões',
              onTap: () => context.push('/configuracoes/usuarios'),
            ),
            _buildDivider(isDark),

            // Acesso do Contador
            _buildSettingsTile(
              context: context,
              icon: Icons.account_balance_rounded,
              color: AppColors.brandGreen,
              title: 'Acesso do Contador',
              subtitle: 'Portais exclusivos',
              onTap: () => context.push('/configuracoes/contador'),
            ),
            _buildDivider(isDark),

            // Checklist de O.S
            _buildSettingsTile(
              context: context,
              icon: Icons.checklist_rtl_rounded,
              color: AppColors.brandBlue,
              title: 'Checklist O.S',
              subtitle: 'Itens padrão da ordem',
              onTap: () => context.push('/configuracoes/checklist'),
            ),
            _buildDivider(isDark),

            // Avançadas
            _buildSettingsTile(
              context: context,
              icon: Icons.settings_applications_rounded,
              color: Colors.grey,
              title: 'Configurações Avançadas',
              subtitle: 'Preferências do PDV e sistema',
              onTap: () => context.push('/configuracoes/avancadas'),
            ),
            _buildDivider(isDark),

            // Plano e Assinatura
            _buildSettingsTile(
              context: context,
              icon: Icons.star_rounded,
              color: AppColors.warning,
              title: 'Plano',
              subtitle: billing.planName,
              onTap: () => context.push('/configuracoes/plano'),
            ),
            _buildDivider(isDark),
          ],

          // Tema
          _buildSettingsTile(
            context: context,
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: AppColors.info,
            title: 'Tema',
            subtitle: themeMode == ThemeMode.dark ? 'Escuro' : 'Claro',
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
              activeTrackColor: AppColors.brandGreen,
            ),
          ),
          _buildDivider(isDark),

          // Central de Ajuda
          _buildSettingsTile(
            context: context,
            icon: Icons.help_outline_rounded,
            color: Colors.purple,
            title: 'Central de Ajuda',
            subtitle: 'Suporte, FAQs e Tutoriais',
            onTap: () => context.push('/configuracoes/ajuda'),
          ),
          _buildDivider(isDark),

          // Versão
          _buildSettingsTile(
            context: context,
            icon: Icons.info_outline_rounded,
            color: AppColors.success,
            title: 'Versão',
            subtitle: AppConstants.appVersion,
          ),

          Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),

          // Logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sair'),
                    content: const Text('Deseja sair da sua conta?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sair'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  ref.read(authNotifierProvider.notifier).signOut();
                }
              },
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.danger,
                size: 18,
              ),
              label: const Text(
                'Sair da conta',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.danger.withAlpha(80)),
                backgroundColor: AppColors.danger.withAlpha(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }
}
