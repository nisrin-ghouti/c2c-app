import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header_bar.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../../admin/domain/entities/option_list_item.dart';
import '../../../admin/domain/entities/option_list_type.dart';
import '../../../admin/presentation/providers/option_label_providers.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../onboarding/domain/entities/demo_key.dart';
import '../../../onboarding/presentation/controllers/demo_flags_controller.dart';
import '../../../onboarding/presentation/controllers/guided_matching_tour_controller.dart';
import '../../../onboarding/presentation/widgets/contextual_showcase.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/benefit.dart';
import '../../domain/entities/digital_card.dart';
import '../../domain/entities/redeem_result.dart';
import '../controllers/redeem_benefit_controller.dart';
import '../providers/benefits_providers.dart';
import '../widgets/benefit_card.dart';
import '../widgets/digital_card_tile.dart';
import 'benefit_profile_screen.dart';
import 'card_detail_screen.dart';

enum _BenefitsTab { catalog, wallet }

/// The "Benefits" bottom-nav tab: browse the partner catalog and spend
/// points, or view previously-redeemed cards — same page, switched by the
/// segmented toggle (matches the Scanning tab's Scan/Champions pattern).
class BenefitsScreen extends ConsumerStatefulWidget {
  const BenefitsScreen({super.key});

  @override
  ConsumerState<BenefitsScreen> createState() => _BenefitsScreenState();
}

class _BenefitsScreenState extends ConsumerState<BenefitsScreen> {
  _BenefitsTab _tab = _BenefitsTab.catalog;
  String? _redeemingBenefitId;
  final _catalogShowcaseKey = GlobalKey();
  final _statusShowcaseKey = GlobalKey();
  final _walletTapShowcaseKey = GlobalKey();
  final _walletContentShowcaseKey = GlobalKey();
  bool _benefitsTourKicked = false;
  bool _walletTourKicked = false;

  Future<void> _redeem(Benefit benefit, AppLocalizations l10n) async {
    final title = benefit.localizedTitle(
      Localizations.localeOf(context).languageCode,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.benefitRedeemConfirmTitle),
        content: Text(
          l10n.benefitRedeemConfirmMessage(title, benefit.pointCost),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.benefitRedeemAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _redeemingBenefitId = benefit.id);
    final outcome = await ref
        .read(redeemBenefitControllerProvider.notifier)
        .redeem(benefit.id);
    if (!mounted) return;
    setState(() => _redeemingBenefitId = null);

    if (outcome.result == RedeemBenefitResult.ok && outcome.card != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CardDetailScreen(card: outcome.card!),
        ),
      );
      return;
    }

    final message = switch (outcome.result) {
      RedeemBenefitResult.alreadyActive => l10n.benefitRedeemErrorAlreadyActive,
      RedeemBenefitResult.insufficientPoints =>
        l10n.benefitRedeemErrorInsufficientPoints,
      RedeemBenefitResult.inactive ||
      RedeemBenefitResult.notFound => l10n.benefitRedeemErrorUnavailable,
      RedeemBenefitResult.notAStudent => l10n.benefitRedeemErrorNotAStudent,
      _ => l10n.benefitRedeemErrorGeneric,
    };
    if (outcome.result == RedeemBenefitResult.alreadyActive) {
      ref.invalidate(myDigitalCardsProvider);
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final points = ref.watch(homeDashboardProvider).valueOrNull?.summary.points;
    final benefitsCatalog = ref.watch(benefitsCatalogProvider);
    final benefitsReady = benefitsCatalog.valueOrNull != null;
    // Keeps the autoDispose redeem controller alive across the redeem() await —
    // without a watcher it has zero listeners and gets disposed mid-operation.
    ref.watch(redeemBenefitControllerProvider);

    // A card's barcode page or a benefit profile left open here would
    // otherwise sit on top of this branch through a replay, burying the
    // Benefits step's targets.
    dismissPushedRoutesOnTourReplay(context, ref);

    final tourStep = ref.watch(matchingTourStepProvider);
    final showBenefitsTour =
        tourStep == MatchingTourStep.awaitingBenefitsContent;
    final showWalletTap = tourStep == MatchingTourStep.awaitingWalletTap;
    final showWalletTour = tourStep == MatchingTourStep.awaitingWalletContent;
    // Same reset as matches/scan: these States survive a tour replay, so a
    // one-shot flag would skip the step silently on the second run.
    if (!showBenefitsTour) _benefitsTourKicked = false;
    if (!showWalletTour) _walletTourKicked = false;

    void openWalletFromTour() {
      setState(() => _tab = _BenefitsTab.wallet);
      if (showBenefitsTour || showWalletTap) {
        ref.read(matchingTourStepProvider.notifier).state =
            MatchingTourStep.awaitingWalletContent;
      }
    }

    if (showBenefitsTour && _tab != _BenefitsTab.catalog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tab != _BenefitsTab.catalog) {
          setState(() => _tab = _BenefitsTab.catalog);
        }
      });
    } else if (showBenefitsTour && benefitsReady && !_benefitsTourKicked) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        if (ref.read(matchingTourStepProvider) !=
            MatchingTourStep.awaitingBenefitsContent) {
          return;
        }

        // Wait until all Benefits tour targets are actually mounted.
        // The catalog is loaded asynchronously, so these keys may not
        // exist yet on the first frame after navigating to Benefits.
        // `GlobalKey.currentContext` doesn't work here — in showcaseview
        // v5.x a GlobalKey passed to `Showcase` is only a registry id and
        // is never attached to the widget's Element, so `currentContext`
        // is always null; `isTargetRendered` checks the package's own
        // registry instead.
        final targetsReady =
            ShowcaseView.get().isTargetRendered(_catalogShowcaseKey) &&
            ShowcaseView.get().isTargetRendered(_statusShowcaseKey) &&
            ShowcaseView.get().isTargetRendered(_walletTapShowcaseKey);

        if (!targetsReady) {
          // Do not mark the tour as started yet.
          // When the benefits data finishes loading, the screen rebuilds
          // and this block will try again.
          return;
        }
        _benefitsTourKicked = true;
        ShowcaseView.get().startShowCase([
          _catalogShowcaseKey,
          _statusShowcaseKey,
          _walletTapShowcaseKey,
        ]);
      });
    }
    if (showWalletTour && _tab != _BenefitsTab.wallet) {
      // Resuming straight onto this step after a refresh lands here with
      // the tab still defaulted to catalog — force it over, same as the
      // benefits-content step above forces catalog.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tab != _BenefitsTab.wallet) {
          setState(() => _tab = _BenefitsTab.wallet);
        }
      });
    }
    if (showWalletTour && _tab == _BenefitsTab.wallet && !_walletTourKicked) {
      _walletTourKicked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final epoch = ref.read(tourEpochProvider);
        if (ref.read(matchingTourStepProvider) !=
            MatchingTourStep.awaitingWalletContent) {
          return;
        }
        late VoidCallback finishListener;
        finishListener = () {
          // Deferred: showcaseview invokes these with `for (final cb in
          // _onFinishCallbacks)`, and mutating that list inside a callback throws
          // ConcurrentModificationError on the next moveNext(), silently skipping
          // every callback after this one — including the tour's own listener.
          scheduleMicrotask(
            () => ShowcaseView.get().removeOnFinishCallback(finishListener),
          );
          if (!mounted) return;
          if (ref.read(tourEpochProvider) != epoch) return;
          ref.read(matchingTourStepProvider.notifier).state =
              MatchingTourStep.awaitingProfileTab;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (ref.read(tourEpochProvider) != epoch) return;
            late VoidCallback profileFinishListener;
            profileFinishListener = () {
              // Deferred: showcaseview invokes these with `for (final cb in
              // _onFinishCallbacks)`, and mutating that list inside a callback throws
              // ConcurrentModificationError on the next moveNext(), silently skipping
              // every callback after this one — including the tour's own listener.
              scheduleMicrotask(
                () => ShowcaseView.get().removeOnFinishCallback(
                  profileFinishListener,
                ),
              );
              if (ref.read(tourEpochProvider) != epoch) return;
              ref.read(matchingTourStepProvider.notifier).state =
                  MatchingTourStep.none;
            };
            ShowcaseView.get().addOnFinishCallback(profileFinishListener);
            ShowcaseView.get().startShowCase([profileTabTourShowcaseKey]);
          });
        };
        ShowcaseView.get().addOnFinishCallback(finishListener);
        ShowcaseView.get().startShowCase([_walletContentShowcaseKey]);
      });
    }
    return Scaffold(
      appBar: AppHeaderBar(title: l10n.navBenefits),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedToggle<_BenefitsTab>(
                    value: _tab,
                    options: [
                      SegmentOption(
                        value: _BenefitsTab.catalog,
                        label: l10n.benefitsCatalogTabLabel,
                      ),
                      SegmentOption(
                        value: _BenefitsTab.wallet,
                        label: l10n.benefitsWalletTabLabel,
                      ),
                    ],
                    onChanged: (tab) {
                      if (showBenefitsTour || showWalletTap || showWalletTour) {
                        return;
                      }

                      setState(() => _tab = tab);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(
              child: _tab == _BenefitsTab.catalog
                  ? _CatalogView(
                      points: points ?? 0,
                      redeemingBenefitId: _redeemingBenefitId,
                      onRedeem: (b) => _redeem(b, l10n),
                      onOpenWallet: openWalletFromTour,
                      tourActive: showBenefitsTour || showWalletTap,
                      catalogShowcaseKey: _catalogShowcaseKey,
                      statusShowcaseKey: _statusShowcaseKey,
                      walletShowcaseKey: _walletTapShowcaseKey,
                    )
                  : (showWalletTour
                        ? TourShowcase(
                            showcaseKey: _walletContentShowcaseKey,
                            title: l10n.tourWalletTitle,
                            description: l10n.tourWalletDescription,
                            hidePrevious: true,
                            child: _WalletView(points: points ?? 0),
                          )
                        : _WalletView(points: points ?? 0)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small, non-blocking first-visit notice — "do not interfere with
/// browsing" (spec), so this is a dismissible inline card rather than a
/// spotlight/dialog. Disappears for good once dismissed (marks the shared
/// per-user `DemoKey.benefitsCatalog` flag seen).
class _CatalogFirstVisitNotice extends ConsumerWidget {
  const _CatalogFirstVisitNotice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(hasSeenDemoProvider(DemoKey.benefitsCatalog))) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline,
              color: AppColors.primaryStrong,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.demoBenefitsCatalogTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.demoBenefitsCatalogMessage,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: l10n.actionGotIt,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => ref
                  .read(demoFlagsControllerProvider)
                  .markSeen(DemoKey.benefitsCatalog),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogView extends ConsumerStatefulWidget {
  const _CatalogView({
    required this.points,
    required this.redeemingBenefitId,
    required this.onRedeem,
    required this.onOpenWallet,
    required this.tourActive,
    required this.catalogShowcaseKey,
    required this.statusShowcaseKey,
    required this.walletShowcaseKey,
  });

  final int points;
  final String? redeemingBenefitId;
  final void Function(Benefit) onRedeem;
  final VoidCallback onOpenWallet;
  final bool tourActive;
  final GlobalKey catalogShowcaseKey;
  final GlobalKey statusShowcaseKey;
  final GlobalKey walletShowcaseKey;
  @override
  ConsumerState<_CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends ConsumerState<_CatalogView> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final benefitsAsync = ref.watch(benefitsCatalogProvider);
    final categoriesAsync = ref.watch(
      optionListProvider(OptionListType.benefitCategory),
    );
    // A benefit stays unredeemable while the student holds an active (i.e.
    // not yet scanned) card for it — falls back to an empty set while the
    // wallet is still loading, which briefly under-restricts the button but
    // the RPC's own `already_active` check backs it up either way.
    final activeCardBenefitIds =
        (ref.watch(myDigitalCardsProvider).valueOrNull ?? const [])
            .where((c) => !c.isRedeemed)
            .map((c) => c.benefitId)
            .toSet();

    return RefreshIndicator(
      onRefresh: () => ref.refresh(benefitsCatalogProvider.future),
      child: benefitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ListView(
          children: [
            const SizedBox(height: 80),
            Center(child: Text(l10n.benefitsCatalogLoadError)),
          ],
        ),
        data: (allBenefits) {
          if (allBenefits.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Text(
                    l10n.benefitsCatalogEmpty,
                    style: const TextStyle(color: AppColors.mutedForeground),
                  ),
                ),
              ],
            );
          }

          final knownCategories =
              categoriesAsync.valueOrNull ?? const <OptionListItem>[];
          // Filter chips must reflect whatever categories the benefits actually
          // carry, even if the admin-curated option list hasn't been populated —
          // otherwise only "All" ever renders.
          final presentCategories =
              allBenefits
                  .map((b) => b.category)
                  .whereType<String>()
                  .where((c) => c.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          final languageCode = Localizations.localeOf(context).languageCode;
          String categoryLabel(String category) {
            for (final option in knownCategories) {
              if (option.label == category) {
                return option.labelFor(languageCode);
              }
            }
            return category;
          }

          final benefits = _category == null
              ? allBenefits
              : allBenefits.where((b) => b.category == _category).toList();

          // Progress toward the cheapest benefit still out of reach — gives the
          // status banner's bar real meaning instead of a decorative fill.
          final unaffordable = allBenefits
              .where((b) => b.pointCost > widget.points)
              .map((b) => b.pointCost);
          final nextGoal = unaffordable.isEmpty
              ? null
              : unaffordable.reduce((a, b) => a < b ? a : b);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            // The tour's highlight is anchored to a measured rect; letting the
            // list scroll underneath it would slide the content out from under
            // the spotlight.
            physics: widget.tourActive
                ? const NeverScrollableScrollPhysics()
                : null,
            children: [
              const _CatalogFirstVisitNotice(),
              widget.tourActive
                  ? TourShowcase(
                      showcaseKey: widget.statusShowcaseKey,
                      title: l10n.tourBenefitsStatusTitle,
                      description: l10n.tourBenefitsStatusDescription,
                      child: _CatalogStatusBanner(
                        points: widget.points,
                        nextGoalCost: nextGoal,
                        onOpenWallet: widget.onOpenWallet,
                        walletShowcaseKey: widget.walletShowcaseKey,
                        tourActive: widget.tourActive,
                      ),
                    )
                  : _CatalogStatusBanner(
                      points: widget.points,
                      nextGoalCost: nextGoal,
                      onOpenWallet: widget.onOpenWallet,
                      walletShowcaseKey: widget.walletShowcaseKey,
                      tourActive: widget.tourActive,
                    ),
              const SizedBox(height: 18),
              // The Benefits explanation step highlights the catalog as a
              // whole — heading, category filters and the benefit cards — so
              // the narration points at what it is describing rather than at
              // one heading. Grouping them also means the highlight tracks
              // the real catalog height instead of a fixed guess.
              _CatalogSection(
                showcase: widget.tourActive
                    ? (
                        key: widget.catalogShowcaseKey,
                        title: l10n.tourBenefitsPageTitle,
                        description: l10n.tourBenefitsPageDescription,
                      )
                    : null,
                children: [
                  Text(
                    l10n.benefitsCatalogHeading,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _CategoryChip(
                          label: l10n.benefitsCategoryAll,
                          icon: Icons.apps,
                          selected: _category == null,
                          onTap: () => setState(() => _category = null),
                        ),
                        for (final category in presentCategories) ...[
                          const SizedBox(width: 8),
                          _CategoryChip(
                            label: categoryLabel(category),
                            icon: _categoryIcon(category),
                            selected: _category == category,
                            onTap: () => setState(() => _category = category),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (benefits.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          l10n.benefitsCatalogEmpty,
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final benefit in benefits.take(
                      widget.tourActive
                          ? _tourHighlightedCards
                          : benefits.length,
                    )) ...[
                      Builder(
                        builder: (context) {
                          final canAfford = widget.points >= benefit.pointCost;
                          final hasActiveCard = activeCardBenefitIds.contains(
                            benefit.id,
                          );
                          return BenefitCard(
                            benefit: benefit,
                            canAfford: canAfford,
                            hasActiveCard: hasActiveCard,
                            redeeming: widget.redeemingBenefitId == benefit.id,
                            onRedeem: () => widget.onRedeem(benefit),
                            // Any published benefit opens its profile, affordable or not.
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BenefitProfileScreen(
                                  benefit: benefit,
                                  canAfford: canAfford,
                                  hasActiveCard: hasActiveCard,
                                  redeeming:
                                      widget.redeemingBenefitId == benefit.id,
                                  onRedeem: () {
                                    Navigator.of(context).pop();
                                    widget.onRedeem(benefit);
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                ],
              ),
              // Cards beyond the highlighted region. During the tour the
              // spotlight covers only the first few (see
              // `_tourHighlightedCards`); the rest render normally underneath
              // so the catalog is still complete.
              if (widget.tourActive)
                for (final benefit in benefits.skip(_tourHighlightedCards)) ...[
                  Builder(
                    builder: (context) {
                      final canAfford = widget.points >= benefit.pointCost;
                      final hasActiveCard = activeCardBenefitIds.contains(
                        benefit.id,
                      );
                      return BenefitCard(
                        benefit: benefit,
                        canAfford: canAfford,
                        hasActiveCard: hasActiveCard,
                        redeeming: widget.redeemingBenefitId == benefit.id,
                        onRedeem: () => widget.onRedeem(benefit),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BenefitProfileScreen(
                              benefit: benefit,
                              canAfford: canAfford,
                              hasActiveCard: hasActiveCard,
                              redeeming:
                                  widget.redeemingBenefitId == benefit.id,
                              onRedeem: () {
                                Navigator.of(context).pop();
                                widget.onRedeem(benefit);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
            ],
          );
        },
      ),
    );
  }
}

/// Groups the benefits catalog — heading, category filters and cards — so the
/// tour can highlight it as one region.
///
/// With [showcase] null (the normal case) this is just a column of the given
/// children, so the catalog looks and behaves exactly as before. During the
/// tour it wraps them in a single [TourShowcase], which is what makes the
/// explanation spotlight the whole catalog instead of one heading.
/// How many benefit cards sit inside the tour's highlighted catalog region.
///
/// The highlight must stay shorter than the viewport: `getRect()` clamps the
/// target rect to the screen, so a taller region clamps to the *whole screen*
/// and the spotlight reads as "nothing is highlighted". Two cards keep the
/// region to heading + filters + a sample of the list.
const _tourHighlightedCards = 2;

class _CatalogSection extends StatelessWidget {
  const _CatalogSection({required this.showcase, required this.children});

  final ({GlobalKey key, String title, String description})? showcase;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );

    final config = showcase;
    if (config == null) return column;

    return TourShowcase(
      showcaseKey: config.key,
      title: config.title,
      description: config.description,
      hidePrevious: true,
      child: column,
    );
  }
}

enum _WalletFilter { all, notUsed, used }

class _WalletView extends ConsumerStatefulWidget {
  const _WalletView({required this.points});

  final int points;

  @override
  ConsumerState<_WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends ConsumerState<_WalletView> {
  _WalletFilter _filter = _WalletFilter.all;
  String? _businessFilter;

  Future<void> _pickBusinessFilter(
    List<DigitalCard> cards,
    AppLocalizations l10n,
  ) async {
    final businesses =
        cards
            .map((c) => c.partnerBusinessName)
            .whereType<String>()
            .where((b) => b.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    if (businesses.isEmpty) return;

    final selected = await showModalBottomSheet<String?>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                l10n.benefitsWalletFilterByBusiness,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ListTile(
              title: Text(l10n.benefitsWalletFilterClear),
              onTap: () => Navigator.of(context).pop<String?>(null),
            ),
            for (final b in businesses)
              ListTile(
                title: Text(b),
                onTap: () => Navigator.of(context).pop<String?>(b),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _businessFilter = selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cardsAsync = ref.watch(myDigitalCardsProvider);
    final studentName =
        ref.watch(myProfileProvider).valueOrNull?.fullName ?? '';

    return RefreshIndicator(
      onRefresh: () => ref.refresh(myDigitalCardsProvider.future),
      child: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ListView(
          children: [
            const SizedBox(height: 80),
            Center(child: Text(l10n.benefitsWalletLoadError)),
          ],
        ),
        data: (allCards) {
          if (allCards.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Text(
                    l10n.benefitsWalletEmpty,
                    style: const TextStyle(color: AppColors.mutedForeground),
                  ),
                ),
              ],
            );
          }

          final businessCards = _businessFilter == null
              ? allCards
              : allCards
                    .where((c) => c.partnerBusinessName == _businessFilter)
                    .toList();
          final notUsedCount = businessCards.where((c) => !c.isRedeemed).length;
          final usedCount = businessCards.where((c) => c.isRedeemed).length;
          final cards = switch (_filter) {
            _WalletFilter.all => businessCards,
            _WalletFilter.notUsed =>
              businessCards.where((c) => !c.isRedeemed).toList(),
            _WalletFilter.used =>
              businessCards.where((c) => c.isRedeemed).toList(),
          };

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              _WalletHeader(points: widget.points, l10n: l10n),
              const SizedBox(height: 12),
              Row(
                children: [
                  _FilterIconButton(
                    active: _businessFilter != null,
                    label: l10n.benefitsWalletFilterButton,
                    onTap: () => _pickBusinessFilter(allCards, l10n),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _FilterChip(
                            label: l10n.benefitsWalletFilterNotUsed,
                            count: notUsedCount,
                            color: AppColors.success,
                            selected: _filter == _WalletFilter.notUsed,
                            onTap: () =>
                                setState(() => _filter = _WalletFilter.notUsed),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _FilterChip(
                            label: l10n.benefitsWalletFilterUsed,
                            count: usedCount,
                            color: AppColors.mutedForeground,
                            selected: _filter == _WalletFilter.used,
                            onTap: () =>
                                setState(() => _filter = _WalletFilter.used),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _FilterChip(
                            label: l10n.benefitsWalletFilterAll,
                            count: businessCards.length,
                            color: AppColors.primaryStrong,
                            selected: _filter == _WalletFilter.all,
                            onTap: () =>
                                setState(() => _filter = _WalletFilter.all),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (cards.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      l10n.benefitsWalletEmpty,
                      style: const TextStyle(color: AppColors.mutedForeground),
                    ),
                  ),
                )
              else
                for (final card in cards)
                  DigitalCardTile(
                    card: card,
                    studentName: studentName,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CardDetailScreen(card: card),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _WalletHeader extends StatelessWidget {
  const _WalletHeader({required this.points, required this.l10n});

  final int points;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.primaryForeground,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.benefitsWalletTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Text(
                  l10n.benefitsWalletSubtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.benefitsWalletPointsLabel,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.mutedForeground,
                ),
              ),
              Text(
                '$points ✨',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.primaryStrong,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterIconButton extends StatelessWidget {
  const _FilterIconButton({
    required this.active,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? AppColors.primary.withValues(alpha: 0.25)
          : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.filter_list,
                size: 16,
                color: AppColors.foreground,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Best-effort icon for a category's canonical (English) label. Purely
/// cosmetic — an unmatched category still renders fine with the fallback tag
/// icon, so new categories added via the admin option-list editor never break.
IconData _categoryIcon(String canonicalLabel) {
  final label = canonicalLabel.toLowerCase();
  if (label.contains('food') ||
      label.contains('drink') ||
      label.contains('coffee')) {
    return Icons.restaurant;
  }
  if (label.contains('beauty') ||
      label.contains('care') ||
      label.contains('spa')) {
    return Icons.spa_outlined;
  }
  if (label.contains('stud') ||
      label.contains('book') ||
      label.contains('station')) {
    return Icons.menu_book_outlined;
  }
  if (label.contains('fit') ||
      label.contains('sport') ||
      label.contains('gym')) {
    return Icons.fitness_center;
  }
  if (label.contains('game') ||
      label.contains('entertain') ||
      label.contains('fun')) {
    return Icons.sports_esports;
  }
  if (label.contains('fashion') ||
      label.contains('cloth') ||
      label.contains('wear')) {
    return Icons.checkroom;
  }
  if (label.contains('tech') || label.contains('electron')) {
    return Icons.devices_other;
  }
  if (label.contains('travel') || label.contains('transport')) {
    return Icons.directions_bus_filled_outlined;
  }
  return Icons.local_offer_outlined;
}

/// Gradient hero card atop the catalog — points balance, progress toward the
/// next benefit still out of reach, and a shortcut into the wallet.
class _CatalogStatusBanner extends StatelessWidget {
  const _CatalogStatusBanner({
    required this.points,
    required this.nextGoalCost,
    required this.onOpenWallet,
    required this.walletShowcaseKey,
    required this.tourActive,
  });

  final int points;
  final int? nextGoalCost;
  final VoidCallback onOpenWallet;
  final GlobalKey walletShowcaseKey;
  final bool tourActive;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress = nextGoalCost == null || nextGoalCost == 0
        ? 1.0
        : (points / nextGoalCost!).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gradientPrimaryStart,
            AppColors.secondary,
            AppColors.accentMint,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.benefitsStatusLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryForeground,
                ),
              ),
              const Spacer(),
              Text(
                '$points ✨',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  color: AppColors.primaryForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              l10n.benefitsWalletPointsLabel,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primaryForeground.withValues(alpha: 0.75),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.4),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: tourActive
                ? TourShowcase(
                    showcaseKey: walletShowcaseKey,
                    title: l10n.tourWalletTitle,
                    description: l10n.tourWalletTapDescription,
                    hideNext: true,
                    onTargetClick: onOpenWallet,
                    disposeOnTap: true,
                    child: OutlinedButton.icon(
                      onPressed: onOpenWallet,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.6),
                        foregroundColor: AppColors.primaryForeground,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      icon: const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 18,
                      ),
                      label: Text(
                        l10n.benefitsOpenWalletAction,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: onOpenWallet,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.6),
                      foregroundColor: AppColors.primaryForeground,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 18,
                    ),
                    label: Text(
                      l10n.benefitsOpenWalletAction,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.35)
          : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected
                    ? AppColors.primaryStrong
                    : AppColors.mutedForeground,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.primaryStrong
                      : AppColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.18) : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? color : AppColors.foreground,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: selected ? color : AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
