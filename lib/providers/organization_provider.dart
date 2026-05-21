import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/organization.dart';
import '../data/repositories/organization_repository.dart';
import '../core/constants/supabase_constants.dart';
import 'auth_provider.dart';

/// Provider do repositório de organização.
final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepository();
});

/// Trigger periódico para revalidar status de acesso da organização.
final organizationHeartbeatProvider = StreamProvider<int>((ref) {
  return Stream<int>.periodic(const Duration(seconds: 60), (tick) => tick);
});

/// Stream Realtime que escuta alterações na organização atual.
/// Dispara quando o admin altera dados da organização (ex: enabled_features).
final organizationRealtimeProvider = StreamProvider<int>((ref) {
  final userProfile = ref.watch(userProfileProvider).value;
  final orgId = userProfile?.organizationId;

  if (orgId == null) {
    return const Stream<int>.empty();
  }

  // Escuta alterações na organização via Supabase Realtime
  final channel = supabase.channel('org_changes_$orgId');
  int tick = 0;

  final controller = Stream<int>.multi((controller) {
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'organizations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orgId,
          ),
          callback: (payload) {
            tick++;
            controller.add(tick);
          },
        )
        .subscribe();
  });

  ref.onDispose(() {
    supabase.removeChannel(channel);
  });

  return controller;
});

/// Provider da organização atual do usuário logado.
final currentOrganizationProvider = FutureProvider<Organization?>((ref) async {
  // Revalida periodicamente para captar bloqueios/reativações vindos do painel web/billing.
  ref.watch(organizationHeartbeatProvider);

  // Revalida instantaneamente quando o admin altera dados da organização.
  ref.watch(organizationRealtimeProvider);

  final userProfile = ref.watch(userProfileProvider).value;
  if (userProfile == null || userProfile.organizationId == null) return null;

  final repo = ref.read(organizationRepositoryProvider);
  return await repo.getById(userProfile.organizationId!);
});

/// Provider do ID da organização atual (conveniência).
final currentOrgIdProvider = Provider<String?>((ref) {
  final userProfile = ref.watch(userProfileProvider).value;
  return userProfile?.organizationId;
});
