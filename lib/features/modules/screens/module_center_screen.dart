import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_scaffold.dart';

class ModuleShortcut {
  final String title;
  final String description;
  final String route;
  final IconData icon;

  const ModuleShortcut({
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
  });
}

/// Tela de centro de módulo para áreas ainda não dedicadas no mobile.
class ModuleCenterScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData heroIcon;
  final List<String> bullets;
  final List<ModuleShortcut> shortcuts;

  const ModuleCenterScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.heroIcon,
    this.bullets = const [],
    this.shortcuts = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: title,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withAlpha(230),
                  colorScheme.tertiary.withAlpha(210),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withAlpha(48),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(36),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(heroIcon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withAlpha(225),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'O que você pode fazer aqui',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    ...bullets.map(
                      (bullet) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Icon(
                                Icons.circle,
                                size: 7,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                bullet,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (shortcuts.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Acessos rápidos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...shortcuts.map(
              (shortcut) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(shortcut.icon, color: colorScheme.primary),
                  ),
                  title: Text(
                    shortcut.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(shortcut.description),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(shortcut.route),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
