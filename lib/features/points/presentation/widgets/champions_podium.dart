import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../domain/entities/leaderboard_entry.dart';

/// Per-rank podium colours (card fill + badge/trophy accent).
class _PodiumPalette {
  const _PodiumPalette(this.fill, this.accent);
  final Color fill;
  final Color accent;

  static _PodiumPalette of(int rank) => switch (rank) {
    1 => const _PodiumPalette(Color(0xFFFFECB3), Color(0xFFF5A623)), // gold
    2 => const _PodiumPalette(Color(0xFFEDEDF2), Color(0xFF9AA0A6)), // silver
    _ => const _PodiumPalette(Color(0xFFFFD9BC), Color(0xFFF08A3C)), // bronze
  };
}

/// Top-3 podium. Children are listed [3rd, 1st, 2nd] — in RTL that renders
/// as 3rd on the right, 1st in the center, 2nd on the left, matching the
/// reference (and mirrors correctly to 3rd-left/1st-center/2nd-right in LTR).
///
/// Handles 1, 2, or 3 entries: early in the month (or with a small cohort)
/// there may be fewer than three ranked students, and the podium should still
/// show whoever's on top rather than disappear entirely.
class ChampionsPodium extends StatelessWidget {
  const ChampionsPodium({super.key, required this.top3});

  /// 1 to 3 entries, ranks 1-N in order.
  final List<LeaderboardEntry> top3;

  @override
  Widget build(BuildContext context) {
    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (third != null) ...[
          Expanded(child: _PodiumCard(entry: third, rank: 3)),
          const SizedBox(width: 10),
        ],
        if (first != null)
          Expanded(child: _PodiumCard(entry: first, rank: 1, tall: true)),
        if (second != null) ...[
          const SizedBox(width: 10),
          Expanded(child: _PodiumCard(entry: second, rank: 2)),
        ],
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.entry,
    required this.rank,
    this.tall = false,
  });

  final LeaderboardEntry entry;
  final int rank;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final palette = _PodiumPalette.of(rank);
    final avatarSize = tall ? 60.0 : 46.0;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          // Leaves head-room for the rank badge that overlaps the top edge.
          margin: const EdgeInsets.only(top: 14),
          padding: EdgeInsets.fromLTRB(8, tall ? 22 : 18, 8, tall ? 16 : 12),
          decoration: BoxDecoration(
            color: palette.fill,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InitialsAvatar(
                initials: entry.initials,
                hue: entry.avatarHue,
                imageUrl: entry.avatarUrl,
                size: avatarSize,
              ),
              const SizedBox(height: 8),
              Text(
                entry.fullName.isEmpty ? '—' : entry.fullName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: tall ? 13 : 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${entry.points} ✨',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: tall ? 14 : 12,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 6),
              Icon(
                Icons.emoji_events,
                color: palette.accent,
                size: tall ? 26 : 20,
              ),
            ],
          ),
        ),
        // Numbered rank badge, straddling the card's top edge.
        Positioned(
          top: 0,
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.accent,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 2),
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
