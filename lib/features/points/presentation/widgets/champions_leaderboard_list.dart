import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../domain/entities/leaderboard_entry.dart';

/// The full month leaderboard as a single table card: a header row
/// (rank / name / points) over one row per student, the viewer's own row
/// tinted so they can spot themselves. Replaces the old list of separate
/// bordered pills to match the reference design.
class ChampionsLeaderboardList extends StatelessWidget {
  const ChampionsLeaderboardList({
    super.key,
    required this.entries,
    required this.viewerId,
  });

  final List<LeaderboardEntry> entries;
  final String viewerId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _HeaderRow(l10n: l10n),
          const Divider(height: 1, color: AppColors.border),
          for (var i = 0; i < entries.length; i++) ...[
            _EntryRow(
              entry: entries[i],
              isViewer: entries[i].userId == viewerId,
            ),
            if (i < entries.length - 1)
              const Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: AppColors.border,
              ),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppColors.mutedForeground,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(l10n.championsTableRankCol, style: style),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.championsTableNameCol, style: style)),
          Text(l10n.championsTablePointsCol, style: style),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.isViewer});

  final LeaderboardEntry entry;
  final bool isViewer;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isViewer
          ? AppColors.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: isViewer ? AppColors.primary : AppColors.foreground,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.fullName.isEmpty ? '—' : entry.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isViewer ? FontWeight.w800 : FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InitialsAvatar(
            initials: entry.initials,
            hue: entry.avatarHue,
            imageUrl: entry.avatarUrl,
            size: 30,
          ),
          const SizedBox(width: 10),
          Text(
            '${entry.points} ✨',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
