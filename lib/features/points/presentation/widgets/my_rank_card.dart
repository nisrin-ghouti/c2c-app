import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/initials.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../domain/entities/my_monthly_rank.dart';

class MyRankCard extends StatelessWidget {
  const MyRankCard({
    super.key,
    required this.myRank,
    required this.myName,
    required this.myAvatarHue,
  });

  final MyMonthlyRank myRank;
  final String myName;
  final int myAvatarHue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (myRank.status == MyMonthlyRankStatus.unranked) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          l10n.championsUnranked,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.mutedForeground),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.championsMyRankLabel,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '#${myRank.rank}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(width: 10),
              InitialsAvatar(
                initials: initialsOf(myName),
                hue: myAvatarHue,
                size: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      myName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      l10n.championsMyPointsLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${myRank.points} ✨',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (myRank.aboveName != null &&
              myRank.gap != null &&
              myRank.gap! > 0) ...[
            const SizedBox(height: 10),
            Text(
              l10n.championsGapLabel(myRank.gap!, myRank.aboveName!),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
