import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/inline_banner.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../roles/domain/entities/user_role.dart';
import '../../../roles/presentation/providers/roles_providers.dart';
import '../../../admin/domain/entities/option_list_type.dart';
import '../../../admin/presentation/providers/option_label_providers.dart';
import '../../domain/entities/campus_event.dart';
import '../../domain/entities/event_action_result.dart';
import '../../domain/entities/event_cancel_result.dart';
import '../../domain/entities/event_kind.dart';
import '../../domain/usecases/event_capacity.dart';
import '../../domain/usecases/event_permissions.dart';
import '../controllers/event_actions_controller.dart';
import '../providers/events_providers.dart';
import '../widgets/event_profile_body.dart';
import 'event_attendance_scan_screen.dart';
import 'event_create_edit_screen.dart';
import 'event_qr_display_screen.dart';
import 'event_statistics_screen.dart';
import 'program_detail_screen.dart';

/// Which entry of the share sheet the user picked.
enum _ShareAction { copyLink, shareSheet }

/// Full event profile — image, description, meta info, and the
/// register/cancel CTA. Reached by tapping a `CampusEventCard`; the event
/// object is passed straight through (same convention as
/// `MatchProfileScreen`) rather than re-fetched by id.
class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.event});

  /// The snapshot whoever pushed this route was holding. It is the starting
  /// value only: [build] then follows the live row, so an edit saved in the
  /// admin panel changes this screen under the student instead of waiting for
  /// them to back out and come in again. See `eventsLiveRefreshProvider`.
  final CampusEvent event;

  Future<void> _register(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final result = await ref
        .read(eventActionsControllerProvider.notifier)
        .register(event.id);
    if (!context.mounted) return;
    final message = switch (result) {
      // A program's registration is an APPLICATION, not a place: the student
      // is a registrant until an organizer accepts them. Saying "you're
      // registered!" there promises something that hasn't happened yet and
      // contradicts the pending status the button then shows.
      EventActionResult.ok =>
        event.eventKind == EventKind.program
            ? l10n.registerPendingApproval
            : l10n.registerSuccess,
      EventActionResult.alreadyRegistered => l10n.registerErrorAlready,
      EventActionResult.full => l10n.registerErrorFull,
      EventActionResult.ended => l10n.registerErrorEnded,
      EventActionResult.notPublished => l10n.registerErrorNotPublished,
      EventActionResult.notFound => l10n.registerErrorNotFound,
      EventActionResult.unknown => l10n.registerErrorGeneric,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
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
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(eventActionsControllerProvider.notifier)
        .cancel(event.id);
    if (!context.mounted) return;
    final message = switch (result) {
      EventCancelResult.ok => l10n.cancelEventRegistrationSuccess,
      _ => l10n.cancelEventRegistrationError,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Cancel stays available until the event starts or a program session has
  /// already been attended.
  bool _canCancelRegistration(CampusEvent event) {
    if (event.registrationStatus != EventRegistrationStatus.registered) {
      return false;
    }
    if (event.hasStarted) return false;
    if (event.sessionAttendance?.hasAny == true) return false;
    return true;
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteEventTitle),
        content: Text(l10n.deleteEventMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteEventConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await ref
        .read(eventActionsControllerProvider.notifier)
        .delete(event.id);
    if (!context.mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.deleteEventError)));
    }
  }

  /// Share sheet for this event: copy the link, or hand it to the OS share
  /// sheet (WhatsApp, Mail, Messages, …).
  ///
  /// The link is just `AppConfig.eventShareUrl` — an id, nothing else. The
  /// title goes in the accompanying message text so the recipient knows what
  /// they're being sent, but every actual detail is fetched by the app from
  /// the server under the recipient's own permissions.
  Future<void> _openShareSheet(
    BuildContext context,
    AppLocalizations l10n,
    CampusEvent event,
  ) async {
    final title = event.localizedTitle(
      Localizations.localeOf(context).languageCode,
    );
    final link = AppConfig.eventShareUrl(event.id);
    final messenger = ScaffoldMessenger.of(context);

    final action = await showModalBottomSheet<_ShareAction>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.link, size: 20),
              title: Text(l10n.eventShareCopyLink),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_ShareAction.copyLink),
            ),
            ListTile(
              leading: const Icon(Icons.ios_share, size: 20),
              title: Text(l10n.eventShareViaApps),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_ShareAction.shareSheet),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null) return;

    try {
      switch (action) {
        case _ShareAction.copyLink:
          await Clipboard.setData(ClipboardData(text: link));
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.eventShareLinkCopied)),
          );
        case _ShareAction.shareSheet:
          await SharePlus.instance.share(
            ShareParams(
              text: '${l10n.eventShareMessage(title)}\n$link',
              subject: title,
            ),
          );
      }
    } catch (e) {
      // A share sheet the OS refuses to open (or a clipboard write that
      // fails) must not look like a successful share.
      debugPrint('EventDetailScreen: share failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(l10n.eventShareFailed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Follow the live row for the WHOLE event, not just its capacity: title,
    // description, location, times and image all change in the admin panel
    // too, and this screen used to render the pushed snapshot for as long as
    // it stayed open. Never blank out what the student is looking at, though —
    // while the refetch is in flight, or if it fails, the snapshot still
    // renders. `eventsLiveRefreshProvider` invalidates this on any edit.
    final event =
        ref.watch(eventByIdProvider(this.event.id)).valueOrNull ?? this.event;
    final busy = ref.watch(eventActionsControllerProvider).contains(event.id);
    final myRoles =
        ref.watch(myRolesProvider).valueOrNull ?? const <UserRole>{};
    final hostAccessIds =
        ref.watch(myHostAccessEventIdsProvider).valueOrNull ?? const <String>{};
    final viewerId = ref.watch(currentAuthSessionProvider).userId ?? '';
    // An uncapped event can never be full, so it costs nothing: no count at
    // all. `event` is already the live row above, so the cap needs no second
    // read of its own.
    //
    // While the count is in flight (or if it fails) the event counts as having
    // room: the server refuses a genuinely full registration anyway, so erring
    // this way costs a snackbar, whereas erring the other way would lock
    // students out of an event that has space.
    //
    // Watched conditionally on `event.capacity`, which can now change under a
    // live edit — adding a cap to an uncapped event starts the watch on the
    // next build, removing one stops it. Riverpod allows a dependency set that
    // varies between builds; it just drops the subscriptions no longer read.
    final EventCapacity capacity;
    if (event.capacity == null) {
      capacity = const EventCapacity.unlimited();
    } else {
      capacity = EventCapacity(
        registered:
            ref.watch(eventRegistrationCountProvider(event.id)).valueOrNull ??
            0,
        capacity: event.capacity,
      );
    }
    // Awaiting approval = holds a registration for a PROGRAM but is absent
    // from the backend's accepted list. Single events have no acceptance step,
    // so they can never be in this state. While the lookup is in flight the
    // answer is "not pending", which keeps the existing CTA on screen instead
    // of flashing a status that may not apply.
    final acceptedProgramIds =
        ref.watch(myAcceptedProgramIdsProvider).valueOrNull;
    final awaitingProgramApproval =
        event.eventKind == EventKind.program &&
        event.registrationStatus == EventRegistrationStatus.registered &&
        acceptedProgramIds != null &&
        !acceptedProgramIds.contains(event.id);
    final acceptedOntoProgram =
        event.eventKind == EventKind.program &&
        (acceptedProgramIds?.contains(event.id) ?? false);

    final canManage = EventPermissions.canManage(
      event,
      roles: myRoles,
      viewerId: viewerId,
      hasHostAccessGrant: hostAccessIds.contains(event.id),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _openShareSheet(context, l10n, event),
            icon: const Icon(Icons.ios_share),
            tooltip: l10n.eventShareAction,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type/category pills sit above the spec-ordered profile —
                  // they're chrome, not one of the spec's profile fields.
                  Row(
                    children: [
                      if (event.category != null && event.category!.isNotEmpty)
                        _Pill(
                          text: localizedOptionLabel(
                            ref,
                            context,
                            type: OptionListType.eventCategory,
                            storedLabel: event.category,
                          ),
                          background: AppColors.peach,
                        ),
                      if (event.category != null && event.category!.isNotEmpty)
                        const SizedBox(width: 8),
                      _Pill(
                        text: event.eventKind == EventKind.program
                            ? l10n.eventTypeProgram
                            : l10n.eventTypeSingle,
                        background: AppColors.sky,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  EventProfileBody(
                    event: event,
                    // Per-session attendance is only meaningful to a student
                    // who's actually in the program. Hosts manage sessions
                    // elsewhere, and a non-registered viewer has nothing to
                    // report yet.
                    showSessionAttendance:
                        !canManage &&
                        event.registrationStatus !=
                            EventRegistrationStatus.notRegistered,
                  ),
                  if (canManage) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EventCreateEditScreen(event: event),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(l10n.eventEditAction),
                    ),
                    const SizedBox(height: 10),
                    if (event.eventKind == EventKind.program)
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProgramDetailScreen(event: event),
                          ),
                        ),
                        icon: const Icon(Icons.event_repeat_outlined, size: 18),
                        label: Text(l10n.programManageSessionsAction),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EventQrDisplayScreen(
                                    title: event.localizedTitle(
                                      Localizations.localeOf(
                                        context,
                                      ).languageCode,
                                    ),
                                    eventId: event.id,
                                    initialEnabled: event.qrEnabled,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.qr_code_2, size: 18),
                              label: Text(l10n.eventShowQrAction),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EventStatisticsScreen(eventId: event.id),
                                ),
                              ),
                              icon: const Icon(Icons.groups_outlined, size: 18),
                              label: Text(l10n.registrantsTitle),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context, ref, l10n),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.destructive,
                        side: BorderSide(
                          color: AppColors.destructive.withValues(alpha: 0.4),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(l10n.deleteEventTitle),
                    ),
                  ],
                  // End of the page, not the sticky bar. Scan stays pinned;
                  // cancel scrolls with the event.
                  if (_canCancelRegistration(event)) ...[
                    const SizedBox(height: 24),
                    _CancelRegistrationButton(onPressed: () => _cancel(context, ref, l10n)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      // The inset sits outside the card, so the action never paints over
      // the system navigation buttons on phones that still have them.
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Material(
          color: AppColors.card,
          elevation: 12,
          shadowColor: AppColors.foreground.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: _CtaSection(
              event: event,
              capacity: capacity,
              busy: busy,
              onRegister: () => _register(context, ref, l10n),
              onScanToCheckIn: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EventAttendanceScanScreen(event: event),
                ),
              ),
              onViewSessions: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProgramDetailScreen(event: event),
                ),
              ),
              awaitingProgramApproval: awaitingProgramApproval,
              acceptedOntoProgram: acceptedOntoProgram,
              l10n: l10n,
            ),
          ),
        ),
      ),
    );
  }
}

/// The register button in its "event full" state — same size and shape as
/// [PrimaryGradientButton] so the registration area doesn't jump, but grey,
/// flat and inert instead of the gradient CTA.
/// The "request sent, awaiting approval" status for a program.
///
/// A disabled button rather than a banner so it occupies exactly the slot the
/// Register button did — the student's eye lands where it already was — and a
/// pastel pink that reads clearly as "not actionable" against the gradient of
/// a live Register button.
class _PendingApprovalStatus extends StatelessWidget {
  const _PendingApprovalStatus({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: false,
      label: label,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.pink.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.pink),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.hourglass_top_outlined,
              size: 18,
              color: AppColors.foreground,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisabledRegisterButton extends StatelessWidget {
  const _DisabledRegisterButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: false,
      label: label,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedForeground,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.background});

  final String text;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CancelRegistrationButton extends StatelessWidget {
  const _CancelRegistrationButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.destructive,
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(
          color: AppColors.destructive.withValues(alpha: 0.45),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      child: Text(l10n.eventCancelAction),
    );
  }
}

class _CtaSection extends StatelessWidget {
  const _CtaSection({
    required this.event,
    required this.capacity,
    required this.busy,
    required this.onRegister,
    required this.onScanToCheckIn,
    required this.onViewSessions,
    required this.awaitingProgramApproval,
    required this.acceptedOntoProgram,
    required this.l10n,
  });

  final CampusEvent event;
  final EventCapacity capacity;
  final bool busy;

  /// True when the viewer has been accepted onto this program — the backend
  /// holds an acceptance row for them. Distinguishes "accepted" from the
  /// plain "registered" banner, which is the state before an organizer acts.
  final bool acceptedOntoProgram;

  /// True when the viewer holds a registration for a program but has not yet
  /// been accepted onto it. Driven by `myAcceptedProgramIdsProvider` — the
  /// backend's acceptance list — not by the tap that registered them, so it
  /// survives a restart and flips the moment an admin accepts.
  final bool awaitingProgramApproval;
  final VoidCallback onRegister;
  final VoidCallback onScanToCheckIn;
  final VoidCallback onViewSessions;
  final AppLocalizations l10n;

  bool get _isProgram => event.eventKind == EventKind.program;

  /// A program's CTA. Attendance there is per session, so this reports how
  /// many sessions are done and always keeps the sessions list — the only
  /// place the remaining sessions can be scanned — one tap away. Before the
  /// per-session counting landed, the first scan flipped the whole program to
  /// "attended" and this button was replaced by a bare banner.
  Widget _programCta() {
    final progress = event.sessionAttendance;
    final complete =
        event.registrationStatus == EventRegistrationStatus.attended;
    final message = complete
        ? l10n.programAttendedAllSessions
        : (progress != null && progress.hasAny)
        ? l10n.programAttendanceProgress(progress.attended, progress.total)
        // Reaching here on a program means the viewer is registered AND not
        // awaiting approval — i.e. an organizer has accepted them. Say that,
        // rather than "you registered", which is the step before and is what
        // the pending status already covers.
        : acceptedOntoProgram
        ? l10n.programAcceptedStatus
        : l10n.eventRegisteredLabel;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InlineBanner(message: message, tone: BannerTone.success),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onViewSessions,
          icon: const Icon(Icons.event_note_outlined, size: 18),
          label: Text(l10n.programViewSessionsAction),
        ),
      ],
    );
  }

  Widget _scanButton() {
    return OutlinedButton.icon(
      onPressed: onScanToCheckIn,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
      icon: const Icon(Icons.qr_code_scanner, size: 18),
      label: Text(l10n.eventScanToCheckInAction),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isProgram &&
        event.registrationStatus != EventRegistrationStatus.notRegistered) {
      // Applied, not yet taken on. Shown instead of the normal program CTA so
      // the student sees their request landed rather than an unchanged
      // Register button — and can't send a second one.
      if (awaitingProgramApproval) {
        return _PendingApprovalStatus(label: l10n.programPendingApprovalStatus);
      }
      return _programCta();
    }
    switch (event.registrationStatus) {
      case EventRegistrationStatus.attended:
        return InlineBanner(
          message: l10n.eventAttendedLabel,
          tone: BannerTone.success,
        );
      case EventRegistrationStatus.registered:
        return _scanButton();
      case EventRegistrationStatus.notRegistered:
        if (event.hasEnded) {
          return InlineBanner(
            message: l10n.eventEndedLabel,
            tone: BannerTone.neutral,
          );
        }
        // Registration closed by hand, which overrides capacity: a closed
        // event may still have places, or no cap at all. Checked before
        // `isFull` so the two can't disagree about which notice to show.
        // `register_for_event` refuses these server-side too (migration
        // 0070), so this is the honest face of a rule already enforced.
        if (event.registrationClosed) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DisabledRegisterButton(label: l10n.eventFullAction),
              const SizedBox(height: 10),
              InlineBanner(
                message: l10n.eventFullNotice,
                tone: BannerTone.neutral,
              ),
            ],
          );
        }
        // No places left: say so here instead of letting the student tap a
        // live-looking button and reading the refusal back as an error. The
        // state is derived fresh from the count each build, so a cancellation
        // or a raised capacity restores the button on the next load.
        if (capacity.isFull) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DisabledRegisterButton(label: l10n.eventFullAction),
              const SizedBox(height: 10),
              InlineBanner(
                message: l10n.eventFullNotice,
                tone: BannerTone.neutral,
              ),
            ],
          );
        }
        return PrimaryGradientButton(
          label: l10n.eventRegisterAction,
          loading: busy,
          onPressed: onRegister,
        );
    }
  }
}
