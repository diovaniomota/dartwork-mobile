import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

/// Tela de login premium — visual espelhado da versão web.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authNotifierProvider.notifier);
      await auth.signIn(_emailCtrl.text.trim(), _passwordCtrl.text);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = 'Credenciais inválidas. Verifique e tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Fundo com gradiente radial azul/verde (como a web)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.loginGradientStart,
              AppColors.loginGradientMid,
              AppColors.loginGradientEnd,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Círculos decorativos de fundo
            Positioned(
              top: -80,
              left: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.brandBlue.withAlpha(70),
                      AppColors.brandBlue.withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              right: -80,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.brandGreen.withAlpha(60),
                      AppColors.brandGreen.withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),

            // Conteúdo principal
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      // Glassmorphism sutil
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF102456).withAlpha(240),
                          const Color(0xFF0A1B42).withAlpha(240),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.info.withAlpha(90),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF040A1C).withAlpha(130),
                          blurRadius: 50,
                          offset: const Offset(0, 24),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.brandBlue.withAlpha(65),
                                  AppColors.brandGreen.withAlpha(50),
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.info.withAlpha(75),
                              ),
                            ),
                            child: const Icon(
                              Icons.work_rounded,
                              size: 44,
                              color: AppColors.brandGreen,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Título
                          const Text(
                            'Work ERP',
                            style: TextStyle(
                              color: Color(0xFFF2F7FF),
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Acesse sua conta',
                            style: TextStyle(
                              color: const Color(0xFFB6CAEE).withAlpha(200),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Erro
                          if (_error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                                border: Border(
                                  left: BorderSide(
                                    color: AppColors.danger,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppColors.danger,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: Color(0xFFF9A8A8),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // E-mail
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    color: Color(0xFFE5EFFF),
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'E-mail',
                                    style: TextStyle(
                                      color: Color(0xFFE5EFFF),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                  color: Color(0xFFF2F7FF),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'seu@email.com',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF95ACD4),
                                  ),
                                  filled: true,
                                  fillColor: const Color(
                                    0xFF09183A,
                                  ).withAlpha(210),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: const Color(
                                        0xFF436FB8,
                                      ).withAlpha(180),
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: const Color(
                                        0xFF436FB8,
                                      ).withAlpha(180),
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: AppColors.info,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (v) => v == null || !v.contains('@')
                                    ? 'E-mail inválido'
                                    : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Senha
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    color: Color(0xFFE5EFFF),
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Senha',
                                    style: TextStyle(
                                      color: Color(0xFFE5EFFF),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscurePassword,
                                style: const TextStyle(
                                  color: Color(0xFFF2F7FF),
                                ),
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF95ACD4),
                                  ),
                                  filled: true,
                                  fillColor: const Color(
                                    0xFF09183A,
                                  ).withAlpha(210),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: const Color(
                                        0xFF436FB8,
                                      ).withAlpha(180),
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: const Color(
                                        0xFF436FB8,
                                      ).withAlpha(180),
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: AppColors.info,
                                      width: 2,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF9AB1D8),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                validator: (v) => v == null || v.length < 6
                                    ? 'Mínimo 6 caracteres'
                                    : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Botão de login com gradiente
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: _loading
                                    ? null
                                    : AppColors.brandGradient,
                                color: _loading
                                    ? AppColors.brandBlue.withAlpha(100)
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _loading
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF0F2D67,
                                          ).withAlpha(130),
                                          blurRadius: 28,
                                          offset: const Offset(0, 14),
                                        ),
                                      ],
                              ),
                              child: ElevatedButton(
                                onPressed: _loading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  disabledBackgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white70,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.login_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Entrar',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Esqueci a senha
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Esqueci minha senha',
                              style: TextStyle(
                                color: Color(0xFF79C9B6),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
