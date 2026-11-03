import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../home/presentation/widgets/home_stat_card.dart';
import '../providers/events_providers.dart';
import '../widgets/confirm_by_student_id_sheet.dart';

/// Host/admin "Statistics & Analytics" — the registrants list (unchanged
/// from the original `event_registrants_screen`) with three summary tiles
/// (Registered/Attended/Missed, from `get_event_stats`) prepended above it,
/// reusing `HomeStatCard`'s exact visual shape.
class EventStatisticsScreen extends ConsumerWidget {
  const EventStatisticsScreen({
    super.key,
    required this.eventId,
    this.sessionId,
    this.title,
  });

  final String eventId;
  final String? sessionId;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final args = (eventId: eventId, sessionId: sessionId);
    final registrantsAsync = ref.watch(_eventRegistrantsProvider(args));
    final statsAsync = ref.watch(_eventStatsProvider(args));

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? l10n.registrantsTitle),
        actions: [
          // Manual check-in from the Participants list, for students whose QR
          // couldn't be scanned.
          IconButton(
            icon: const Icon(Icons.pin_outlined),
            tooltip: l10n.attendanceManualTitle,
            onPressed: () async {
              final confirmed = await showConfirmByStudentIdSheet(
                context,
                eventId: eventId,
                sessionId: sessionId,
              );
              if (confirmed) {
                ref.invalidate(_eventRegistrantsProvider(args));
                ref.invalidate(_eventStatsProvider(args));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          statsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (stats) => Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: HomeStatCard(
                      icon: Icons.how_to_reg_outlined,
                      iconColor: AppColors.secondaryForeground,
                      backgroundColor: AppColors.sky,
                      label: l10n.eventStatsRegistered,
                      count: stats.registered,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HomeStatCard(
                      icon: Icons.check_circle_outline,
                      iconColor: AppColors.foreground,
                      backgroundColor: AppColors.mint,
                      label: l10n.eventStatsAttended,
                      count: stats.attended,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HomeStatCard(
                      icon: Icons.cancel_outlined,
                      iconColor: AppColors.foreground,
                      backgroundColor: AppColors.pink,
                      label: l10n.eventStatsMissed,
                      count: stats.missed,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: registrantsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text(l10n.homeLoadError)),
              data: (registrants) {
                if (registrants.isEmpty) {
                  return Center(child: Text(l10n.registrantsEmpty));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: registrants.length,
                  itemBuilder: (context, index) {
                    final registrant = registrants[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          InitialsAvatar(
                            initials: registrant.fullName.isEmpty
                                ? '?'
                                : registrant.fullName[0],
                            hue: 220,
                            size: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  registrant.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  registrant.email ?? '',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            registrant.attended
                                ? l10n.registrantAttended
                                : l10n.registrantRegisteredOnly,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: registrant.attended
                                  ? AppColors.success
                                  : AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final _eventRegistrantsProvider = FutureProvider.autoDispose.family((
  ref,
  ({String eventId, String? sessionId}) args,
) {
  return ref.watch(getEventRegistrantsProvider)(
    args.eventId,
    sessionId: args.sessionId,
  );
});

final _eventStatsProvider = FutureProvider.autoDispose.family((
  ref,
  ({String eventId, String? sessionId}) args,
) {
  return ref.watch(getEventStatsProvider)(
    args.eventId,
    sessionId: args.sessionId,
  );
});
