import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/inline_banner.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../onboarding/domain/entities/demo_key.dart';
import '../../../onboarding/presentation/controllers/demo_flags_controller.dart';
import '../../../onboarding/presentation/widgets/contextual_showcase.dart';
import '../../../roles/domain/entities/user_role.dart';
import '../../../roles/presentation/providers/roles_providers.dart';
import '../../domain/entities/campus_event.dart';
import '../../domain/entities/event_session.dart';
import '../../domain/usecases/event_permissions.dart';
import '../providers/events_providers.dart';
import '../widgets/session_schedule.dart';
import 'event_attendance_scan_screen.dart';
import 'event_qr_display_screen.dart';
import 'event_statistics_screen.dart';

/// A Program's full profile — points equation at top, then every session
/// in chronological order. Reached from `event_detail_screen`'s "View
/// Sessions"/"Manage Sessions" action for `event_kind == program` events.
class ProgramDetailScreen extends ConsumerWidget {
  ProgramDetailScreen({super.key, required this.event});

  final CampusEvent event;

  /// Stable for the lifetime of this pushed route.
  final _pointsShowcaseKey = GlobalKey();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = event.localizedTitle(languageCode);
    final description = event.localizedDescription(languageCode);
    final sessionsAsync = ref.watch(eventSessionsProvider(event.id));
    final myRoles =
        ref.watch(myRolesProvider).valueOrNull ?? const <UserRole>{};
    final hostAccessIds =
        ref.watch(myHostAccessEventIdsProvider).valueOrNull ?? const <String>{};
    final viewerId = ref.watch(currentAuthSessionProvider).userId ?? '';
    final canManage = EventPermissions.canManage(
      event,
      roles: myRoles,
      viewerId: viewerId,
      hasHostAccessGrant: hostAccessIds.contains(event.id),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.programSessionsLoadError)),
        data: (sessions) {
          final totalPoints = event.points * sessions.length;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (description != null && description.trim().isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    description,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Builder(
                builder: (context) {
                  final showDemo = !ref.watch(
                    hasSeenDemoProvider(DemoKey.program),
                  );
                  if (showDemo) {
                    startContextualDemoOnce(
                      context: context,
                      ref: ref,
                      key: DemoKey.program,
                      showcaseKeys: [_pointsShowcaseKey],
                    );
                  }
                  final equationCard = Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.programPointsEquation(
                        event.points,
                        sessions.length,
                        totalPoints,
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  );
                  return showDemo
                      ? ContextualShowcase(
                          showcaseKey: _pointsShowcaseKey,
                          title: l10n.demoProgramTitle,
                          description: l10n.demoProgramMessage,
                          child: equationCard,
                        )
                      : equationCard;
                },
              ),
              // How far through the program the student is. Each row below
              // carries its own status; this is the one-line summary of them,
              // and the only "attended" line a program gets — the event-level
              // banner on the detail screen speaks for single events.
              if (!canManage &&
                  sessions.any(
                    (session) =>
                        session.registrationStatus !=
                        EventRegistrationStatus.notRegistered,
                  )) ...[
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final attended = sessions
                        .where(
                          (session) =>
                              session.registrationStatus ==
                              EventRegistrationStatus.attended,
                        )
                        .length;
                    return InlineBanner(
                      message: attended == sessions.length
                          ? l10n.programAttendedAllSessions
                          : l10n.programAttendanceProgress(
                              attended,
                              sessions.length,
                            ),
                      tone: BannerTone.success,
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
              Text(
                l10n.programSessionsTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 12),
              if (sessions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      l10n.programSessionsEmpty,
                      style: const TextStyle(color: AppColors.mutedForeground),
                    ),
                  ),
                )
              else
                ...sessions.map(
                  (session) => _SessionRow(
                    event: event,
                    session: session,
                    canManage: canManage,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.event,
    required this.session,
    required this.canManage,
  });

  final CampusEvent event;
  final EventSession session;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Session title and venue are translated alongside the parent event by
    // the `translate-content` edge function; render the viewer's language
    // rather than whatever language the admin happened to type.
    final languageCode = Localizations.localeOf(context).languageCode;
    final sessionTitle = session.localizedTitle(languageCode);
    final sessionLocation = session.localizedLocation(languageCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sessionTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: AppColors.mutedForeground,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: SessionSchedule(
                            startsAt: session.startsAt,
                            endsAt: session.endsAt,
                            dateStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.mutedForeground,
                            ),
                            timeStyle: const TextStyle(
                              fontSize: 11,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (sessionLocation != null && sessionLocation.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: AppColors.mutedForeground,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                sessionLocation,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (canManage) ...[
                const SizedBox(width: 8),
                _IconAction(
                  icon: Icons.qr_code_2,
                  color: AppColors.primary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EventQrDisplayScreen(
                        title: sessionTitle,
                        eventId: event.id,
                        sessionId: session.id,
                        initialEnabled: session.qrEnabled,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _IconAction(
                  icon: Icons.bar_chart,
                  color: AppColors.secondaryForeground,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EventStatisticsScreen(
                        eventId: event.id,
                        sessionId: session.id,
                        title: sessionTitle,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (!canManage) ...[
            const SizedBox(height: 10),
            _SessionStatus(event: event, session: session, l10n: l10n),
          ],
        ],
      ),
    );
  }
}

class _SessionStatus extends StatelessWidget {
  const _SessionStatus({
    required this.event,
    required this.session,
    required this.l10n,
  });

  final CampusEvent event;
  final EventSession session;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // Passed to the scan screen's header, so it must follow the viewer's
    // language like the row above it.
    final sessionTitle = session.localizedTitle(
      Localizations.localeOf(context).languageCode,
    );

    switch (session.registrationStatus) {
      case EventRegistrationStatus.attended:
        return InlineBanner(
          message: l10n.myEventsAttendedMessage,
          tone: BannerTone.success,
        );
      case EventRegistrationStatus.registered:
        if (session.hasEnded) {
          return InlineBanner(
            message: l10n.myEventsMissedMessage,
            tone: BannerTone.error,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EventAttendanceScanScreen(
                    event: event,
                    sessionTitle: sessionTitle,
                    sessionId: session.id,
                  ),
                ),
              ),
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              label: Text(l10n.eventScanToCheckInAction),
            ),
            const SizedBox(height: 8),
            InlineBanner(
              message: l10n.myEventsUpcomingMessage,
              tone: BannerTone.neutral,
            ),
          ],
        );
      case EventRegistrationStatus.notRegistered:
        return const SizedBox.shrink();
    }
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}
