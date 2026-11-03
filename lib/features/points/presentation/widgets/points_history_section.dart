import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/points_controller.dart';
import 'reason_label.dart';

class PointsHistorySection extends ConsumerWidget {
  const PointsHistorySection({super.key});

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final transactionsAsync = ref.watch(recentTransactionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.pointsHistoryTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 10),
        transactionsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => Text(
            l10n.pointsHistoryLoadError,
            style: const TextStyle(color: AppColors.mutedForeground),
          ),
          data: (transactions) {
            if (transactions.isEmpty) {
              return Text(
                l10n.pointsHistoryEmpty,
                style: const TextStyle(color: AppColors.mutedForeground),
              );
            }
            return Column(
              children: [
                for (final entry in transactions)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reasonLabel(l10n, entry.reason),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${_twoDigits(entry.createdAt.hour)}:${_twoDigits(entry.createdAt.minute)}, '
                                '${_twoDigits(entry.createdAt.day)}.${_twoDigits(entry.createdAt.month)}.${entry.createdAt.year}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${entry.amount > 0 ? '+' : ''}${entry.amount}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: entry.amount >= 0
                                ? AppColors.success
                                : AppColors.destructive,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
