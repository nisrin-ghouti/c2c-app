import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/champions_announcement.dart';
import 'medal_emoji.dart';

/// Mandatory, OK-only personal "you were a top-3 Champion" popup — shown
/// only to last month's top 3 finishers, in addition to (and before) the
/// general `MonthAnnouncementDialog`.
class WinnerBonusDialog extends StatelessWidget {
  const WinnerBonusDialog({super.key, required this.announcement});

  final ChampionsAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rank = announcement.myRank!;
    final points = announcement.myPoints ?? 0;
    final bonus = announcement.myBonus ?? 0;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(medalFor(rank), style: const TextStyle(fontSize: 40)),
        titlePadding: const EdgeInsets.only(top: 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.winnerBonusTitle(rank),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(l10n.winnerBonusPoints(points), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.winnerBonusAmount(bonus),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.winnerBonusOk),
            ),
          ),
        ],
      ),
    );
  }
}
