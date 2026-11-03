import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/inline_banner.dart';
import '../../../admin/domain/entities/option_list_type.dart';
import '../../../admin/presentation/providers/option_label_providers.dart';
import '../../domain/entities/campus_event.dart';

/// Border/message tone for the "My Events" screen's color-coded cards —
/// `null` (the default, used everywhere else) renders exactly as the
/// original browse-list card always has.
enum CampusEventCardTone { neutral, success, destructive }

class CampusEventCard extends StatelessWidget {
  const CampusEventCard({
    super.key,
    required this.event,
    required this.canManage,
    required this.registerBusy,
    required this.onRegister,
    this.isFull = false,
    this.awaitingApproval = false,
    required this.onDelete,
    required this.onViewRegistrants,
    this.onTap,
    this.onCheckIn,
    this.onCancel,
    this.tone,
    this.statusMessage,
  });

  final CampusEvent event;
  final bool canManage;
  final bool registerBusy;
  final VoidCallback onRegister;

  /// No places left — the Register button goes grey and inert, matching the
  /// detail screen. Defaults to false so a caller that doesn't know the
  /// count (the approval previews) behaves exactly as before.
  final bool isFull;

  /// True for a program the viewer has applied to but has not been accepted
  /// onto. The card must say that rather than "Registered" — the list and the
  /// detail screen cannot disagree about whether a place has been granted.
  final bool awaitingApproval;
  final VoidCallback onDelete;
  final VoidCallback onViewRegistrants;

  /// Opens the event's full-profile screen. Optional so the approval-queue
  /// card (Slice 2) can reuse this widget without a tap-through.
  final VoidCallback? onTap;

  /// Opens check-in after registration. Replaces the Register button.
  final VoidCallback? onCheckIn;

  /// Withdraws a registration that has not started. Shown under check-in,
  /// not in its place.
  final VoidCallback? onCancel;

  /// My-Events-only: colors the border and, combined with [statusMessage],
  /// appends the exact spec copy ("Great job!...", "We missed you!...",
  /// "We're looking forward to seeing you!") beneath the card.
  final CampusEventCardTone? tone;
  final String? statusMessage;

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  Color get _borderColor => switch (tone) {
    CampusEventCardTone.success => AppColors.success,
    CampusEventCardTone.destructive => AppColors.destructive,
    CampusEventCardTone.neutral || null => AppColors.border,
  };

  BannerTone get _bannerTone => switch (tone) {
    CampusEventCardTone.success => BannerTone.success,
    CampusEventCardTone.destructive => BannerTone.error,
    CampusEventCardTone.neutral || null => BannerTone.neutral,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = event.localizedTitle(languageCode);
    final location = event.localizedLocation(languageCode);
    final date =
        '${_twoDigits(event.startsAt.day)}.${_twoDigits(event.startsAt.month)}, '
        '${_twoDigits(event.startsAt.hour)}:${_twoDigits(event.startsAt.minute)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor, width: tone != null ? 1.5 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  // Logical order: thumbnail first ("start" -> right in
                  // RTL, matching the reference screenshot), management
                  // icons last ("end" -> left).
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child:
                          event.imageUrl != null && event.imageUrl!.isNotEmpty
                          ? Image.network(
                              event.imageUrl!,
                              width: 84,
                              height: 84,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 84,
                                height: 84,
                                color: AppColors.surfaceMuted,
                                alignment: Alignment.center,
                                child: const Text(
                                  '🎉',
                                  style: TextStyle(fontSize: 28),
                                ),
                              ),
                            )
                          : Container(
                              width: 84,
                              height: 84,
                              color: AppColors.surfaceMuted,
                              alignment: Alignment.center,
                              child: const Text(
                                '🎉',
                                style: TextStyle(fontSize: 28),
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (event.category != null &&
                              event.category!.isNotEmpty)
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.peach.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: OptionLabelText(
                                  type: OptionListType.eventCategory,
                                  value: event.category,
                                  style: const TextStyle(fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (location != null && location.isNotEmpty)
                            _MetaRow(
                              icon: Icons.location_on_outlined,
                              text: location,
                            ),
                          _MetaRow(
                            icon: Icons.calendar_today_outlined,
                            text: date,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.mint.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  l10n.eventUpcomingTag,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                              Text(
                                l10n.eventPointsLabel(event.points),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (canManage) ...[
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          _IconAction(
                            icon: Icons.delete_outline,
                            color: AppColors.destructive,
                            onTap: onDelete,
                          ),
                          const SizedBox(height: 6),
                          _IconAction(
                            icon: Icons.groups_outlined,
                            color: AppColors.primary,
                            onTap: onViewRegistrants,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _RegistrationButton(
                  event: event,
                  status: event.registrationStatus,
                  busy: registerBusy,
                  isFull: isFull,
                  awaitingApproval: awaitingApproval,
                  onRegister: onRegister,
                  onCheckIn: onCheckIn,
                  onCancel: onCancel,
                  l10n: l10n,
                ),
                if (statusMessage != null) ...[
                  const SizedBox(height: 10),
                  InlineBanner(message: statusMessage!, tone: _bannerTone),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.mutedForeground),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
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
    );
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

class _RegistrationButton extends StatelessWidget {
  const _RegistrationButton({
    required this.event,
    required this.status,
    required this.busy,
    required this.isFull,
    this.awaitingApproval = false,
    required this.onRegister,
    required this.onCheckIn,
    required this.onCancel,
    required this.l10n,
  });

  final CampusEvent event;
  final EventRegistrationStatus status;
  final bool busy;
  final bool isFull;
  final bool awaitingApproval;
  final VoidCallback onRegister;
  final VoidCallback? onCheckIn;
  final VoidCallback? onCancel;
  final AppLocalizations l10n;

  /// Same gate as the event screen: cancel stays available until the event
  /// starts or a program session has already been attended.
  bool get _canCancel =>
      onCancel != null &&
      !event.hasStarted &&
      event.sessionAttendance?.hasAny != true;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case EventRegistrationStatus.attended:
        return _StatusBar(
          label: l10n.eventAttendedLabel,
          color: AppColors.success,
          icon: Icons.check_circle,
        );
      case EventRegistrationStatus.registered:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (onCheckIn != null)
              _ActionButton(
                label: l10n.eventScanToCheckInAction,
                filled: true,
                onPressed: onCheckIn,
              ),
            if (_canCancel) ...[
              if (onCheckIn != null) const SizedBox(height: 8),
              _CancelRegistrationButton(onPressed: onCancel),
            ],
            if (onCheckIn == null && !_canCancel)
              _StatusBar(
                label: awaitingApproval
                    ? l10n.eventPendingApprovalLabel
                    : l10n.eventRegisteredLabel,
                color: awaitingApproval ? AppColors.pink : AppColors.success,
                icon: awaitingApproval
                    ? Icons.hourglass_top
                    : Icons.check_circle,
              ),
          ],
        );
      case EventRegistrationStatus.notRegistered:
        // The long "registration will reopen here" notice belongs on the
        // detail screen, which has room for it; the card just stops offering
        // a tap that the server would refuse.
        return _ActionButton(
          label: isFull ? l10n.eventFullAction : l10n.eventRegisterAction,
          busy: busy,
          filled: true,
          enabled: !busy && !isFull,
          onPressed: onRegister,
        );
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.filled,
    this.busy = false,
    this.enabled = true,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool busy;
  final bool enabled;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final foreground = destructive
        ? AppColors.destructive
        : filled
        ? AppColors.secondaryForeground
        : AppColors.secondary;
    final background = filled
        ? (enabled ? AppColors.secondary : AppColors.muted)
        : Colors.transparent;

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: filled
          ? FilledButton(
              onPressed: enabled ? onPressed : null,
              style: FilledButton.styleFrom(
                backgroundColor: background,
                foregroundColor: enabled
                    ? foreground
                    : AppColors.mutedForeground,
                disabledBackgroundColor: AppColors.muted,
                disabledForegroundColor: AppColors.mutedForeground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(label),
            )
          : OutlinedButton(
              onPressed: enabled ? onPressed : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: foreground,
                side: BorderSide(
                  color: destructive
                      ? AppColors.destructive.withValues(alpha: 0.45)
                      : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text(label),
            ),
    );
  }
}

class _CancelRegistrationButton extends StatelessWidget {
  const _CancelRegistrationButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      label: AppLocalizations.of(context).eventCancelAction,
      onPressed: onPressed,
      filled: false,
      destructive: true,
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

