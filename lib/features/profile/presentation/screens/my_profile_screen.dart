import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../admin/domain/entities/option_list_type.dart';
import '../../../admin/presentation/providers/option_label_providers.dart';
import '../../../../core/accessibility/accessibility_button_position_controller.dart';
import '../../../../core/accessibility/accessibility_panel.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/localization/supported_locales.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/widgets/app_header_bar.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../../auth/domain/entities/gender.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/push/push_service.dart';
import '../../../legal/legal.dart';
import '../../../legal/presentation/screens/legal_document_screen.dart';
import '../../../home/presentation/widgets/points_badge.dart';
import '../../../onboarding/presentation/controllers/home_coach_mark_controller.dart';
import '../../../onboarding/domain/entities/demo_key.dart';
import '../../../onboarding/presentation/controllers/demo_flags_controller.dart';
import '../../../onboarding/presentation/controllers/guided_matching_tour_controller.dart';
import '../../../support/presentation/widgets/support_contacts_sheet.dart';
import '../providers/profile_providers.dart';
import 'edit_profile_screen.dart';

/// Interests are stored across two legacy option lists (`hobby` and
/// `interest` — see the profile edit screens, which now present them as one
/// merged field) — try the `interest` list's translation first, then fall
/// back to `hobby`, so both old and newly-saved values resolve correctly.
String _mergedInterestLabel(
  WidgetRef ref,
  BuildContext context,
  String stored,
) {
  final fromInterest = localizedOptionLabel(
    ref,
    context,
    type: OptionListType.interest,
    storedLabel: stored,
  );
  if (fromInterest != stored) return fromInterest;
  return localizedOptionLabel(
    ref,
    context,
    type: OptionListType.hobby,
    storedLabel: stored,
  );
}

/// The "Profile" bottom-nav tab — view profile, edit, and settings (language,
/// accessibility, policy, logout), reusing the auth feature's `Profile`
/// entity/repository rather than duplicating profile fetch/save logic.
class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(myProfileProvider);

    dismissPushedRoutesOnTourReplay(context, ref);

    return Scaffold(
      appBar: AppHeaderBar(title: l10n.navProfile),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(myProfileProvider.future),
          child: profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => ListView(
              children: [
                const SizedBox(height: 120),
                Center(child: Text(l10n.profileLoadError)),
              ],
            ),
            data: (profile) => ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _ProfileHero(profile: profile),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionCard(
                        title: l10n.profileAboutTitle,
                        icon: Icons.person_outline,
                        child: Text(
                          (profile.bio == null || profile.bio!.isEmpty)
                              ? l10n.profileAboutEmpty
                              : profile.bio!,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: l10n.profileInterestsLabel,
                        icon: Icons.favorite_border,
                        child: Builder(
                          builder: (context) {
                            final merged = {
                              ...profile.hobbies,
                              ...profile.interests,
                            }.toList();
                            return Text(
                              merged.isEmpty
                                  ? l10n.profileInterestsEmpty
                                  : merged
                                        .map(
                                          (v) => _mergedInterestLabel(
                                            ref,
                                            context,
                                            v,
                                          ),
                                        )
                                        .where((v) => v.isNotEmpty)
                                        .join(', '),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: l10n.profileLanguagesTitle,
                        icon: Icons.translate,
                        child: Text(
                          profile.languages.isEmpty
                              ? l10n.profileLanguagesEmpty
                              : localizedOptionLabels(
                                  ref,
                                  context,
                                  type: OptionListType.language,
                                  storedLabels: profile.languages,
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: l10n.profileStudiesTitle,
                        icon: Icons.school_outlined,
                        child: Column(
                          children: [
                            _TableRow(
                              l10n.profileFieldOfStudyLabel,
                              profile.fieldsOfStudy.isEmpty
                                  ? '—'
                                  : localizedOptionLabels(
                                      ref,
                                      context,
                                      type: OptionListType.fieldOfStudy,
                                      storedLabels: profile.fieldsOfStudy,
                                    ),
                            ),
                            _TableRow(
                              l10n.profileFacultyLabel,
                              profile.faculties.isEmpty
                                  ? '—'
                                  : localizedOptionLabels(
                                      ref,
                                      context,
                                      type: OptionListType.faculty,
                                      storedLabels: profile.faculties,
                                    ),
                            ),
                            _TableRow(
                              l10n.profileDegreeLabel,
                              localizedOptionLabel(
                                    ref,
                                    context,
                                    type: OptionListType.degree,
                                    storedLabel: profile.degree,
                                  ).isEmpty
                                  ? '—'
                                  : localizedOptionLabel(
                                      ref,
                                      context,
                                      type: OptionListType.degree,
                                      storedLabel: profile.degree,
                                    ),
                            ),
                            _TableRow(
                              l10n.profileGenderLabel,
                              profile.gender == null
                                  ? '—'
                                  : switch (profile.gender!) {
                                      Gender.male => l10n.genderMale,
                                      Gender.female => l10n.genderFemale,
                                      Gender.undisclosed =>
                                        l10n.genderUndisclosed,
                                    },
                            ),
                            _TableRow(
                              l10n.profileYearLabel,
                              profile.year?.toString() ?? '—',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _SettingsCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends ConsumerWidget {
  const _ProfileHero({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pointsAsync = ref.watch(myTotalPointsProvider);

    final subtitleParts = [
      if (profile.fieldsOfStudy.isNotEmpty) profile.fieldsOfStudy.join(', '),
      if (profile.degree != null && profile.degree!.isNotEmpty) profile.degree!,
      if (profile.year != null) l10n.profileYearShort(profile.year!),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitleParts.join(' · '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.foreground,
                        ),
                      ),
                    ],
                    if (profile.email != null && profile.email!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        profile.email!,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.foreground.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              InitialsAvatar(
                initials: profile.fullName.isEmpty ? '?' : profile.fullName[0],
                hue: profile.avatarHue,
                imageUrl: profile.avatarUrl,
                size: 64,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              pointsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (points) => PointsBadge(points: points),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(profile: profile),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(
                  l10n.profileEditAction,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DefaultTextStyle(
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedForeground,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends ConsumerStatefulWidget {
  const _SettingsCard();

  @override
  ConsumerState<_SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends ConsumerState<_SettingsCard> {
  String? _version;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  /// Replays only the step-by-step coach-mark tour. The removed full-screen
  /// onboarding cards are intentionally not restored.
  Future<void> _replayStepByStepTour() async {
    await ref.read(homeCoachMarkControllerProvider.notifier).reset();
    // Reset only contextual flags that are embedded in the main tour.
    // First-ever-only demos (digital card, chat controls, notifications and
    // champions) stay seen even when the user deliberately replays the main
    // Step-by-Step tour.
    await ref.read(demoFlagsControllerProvider).resetSelected(const [
      DemoKey.accessibility,
      DemoKey.matching,
      DemoKey.reportUser,
      DemoKey.eventCheckIn,
    ]);
    ref.read(matchingTourStepProvider.notifier).state = MatchingTourStep.none;
    // Dismiss anything the previous tour pushed (a match profile), which
    // goBranch cannot pop because it was pushed imperatively.
    ref.read(tourGenerationProvider.notifier).state++;
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  Future<void> _confirmLogout(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profileLogoutConfirmTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.profileLogoutAction),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // Drop this device's push token first — the RPC needs the auth context,
      // which is gone once we sign out.
      await ref.read(pushServiceProvider).unregisterToken();
      await ref.read(signOutProvider)();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider);

    return _SectionCard(
      title: l10n.profileSettingsTitle,
      icon: Icons.settings_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.profileLanguageLabel,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SegmentedToggle<AppLocale>(
            compact: true,
            value: SupportedLocales.byCode(locale.languageCode),
            options: [
              for (final option in SupportedLocales.all)
                SegmentOption(value: option, label: option.nativeName),
            ],
            onChanged: (option) => ref
                .read(localeControllerProvider.notifier)
                .setLocale(option.locale),
          ),
          const SizedBox(height: 14),
          _SettingsRow(
            icon: Icons.accessibility_new,
            label: l10n.accessibilityPanelTitle,
            onTap: () => showAccessibilityPanel(context),
          ),
          _SettingsSwitchRow(
            icon: Icons.open_with,
            label: l10n.accessibilityFloatingToggle,
            value: ref.watch(accessibilityFloatingEnabledProvider),
            onChanged: (v) => ref
                .read(accessibilityFloatingEnabledProvider.notifier)
                .setEnabled(v),
          ),
          _SettingsRow(
            icon: Icons.description_outlined,
            label: l10n.profilePolicyLabel,
            onTap: () => context.push(AppRoutes.policy),
          ),
          _SettingsRow(
            icon: Icons.privacy_tip_outlined,
            label: l10n.legalPrivacyTitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const LegalDocumentScreen(kind: LegalDocumentKind.privacy),
              ),
            ),
          ),
          _SettingsRow(
            icon: Icons.gavel_outlined,
            label: l10n.legalTermsTitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const LegalDocumentScreen(kind: LegalDocumentKind.terms),
              ),
            ),
          ),
          _SettingsRow(
            icon: Icons.poll_outlined,
            label: l10n.surveysTitle,
            onTap: () => context.push(AppRoutes.surveys),
          ),
          _SettingsRow(
            icon: Icons.support_agent,
            label: l10n.supportContactsRowLabel,
            onTap: () => showSupportContactsSheet(context),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.settingsHelpSectionTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          _SettingsRow(
            icon: Icons.replay,
            label: l10n.tourReplayAction,
            onTap: _replayStepByStepTour,
          ),
          const Divider(height: 24, color: AppColors.border),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(l10n),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.destructive,
                side: BorderSide(
                  color: AppColors.destructive.withValues(alpha: 0.4),
                ),
              ),
              icon: const Icon(Icons.logout, size: 16),
              label: Text(l10n.profileLogoutAction),
            ),
          ),
          if (_version != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                l10n.profileAppVersion(_version!),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.mutedForeground),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.foreground,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.mutedForeground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.foreground,
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
