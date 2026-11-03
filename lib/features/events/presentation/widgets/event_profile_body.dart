import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/external_link_value.dart';
import '../../../admin/domain/entities/option_list_type.dart';
import '../../../admin/presentation/providers/option_label_providers.dart';
import '../../domain/entities/campus_event.dart';
import '../../domain/entities/event_kind.dart';
import '../../domain/entities/event_session.dart';
import '../providers/events_providers.dart';
import 'session_schedule.dart';

/// The spec-ordered Event Profile, shared by the student detail screen and the
/// admin approval review so an approver sees exactly what students will see.
///
/// Field order is fixed by the spec and deliberately literal — Title, Image,
/// Organizer, Points, Description, Location, Schedule, Organizer Description,
/// External Link, Category.
///
/// For `EventKind.program` the schedule section becomes a table of every
/// session rather than one start/end pair, and the points section shows the
/// program total (per-session points × sessions) — a program was previously
/// indistinguishable from a one-time event here.
class EventProfileBody extends ConsumerWidget {
  const EventProfileBody({
    super.key,
    required this.event,
    this.showSessionAttendance = false,
  });

  final CampusEvent event;

  /// Whether the sessions table gets a per-session attendance column.
  ///
  /// Only meaningful for a student who is actually taking part in the program —
  /// hosts see the manage-side UI instead, and a student who hasn't registered
  /// has no attendance to report, so both get the plain three-column table.
  final bool showSessionAttendance;

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _dateTime(DateTime dt) =>
      '${_two(dt.day)}.${_two(dt.month)}.${dt.year} · ${_two(dt.hour)}:${_two(dt.minute)}';

  static String _timeOnly(DateTime dt) => '${_two(dt.hour)}:${_two(dt.minute)}';

  /// Whether two instants fall on the same calendar day. The schedule row
  /// abbreviates the end to a bare time, which silently drops the day for an
  /// event that runs past midnight — a 13.09 20:00 → 14.09 20:00 event read as
  /// `20:00 – 20:00`. Multi-day events spell the end date out instead.
  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = event.localizedTitle(languageCode);
    final description = event.localizedDescription(languageCode);
    final organizerName = event.localizedOrganizerName(languageCode);
    final location = event.localizedLocation(languageCode);
    final organizerDescription = event.localizedOrganizerDescription(
      languageCode,
    );
    final isProgram = event.eventKind == EventKind.program;

    // Only programs need the sessions round trip.
    final sessionsAsync = isProgram
        ? ref.watch(eventSessionsProvider(event.id))
        : null;
    final sessions = sessionsAsync?.valueOrNull ?? const <EventSession>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Title
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),

        // 2. Image
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: event.imageUrl != null && event.imageUrl!.isNotEmpty
              ? Image.network(
                  event.imageUrl!,
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _ImageFallback(),
                )
              : const _ImageFallback(),
        ),

        // 3. Organizer / business name
        if (organizerName != null && organizerName.trim().isNotEmpty)
          _Section(
            title: l10n.eventProfileOrganizerLabel,
            icon: Icons.storefront_outlined,
            child: Text(organizerName),
          ),

        // 4. Points awarded — for a program, the headline number is what the
        // student earns for completing the whole thing.
        _Section(
          title: l10n.eventProfilePointsLabel,
          icon: Icons.stars_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isProgram) ...[
                Text(
                  l10n.eventProfileTotalPoints(event.points * sessions.length),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.eventProfilePerSessionPoints(event.points)}'
                  ' · ${l10n.eventProfileSessionCount(sessions.length)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ] else
                Text(
                  l10n.eventPointsLabel(event.points),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
            ],
          ),
        ),

        // 5. Event description
        if (description != null && description.trim().isNotEmpty)
          _Section(
            title: l10n.eventProfileDescriptionLabel,
            icon: Icons.notes_outlined,
            child: Text(description),
          ),

        // 6. Location
        if (!isProgram && location != null && location.trim().isNotEmpty)
          _Section(
            title: l10n.eventProfileLocationLabel,
            icon: Icons.location_on_outlined,
            child: Text(location),
          ),

        // 7. Schedule — a table of sessions for programs, one range otherwise.
        _Section(
          title: isProgram
              ? l10n.eventProfileSessionsLabel
              : l10n.eventProfileScheduleLabel,
          icon: Icons.calendar_today_outlined,
          child: isProgram
              ? _SessionsTable(
                  async: sessionsAsync!,
                  l10n: l10n,
                  showAttendance: showSessionAttendance,
                )
              : Text(
                  _sameDay(event.startsAt, event.endsAt)
                      ? '${_dateTime(event.startsAt)} – ${_timeOnly(event.endsAt)}'
                      : '${_dateTime(event.startsAt)} – ${_dateTime(event.endsAt)}',
                ),
        ),

        // 8. Organizer description
        if (organizerDescription != null &&
            organizerDescription.trim().isNotEmpty)
          _Section(
            title: l10n.eventProfileOrganizerDescriptionLabel,
            icon: Icons.info_outline,
            child: Text(organizerDescription),
          ),

        // 9. External link
        if (event.externalLink != null && event.externalLink!.trim().isNotEmpty)
          _Section(
            title: l10n.eventProfileExternalLinkLabel,
            icon: Icons.link_outlined,
            child: ExternalLinkValue(value: event.externalLink!.trim()),
          ),

        // 10. Category
        if (event.category != null && event.category!.trim().isNotEmpty)
          _Section(
            title: l10n.eventProfileCategoryLabel,
            icon: Icons.category_outlined,
            child: OptionLabelText(
              type: OptionListType.eventCategory,
              value: event.category,
            ),
          ),
      ],
    );
  }
}

/// Every session of a program, chronological — the "table" the spec asks for.
/// Breathing room between the schedule column and the venue column. The
/// schedule's end time runs to the right edge of its cell, so without this the
/// two read as one run-on string.
const double _whenGap = 14;

class _SessionsTable extends StatelessWidget {
  const _SessionsTable({
    required this.async,
    required this.l10n,
    this.showAttendance = false,
  });

  final AsyncValue<List<EventSession>> async;
  final AppLocalizations l10n;

  /// Adds the per-session attendance column. See
  /// [EventProfileBody.showSessionAttendance].
  final bool showAttendance;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => Text(
        l10n.programSessionsLoadError,
        style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
      ),
      data: (sessions) {
        // Session title and venue are translated alongside the parent event;
        // render the viewer's language, not whatever the admin typed.
        final sessionLanguageCode = Localizations.localeOf(
          context,
        ).languageCode;
        if (sessions.isEmpty) {
          return Text(
            l10n.programSessionsEmpty,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          );
        }
        return Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      l10n.eventProfileSessionColumn,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      l10n.eventProfileWhenColumn,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                  // Keeps the schedule's end time off the venue text. Mirrored
                  // in the data row below so the columns stay aligned.
                  const SizedBox(width: _whenGap),
                  Expanded(
                    flex: 2,
                    child: Text(
                      l10n.eventProfileWhereColumn,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                  if (showAttendance)
                    Expanded(
                      flex: 2,
                      child: Text(
                        l10n.eventProfileStatusColumn,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            for (var i = 0; i < sessions.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: i == 0
                          ? AppColors.border
                          : AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        sessions[i].localizedTitle(sessionLanguageCode),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: SessionSchedule(
                        startsAt: sessions[i].startsAt,
                        endsAt: sessions[i].endsAt,
                        dateStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        timeStyle: const TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                    const SizedBox(width: _whenGap),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _sessionLocation(sessions[i], sessionLanguageCode),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                    if (showAttendance)
                      Expanded(
                        flex: 2,
                        child: _SessionAttendance(
                          session: sessions[i],
                          l10n: l10n,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One session's attendance status, using the same three states a one-time
/// event gets in My Events: attended, missed once it's over, upcoming until
/// then. Kept to a word so it fits a table cell — the sentence-length wording
/// lives on the program detail screen.
class _SessionAttendance extends StatelessWidget {
  const _SessionAttendance({required this.session, required this.l10n});

  final EventSession session;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final attended =
        session.registrationStatus == EventRegistrationStatus.attended;

    final (label, color, icon) = attended
        ? (l10n.eventAttendedLabel, AppColors.success, Icons.check_circle)
        : session.hasEnded
        ? (l10n.eventProfileSessionMissed, AppColors.destructive, Icons.cancel)
        : (
            l10n.eventProfileSessionUpcoming,
            AppColors.mutedForeground,
            Icons.schedule,
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// A session's venue in [languageCode], or an em dash when it has none.
String _sessionLocation(EventSession session, String languageCode) {
  final value = session.localizedLocation(languageCode);
  if (value == null || value.trim().isEmpty) return '—';
  return value;
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      width: double.infinity,
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      child: const Text('🎉', style: TextStyle(fontSize: 56)),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DefaultTextStyle(
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.foreground,
                height: 1.4,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
