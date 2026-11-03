import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/match_candidate.dart';

class MatchCandidateCard extends StatelessWidget {
  const MatchCandidateCard({
    super.key,
    required this.candidate,
    required this.onViewProfile,
    required this.onMessage,
    this.compatibilityBadgeWrapper,
    this.viewProfileButtonWrapper,
    this.messageButtonWrapper,
  });

  final MatchCandidate candidate;
  final VoidCallback onViewProfile;
  final VoidCallback onMessage;

  /// Optionally wraps the compatibility badge — lets the list screen
  /// spotlight it (on the first card only) for the first-time "what does
  /// this percentage mean" demo. The badge itself is a plain (non-Positioned)
  /// Stack child — see the comment at its call site for why that matters.
  final Widget Function(Widget child)? compatibilityBadgeWrapper;

  /// Optionally wraps the "View Profile" button — lets the list screen
  /// spotlight it (on the first card only) as the tap-gated next step of the
  /// guided matching walkthrough.
  final Widget Function(Widget child)? viewProfileButtonWrapper;

  /// Optionally wraps the Chat button for the main guided tour.
  final Widget Function(Widget child)? messageButtonWrapper;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subtitleParts = [
      if (candidate.fieldOfStudy != null && candidate.fieldOfStudy!.isNotEmpty)
        candidate.fieldOfStudy!,
      if (candidate.year != null) l10n.matchesYearInline(candidate.year!),
    ];
    final tags = candidate.mergedInterests.toList();
    final avatarColor = HSLColor.fromAHSL(
      1,
      candidate.avatarHue.toDouble(),
      0.55,
      0.68,
    ).toColor();
    final hasPhoto =
        candidate.avatarUrl != null && candidate.avatarUrl!.isNotEmpty;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A big photo header (falling back to a color block with the
          // student's initials when there's no uploaded photo) with the
          // compatibility badge overlaid on top of it. The photo is the
          // `Positioned.fill` layer and the badge is a plain (non-Positioned)
          // Stack child placed via `alignment` + padding instead — keeping
          // the showcase target (the badge) out of a `Positioned` wrapper is
          // what actually fixed showcaseview's mismeasurement; wrapping the
          // whole header instead (an earlier attempt) worked around it by
          // over-highlighting rather than fixing the target itself.
          SizedBox(
            height: 170,
            width: double.infinity,
            child: Stack(
              alignment: AlignmentDirectional.topEnd,
              children: [
                Positioned.fill(
                  child: hasPhoto
                      ? Image.network(candidate.avatarUrl!, fit: BoxFit.cover)
                      : ColoredBox(
                          color: avatarColor,
                          child: Center(
                            child: Text(
                              candidate.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 40,
                              ),
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 10, end: 10),
                  child: (compatibilityBadgeWrapper ?? (child) => child)(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.matchesCompatibilityBadge(
                          candidate.compatibilityPercent,
                        ),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  candidate.fullName.isEmpty ? '—' : candidate.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (subtitleParts.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitleParts.join(' • '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in tags)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (candidate.bio != null && candidate.bio!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.track_changes,
                        size: 16,
                        color: AppColors.primaryStrong,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          candidate.bio!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Logical order matches reference: "view profile" first
                    // (start -> right in RTL), "message" second (end -> left).
                    Expanded(
                      child: (viewProfileButtonWrapper ?? (child) => child)(
                        OutlinedButton(
                          onPressed: onViewProfile,
                          child: Text(
                            l10n.profileViewAction,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: (messageButtonWrapper ?? (child) => child)(
                        FilledButton(
                          onPressed: onMessage,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: Text(
                            l10n.matchesSendHelloAction,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
