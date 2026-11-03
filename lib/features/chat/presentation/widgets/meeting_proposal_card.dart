import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/proposal_action_result.dart';
import '../../domain/entities/meeting_proposal.dart';
import '../../../matches/presentation/providers/scheduled_meeting_providers.dart';
import '../../../matches/presentation/screens/meeting_screen.dart';
import '../providers/chat_providers.dart';

/// Inline card rendered in place of a `meetingProposal`-type chat message —
/// shows the proposed time/location/notes, with Accept/Decline for the
/// recipient or a "waiting" state for the proposer.
class MeetingProposalCard extends ConsumerStatefulWidget {
  const MeetingProposalCard({
    super.key,
    required this.proposalId,
    required this.viewerId,
    required this.otherName,
  });

  final String proposalId;
  final String viewerId;
  final String otherName;

  @override
  ConsumerState<MeetingProposalCard> createState() =>
      _MeetingProposalCardState();
}

class _MeetingProposalCardState extends ConsumerState<MeetingProposalCard> {
  /// True from the moment Accept/Decline is tapped until the RPC answers.
  ///
  /// Both buttons go dead while it's set, so a double tap can't send a second
  /// `respond_to_meeting_proposal` — the second call would land on an
  /// already-answered proposal and come back `already_responded`, which read
  /// as the button having failed.
  bool _responding = false;

  String _formatDateTime(DateTime utc) {
    // toLocal(): these arrive as UTC, and formatting the raw fields
    // would print UTC wall-clock time to a student in campus time.
    final dt = utc.toLocal();
    final d =
        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    final t =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d · $t';
  }

  Future<void> _respond(MeetingProposal proposal, bool accept) async {
    if (_responding) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _responding = true);

    RespondProposalResult result;
    try {
      result = await ref.read(respondToProposalProvider)(
        proposal.id,
        accept: accept,
      );
    } catch (e) {
      // A throw here (network, or the RPC raising) used to disappear into an
      // unhandled future: the button looked like it had done nothing at all.
      debugPrint('MeetingProposalCard: respond failed: $e');
      result = RespondProposalResult.unknown;
    }
    if (!mounted) return;
    setState(() => _responding = false);

    // The card's own status comes from `meetingProposalProvider`, a realtime
    // stream, so it updates on the row write for BOTH participants and needs
    // no invalidation here. The accepted meeting also shows up in My Events,
    // which is a plain fetch — that one does.
    if (result == RespondProposalResult.ok) {
      ref.invalidate(myMeetingsProvider);
      return;
    }

    // Every non-ok outcome says something. A daily limit is a refusal rather
    // than a failure, and the rest are genuine errors, but leaving any of
    // them silent is what made "Accept doesn't work" indistinguishable from
    // "Accept did nothing".
    final message = switch (result) {
      RespondProposalResult.ok => null,
      RespondProposalResult.dailyPairLimit =>
        l10n.proposeMeetingErrorSameStudentToday,
      RespondProposalResult.dailyPartnerLimitSelf =>
        l10n.proposeMeetingErrorDailyLimitSelf,
      RespondProposalResult.dailyPartnerLimitOther =>
        l10n.proposeMeetingErrorDailyLimitOther,
      RespondProposalResult.alreadyResponded =>
        l10n.proposeMeetingAlreadyResponded,
      RespondProposalResult.forbidden ||
      RespondProposalResult.notFound ||
      RespondProposalResult.unknown => l10n.proposeMeetingRespondError,
    };
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final viewerId = widget.viewerId;
    final proposalAsync = ref.watch(
      meetingProposalProvider(widget.proposalId),
    );

    return proposalAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (proposal) {
        if (proposal == null) return const SizedBox.shrink();
        final isRecipient = proposal.proposedBy != viewerId;

        Widget statusArea;
        switch (proposal.status) {
          case MeetingProposalStatus.pending:
            statusArea = isRecipient
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _responding
                              ? null
                              : () => _respond(proposal, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.destructive,
                            side: BorderSide(
                              color: AppColors.destructive.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: Text(l10n.proposeMeetingDecline),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: _responding
                              ? null
                              : () => _respond(proposal, true),
                          child: Text(l10n.proposeMeetingAccept),
                        ),
                      ),
                    ],
                  )
                : Text(
                    l10n.proposeMeetingWaiting,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedForeground,
                    ),
                  );
          case MeetingProposalStatus.accepted:
            // Accepted meetings are actionable, but the QR handshake button
            // only appears during the scheduled window — otherwise it just
            // opens onto a screen with nothing to do yet (or not anymore).
            final now = DateTime.now();
            final windowOpen =
                now.isAfter(proposal.scheduledAt) &&
                now.isBefore(proposal.endsAt);
            statusArea = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusBadge(
                  label: l10n.proposeMeetingAccepted,
                  color: AppColors.success,
                ),
                const SizedBox(height: 8),
                if (windowOpen)
                  FilledButton.icon(
                    icon: const Icon(Icons.qr_code_2, size: 18),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MeetingScreen(
                          proposalId: proposal.id,
                          otherName: widget.otherName,
                          scheduledAt: proposal.scheduledAt,
                          endsAt: proposal.endsAt,
                        ),
                      ),
                    ),
                    label: Text(l10n.meetingOpenAction),
                  )
                else
                  Text(
                    now.isBefore(proposal.scheduledAt)
                        ? l10n.meetingNotYetOpen
                        : l10n.meetingWindowEnded,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedForeground,
                    ),
                  ),
              ],
            );
          case MeetingProposalStatus.declined:
            statusArea = _StatusBadge(
              label: l10n.proposeMeetingDeclined,
              color: AppColors.destructive,
            );
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(maxWidth: 280),
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
                  Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.proposeMeetingCardTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatDateTime(proposal.scheduledAt),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (proposal.location != null && proposal.location!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    proposal.location!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ),
              if (proposal.notes != null && proposal.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    proposal.notes!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              const SizedBox(height: 10),
              statusArea,
            ],
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
