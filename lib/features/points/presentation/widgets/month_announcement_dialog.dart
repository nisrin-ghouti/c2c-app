import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../domain/entities/champions_announcement.dart';
import 'medal_emoji.dart';

/// Mandatory, OK-only "last month's Champions are in" popup — shown to
/// every student once per finalized month, regardless of their own result.
/// Blocked from dismissing via back button (`PopScope(canPop: false)`),
/// same "advance-only" rule as the onboarding tutorial.
class MonthAnnouncementDialog extends StatelessWidget {
  const MonthAnnouncementDialog({super.key, required this.announcement});

  final ChampionsAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final monthLabel =
        '${announcement.month.month.toString().padLeft(2, '0')}.${announcement.month.year}';

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l10n.monthAnnouncementTitle(monthLabel)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.monthAnnouncementBody),
              const SizedBox(height: 16),
              for (final result in announcement.top3)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Text(
                        medalFor(result.rank),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      InitialsAvatar(
                        initials: result.initials,
                        hue: result.avatarHue,
                        imageUrl: result.avatarUrl,
                        size: 36,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          result.fullName.isEmpty ? '—' : result.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        '${result.points} ✨',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.monthAnnouncementOk),
          ),
        ],
      ),
    );
  }
}
