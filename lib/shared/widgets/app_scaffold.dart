import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/billing_provider.dart';
import 'app_drawer.dart';

/// Base scaffold with global shell styling.
class AppScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final bool showDrawer;

  const AppScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.bottomNavigationBar,
    this.showDrawer = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final canShowAssistantRoute =
        currentLocation != '/assistente' &&
        currentLocation != '/blocked' &&
        currentLocation != '/mobile-bloqueado' &&
        currentLocation != '/login';

    final appBarActions = <Widget>[
      ...?actions,
      // Verifica se a feature assistente_ia está habilitada via billing
      if (canShowAssistantRoute)
        Consumer(
          builder: (context, ref, _) {
            final billing = ref.watch(billingProvider);
            if (!billing.hasFeature('assistente_ia')) {
              return const SizedBox.shrink();
            }
            return _ActionIcon(
              tooltip: 'Assistente IA',
              icon: Icons.smart_toy_rounded,
              onTap: () => GoRouter.of(context).push('/assistente'),
            );
          },
        ),
      const SizedBox(width: 4),
    ];

    final appBarGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [Color(0xFF0A2344), Color(0xFF10325D)]
          : const [Color(0xFFF7FBFF), Color(0xFFE8F2FF)],
    );

    final borderColor = isDark
        ? AppColors.darkBorderStrong.withAlpha(185)
        : AppColors.lightBorderStrong.withAlpha(210);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
        } else {
          final location = GoRouterState.of(context).matchedLocation;
          if (location != '/') {
            router.go('/');
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          titleSpacing: 14,
          toolbarHeight: subtitle == null ? 68 : 82,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          actions: appBarActions,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: appBarGradient,
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : AppColors.brandBlue)
                      .withAlpha(isDark ? 54 : 24),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
        drawer: showDrawer ? const AppDrawer() : null,
        body: Container(
          constraints: const BoxConstraints.expand(),
          decoration: BoxDecoration(
            gradient: isDark
                ? AppColors.surfaceGradientDark
                : AppColors.surfaceGradientLight,
          ),
          child: Stack(
            children: [
              Positioned(
                top: -120,
                right: -84,
                child: _GlowOrb(
                  size: 280,
                  color: (isDark ? AppColors.brandBlue : AppColors.brandGreen)
                      .withAlpha(isDark ? 32 : 20),
                ),
              ),
              Positioned(
                top: -90,
                left: -60,
                child: _GlowOrb(
                  size: 220,
                  color: (isDark ? AppColors.brandGreen : AppColors.brandBlue)
                      .withAlpha(isDark ? 42 : 28),
                ),
              ),
              Positioned(
                right: -80,
                bottom: -100,
                child: _GlowOrb(
                  size: 260,
                  color: (isDark ? AppColors.brandBlue : AppColors.brandGreen)
                      .withAlpha(isDark ? 42 : 26),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDark
                            ? [
                                Colors.white.withAlpha(5),
                                Colors.transparent,
                                Colors.black.withAlpha(18),
                              ]
                            : [
                                Colors.white.withAlpha(28),
                                Colors.transparent,
                                Colors.white.withAlpha(10),
                              ],
                        stops: const [0, 0.32, 1],
                      ),
                    ),
                  ),
                ),
              ),
              body,
            ],
          ),
        ),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      child: Material(
        color: isDark
            ? AppColors.darkSurfaceElevated.withAlpha(220)
            : AppColors.lightCard.withAlpha(235),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        shadowColor: Colors.black.withAlpha(isDark ? 40 : 10),
        elevation: 1.5,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Tooltip(
              message: tooltip,
              child: Icon(
                icon,
                size: 20,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withAlpha(0)]),
        ),
      ),
    );
  }
}
