import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../onboarding/domain/entities/demo_key.dart';
import '../../../onboarding/presentation/controllers/demo_flags_controller.dart';
import '../../../onboarding/presentation/widgets/contextual_showcase.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../controllers/points_controller.dart';
import 'champions_leaderboard_list.dart';
import 'champions_podium.dart';
import 'my_rank_card.dart';

class MonthlyChampionsContent extends ConsumerWidget {
  MonthlyChampionsContent({super.key});

  /// Stable for the lifetime of this widget instance.
  final _rankCardShowcaseKey = GlobalKey();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dataAsync = ref.watch(monthlyChampionsDataProvider);
    final viewerId = ref.watch(currentAuthSessionProvider).userId ?? '';

    return dataAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(l10n.championsLoadError)),
      ),
      data: (data) {
        final leaderboard = data.leaderboard;
        if (leaderboard.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                l10n.championsEmpty,
                style: const TextStyle(color: AppColors.mutedForeground),
              ),
            ),
          );
        }

        final top3 = leaderboard.take(3).toList();
        final LeaderboardEntry? viewerEntry = leaderboard
            .cast<LeaderboardEntry?>()
            .firstWhere((e) => e!.userId == viewerId, orElse: () => null);

        final showChampionsDemo = !ref.watch(
          hasSeenDemoProvider(DemoKey.champions),
        );
        if (showChampionsDemo) {
          startContextualDemoOnce(
            context: context,
            ref: ref,
            key: DemoKey.champions,
            showcaseKeys: [_rankCardShowcaseKey],
          );
        }

        final rankCard = MyRankCard(
          myRank: data.myRank,
          myName: viewerEntry?.fullName ?? '',
          myAvatarHue: viewerEntry?.avatarHue ?? 220,
        );
        final myRankCard = showChampionsDemo
            ? ContextualShowcase(
                showcaseKey: _rankCardShowcaseKey,
                title: l10n.demoChampionsTitle,
                description: l10n.demoChampionsMessage,
                child: rankCard,
              )
            : rankCard;
        final podium = top3.isEmpty ? null : ChampionsPodium(top3: top3);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ChampionsHero(l10n: l10n),
            const SizedBox(height: 16),
            // Reference layout: rank card beside the podium where there's room,
            // stacked on narrow phones so neither gets squeezed.
            LayoutBuilder(
              builder: (context, constraints) {
                if (podium == null) return myRankCard;
                if (constraints.maxWidth >= 480) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: myRankCard),
                      const SizedBox(width: 12),
                      Expanded(flex: 6, child: podium),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [podium, const SizedBox(height: 16), myRankCard],
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              l10n.championsListTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 10),
            ChampionsLeaderboardList(entries: leaderboard, viewerId: viewerId),
          ],
        );
      },
    );
  }
}

/// The gradient header: "Champions {Month} {Year}" with a trophy, plus a small
/// "updated monthly" status pill. The month name comes from
/// [MaterialLocalizations] so it's localized (en/he/ar) with no extra setup.
class _ChampionsHero extends StatelessWidget {
  const _ChampionsHero({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final monthYear = MaterialLocalizations.of(
      context,
    ).formatMonthYear(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.championsHeroLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.foreground,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 8, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      l10n.championsUpdateFrequency,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: Color(0xFFF5A623),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${l10n.championsHeroMonthPrefix} $monthYear',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Rewards line for the top three, per the PDF: the system awards
          // these bonus points to 1st/2nd/3rd at each monthly reset. Values are
          // the spec's fixed amounts — see [_championsBonus*] below.
          Text(
            l10n.championsRewardsTitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _RewardChip(
                label: l10n.championsRewardFirst(_championsBonusFirst),
              ),
              _RewardChip(
                label: l10n.championsRewardSecond(_championsBonusSecond),
              ),
              _RewardChip(
                label: l10n.championsRewardThird(_championsBonusThird),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// The monthly bonus awarded to the top three, fixed by the spec. These mirror
// what the server grants on the monthly reset; they live here only for
// display. If the backend amounts ever change, update both.
const int _championsBonusFirst = 100;
const int _championsBonusSecond = 60;
const int _championsBonusThird = 30;

class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
