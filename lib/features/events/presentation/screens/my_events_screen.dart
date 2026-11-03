import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header_bar.dart';
import '../../../../core/widgets/filter_chip_row.dart';
import '../../../../core/widgets/inline_banner.dart';
import '../../domain/entities/campus_event.dart';
import '../../domain/entities/event_cancel_result.dart';
import '../../domain/entities/event_kind.dart';
import '../controllers/event_actions_controller.dart';
import '../../../matches/presentation/providers/scheduled_meeting_providers.dart';
import '../../../matches/presentation/screens/meeting_screen.dart';
import '../providers/events_providers.dart';
import '../widgets/campus_event_card.dart';
import 'event_attendance_scan_screen.dart';
import 'event_detail_screen.dart';

enum _MyEventsFilter { all, upcoming, attended, missed }

class MyEventsScreen extends ConsumerStatefulWidget {
  const MyEventsScreen({super.key});

  @override
  ConsumerState<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends ConsumerState<MyEventsScreen> {
  _MyEventsFilter _filter = _MyEventsFilter.all;

  bool _matches(CampusEvent event, _MyEventsFilter filter) {
    final attended =
        event.registrationStatus == EventRegistrationStatus.attended;
    switch (filter) {
      case _MyEventsFilter.all:
        return true;
      case _MyEventsFilter.upcoming:
        return !event.hasEnded;
      case _MyEventsFilter.attended:
        return attended;
      case _MyEventsFilter.missed:
        return event.hasEnded && !attended;
    }
  }

  bool _meetingMatches(ScheduledMeeting meeting, _MyEventsFilter filter) {
    final ended = DateTime.now().isAfter(meeting.endsAt);
    switch (filter) {
      case _MyEventsFilter.all:
        return true;
      case _MyEventsFilter.upcoming:
        return !meeting.completed && !ended;
      case _MyEventsFilter.attended:
        return meeting.completed;
      case _MyEventsFilter.missed:
        return !meeting.completed && ended;
    }
  }

  CampusEventCardTone _toneFor(CampusEvent event) {
    if (event.registrationStatus == EventRegistrationStatus.attended) {
      return CampusEventCardTone.success;
    }
    if (event.sessionAttendance?.hasAny ?? false) {
      return CampusEventCardTone.neutral;
    }
    if (event.hasEnded) return CampusEventCardTone.destructive;
    return CampusEventCardTone.neutral;
  }

  String _messageFor(CampusEvent event, AppLocalizations l10n) {
    if (event.registrationStatus == EventRegistrationStatus.attended) {
      return l10n.myEventsAttendedMessage;
    }
    // A part-done program is neither attended nor missed — say which sessions
    // are still outstanding instead of picking one of those two.
    final progress = event.sessionAttendance;
    if (progress != null && progress.hasAny) {
      return l10n.programAttendanceProgress(progress.attended, progress.total);
    }
    if (event.hasEnded) return l10n.myEventsMissedMessage;
    return l10n.myEventsUpcomingMessage;
  }

  Future<void> _cancelRegistration(
    CampusEvent event,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelEventRegistrationTitle),
        content: Text(l10n.cancelEventRegistrationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.cancelEventRegistrationConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await ref
        .read(eventActionsControllerProvider.notifier)
        .cancel(event.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == EventCancelResult.ok
              ? l10n.cancelEventRegistrationSuccess
              : l10n.cancelEventRegistrationError,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final acceptedProgramIds =
        ref.watch(myAcceptedProgramIdsProvider).valueOrNull;
    final eventsAsync = ref.watch(myEventsProvider);
    final meetingsAsync = ref.watch(myMeetingsProvider);

    final filterLabels = {
      _MyEventsFilter.all: l10n.filterAll,
      _MyEventsFilter.upcoming: l10n.myEventsFilterUpcoming,
      _MyEventsFilter.attended: l10n.myEventsFilterAttended,
      _MyEventsFilter.missed: l10n.myEventsFilterMissed,
    };

    return Scaffold(
      appBar: AppHeaderBar(title: l10n.myEventsTitle),
      body: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: RefreshIndicator(
        onRefresh: () => ref.refresh(myEventsProvider.future),
        child: eventsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(child: Text(l10n.myEventsLoadError)),
            ],
          ),
          data: (events) {
            final filtered = events.where((e) => _matches(e, _filter)).toList()
              ..sort((a, b) => b.startsAt.compareTo(a.startsAt));

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: FilterChipRow(
                      options: filterLabels.values.toList(),
                      selected: filterLabels[_filter]!,
                      onSelected: (label) => setState(() {
                        _filter = filterLabels.entries
                            .firstWhere((e) => e.value == label)
                            .key;
                      }),
                    ),
                  ),
                ),
                // Scheduled meetings (from chat) live in My Events too, per the
                // spec — shown above campus events since they're time-sensitive.
                ...?meetingsAsync.whenOrNull(
                  data: (meetings) {
                    final filteredMeetings = meetings
                        .where((m) => _meetingMatches(m, _filter))
                        .toList();
                    return filteredMeetings.isEmpty
                        ? null
                        : [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  4,
                                  16,
                                  8,
                                ),
                                child: Text(
                                  l10n.myEventsMeetingsTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              sliver: SliverList.builder(
                                itemCount: filteredMeetings.length,
                                itemBuilder: (context, index) {
                                  final meeting = filteredMeetings[index];
                                  return _MeetingCard(
                                    meeting: meeting,
                                    l10n: l10n,
                                  );
                                },
                              ),
                            ),
                          ];
                  },
                ),
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          l10n.myEventsEmpty,
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final event = filtered[index];
                        return CampusEventCard(
                          event: event,
                          canManage: false,
                          registerBusy: false,
                          // Same rule as the events list and the detail
                          // screen: applied to a program but not yet accepted
                          // is "awaiting approval", not "Registered".
                          awaitingApproval:
                              event.eventKind == EventKind.program &&
                              event.registrationStatus ==
                                  EventRegistrationStatus.registered &&
                              acceptedProgramIds != null &&
                              !acceptedProgramIds.contains(event.id),
                          tone: _toneFor(event),
                          statusMessage: _messageFor(event, l10n),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EventDetailScreen(event: event),
                            ),
                          ),
                          onCheckIn: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  EventAttendanceScanScreen(event: event),
                            ),
                          ),
                          onCancel: () => _cancelRegistration(event, l10n),
                          onRegister: () {},
                          onDelete: () {},
                          onViewRegistrants: () {},
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
        ),
      ),
    );
  }
}

/// A scheduled meeting row in My Events — tapping opens the two-sided Meeting
/// Screen. Shows a completed badge once both students have scanned.
class _MeetingCard extends StatelessWidget {
  const _MeetingCard({required this.meeting, required this.l10n});

  final ScheduledMeeting meeting;
  final AppLocalizations l10n;

  // toLocal(): stored as UTC; format in campus time.
  String _when(DateTime utc) {
    final dt = utc.toLocal();
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}'
        ' · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final windowOpen =
        now.isAfter(meeting.scheduledAt) && now.isBefore(meeting.endsAt);
    final ended = !windowOpen && now.isAfter(meeting.endsAt);
    final actionable = !meeting.completed && windowOpen;

    Widget? trailingIndicator;
    if (meeting.completed) {
      trailingIndicator = Text(
        l10n.meetingCardCompleted,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.success,
        ),
      );
    } else if (windowOpen) {
      trailingIndicator = const Icon(Icons.chevron_right);
    } else if (!ended) {
      trailingIndicator = const Icon(
        Icons.schedule,
        size: 18,
        color: AppColors.mutedForeground,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: actionable
            ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MeetingScreen(
                    proposalId: meeting.proposalId,
                    otherName: meeting.otherName,
                    scheduledAt: meeting.scheduledAt,
                    endsAt: meeting.endsAt,
                  ),
                ),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Icon(
                    meeting.completed ? Icons.check : Icons.people_alt_outlined,
                    color: meeting.completed
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.meetingCardWith(meeting.otherName),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_when(meeting.scheduledAt)}'
                        '${meeting.location != null && meeting.location!.isNotEmpty ? ' · ${meeting.location}' : ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailingIndicator != null) ...[
                  const SizedBox(width: 8),
                  trailingIndicator,
                ],
              ],
            ),
            if (meeting.completed || !windowOpen) ...[
              const SizedBox(height: 10),
              InlineBanner(
                message: meeting.completed
                    ? l10n.meetingAttendedMessage
                    : ended
                    ? l10n.meetingMissedMessage
                    : l10n.meetingNotYetOpen,
                tone: meeting.completed
                    ? BannerTone.success
                    : ended
                    ? BannerTone.error
                    : BannerTone.neutral,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
