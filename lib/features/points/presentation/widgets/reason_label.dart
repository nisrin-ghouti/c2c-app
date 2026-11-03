import '../../../../core/l10n/generated/app_localizations.dart';

/// Maps a `point_transactions.reason` ledger value to localized display
/// text. Kept as a pure mapping function (not baked into the entity) so the
/// domain layer stays free of `AppLocalizations`.
String reasonLabel(AppLocalizations l10n, String reason) {
  return switch (reason) {
    'event_attendance' => l10n.reasonEventAttendance,
    'meeting_first' => l10n.reasonMeetingFirst,
    'meeting_second' => l10n.reasonMeetingSecond,
    'meeting_repeat' => l10n.reasonMeetingRepeat,
    'group_meeting' => l10n.reasonGroupMeeting,
    'monthly_prize' => l10n.reasonMonthlyPrize,
    'benefit_redeem' => l10n.reasonBenefitRedeem,
    _ => l10n.reasonGeneric,
  };
}
