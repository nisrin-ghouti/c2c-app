import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/app_header_bar.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../../onboarding/presentation/controllers/guided_matching_tour_controller.dart';
import '../providers/scanning_tab_provider.dart';
import '../widgets/how_to_earn_panel.dart';
import '../widgets/monthly_champions_content.dart';
import '../widgets/points_history_section.dart';
import '../widgets/scan_card.dart';

/// The "Scanning" bottom-nav tab: scan/enter a meeting or event code and see
/// your points history, or check this month's leaderboard — same page,
/// switched by the segmented toggle (matches the reference design).
///
/// A [scanningTabRequestProvider] request (set by the Home "Monthly Champions"
/// button) overrides the remembered tab, so that button always lands on
/// Champions regardless of what was open last.
class ScanningScreen extends ConsumerStatefulWidget {
  const ScanningScreen({super.key});

  @override
  ConsumerState<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends ConsumerState<ScanningScreen> {
  ScanningTab _tab = ScanningTab.scan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    dismissPushedRoutesOnTourReplay(context, ref);

    final mainScanTour =
        ref.watch(matchingTourStepProvider) ==
        MatchingTourStep.awaitingScanContent;

    // The first-run tour must always land on the Scan content, even if this
    // persistent branch was previously left on Monthly Champions.
    if (mainScanTour && _tab != ScanningTab.scan) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tab != ScanningTab.scan) {
          setState(() => _tab = ScanningTab.scan);
        }
      });
    }

    // Honour a pending tab request (from Home), then clear it so a later manual
    // visit keeps whatever tab the user last chose. Done in a post-frame
    // callback because it both reads and writes providers during build.
    final requested = ref.watch(scanningTabRequestProvider);
    if (requested != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _tab = requested);
        ref.read(scanningTabRequestProvider.notifier).state = null;
      });
    }

    return Scaffold(
      appBar: AppHeaderBar(title: l10n.scanningTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedToggle<ScanningTab>(
                value: _tab,
                options: [
                  SegmentOption(
                    value: ScanningTab.scan,
                    label: l10n.scanTabLabel,
                  ),
                  SegmentOption(
                    value: ScanningTab.champions,
                    label: l10n.championsTabLabel,
                  ),
                ],
                onChanged: (tab) => setState(() => _tab = tab),
              ),
              const SizedBox(height: 16),
              if (_tab == ScanningTab.scan) ...[
                const ScanCard(),
                const SizedBox(height: 20),
                const PointsHistorySection(),
                const SizedBox(height: 20),
                const HowToEarnPanel(),
              ] else
                MonthlyChampionsContent(),
            ],
          ),
        ),
      ),
    );
  }
}
