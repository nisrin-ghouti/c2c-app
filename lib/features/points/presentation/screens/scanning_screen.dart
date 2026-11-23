import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';

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
  bool _scanGuide = false;
  bool _championsGuide = false;
  final _championsGuideKey = GlobalKey();

  Future<void> _startChampionsGuide() async {
    for (var i = 0; i < 15; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted || !_championsGuide) return;
      if (ShowcaseView.get().isTargetRendered(_championsGuideKey)) {
        ShowcaseView.get().startShowCase([_championsGuideKey]);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    dismissPushedRoutesOnTourReplay(context, ref);

    ref.listen(tabGuideRequestProvider, (previous, next) {
      if (next != TabGuideTarget.scan) return;
      ref.read(tabGuideRequestProvider.notifier).state = null;
      if (_tab == ScanningTab.scan) {
        setState(() {
          _scanGuide = true;
          _championsGuide = false;
        });
        return;
      }
      setState(() {
        _scanGuide = false;
        _championsGuide = true;
      });
      _startChampionsGuide();
    });

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
      appBar: AppHeaderBar(
        title: l10n.scanningTitle,
        onOpenGuide: () => requestTabGuide(ref, TabGuideTarget.scan),
      ),
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
                ScanCard(guideActive: _scanGuide),
                const SizedBox(height: 20),
                const PointsHistorySection(),
                const SizedBox(height: 20),
                const HowToEarnPanel(),
              ] else
                MonthlyChampionsContent(
                  guideShowcaseKey: _championsGuide
                      ? _championsGuideKey
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
