import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/auth_scaffold.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../../../../core/widgets/inline_banner.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
import '../../../../core/widgets/required_field_label.dart';
import '../../../../core/widgets/year_of_study_field.dart';
import '../../../../core/widgets/filter_chip_row.dart';
import '../../../admin/domain/entities/option_list_item.dart';
import '../../../admin/domain/entities/option_list_type.dart';
import '../../../admin/presentation/providers/admin_providers.dart';
import '../../../admin/presentation/widgets/option_list_searchable_field.dart';
import '../../domain/entities/gender.dart';
import '../../domain/entities/profile.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/full_name_warning.dart';
import '../controllers/complete_profile_controller.dart';
import '../navigation/post_auth_navigation.dart';
import '../providers/auth_providers.dart';

/// The current user's profile, loaded once so the mandatory Complete-Profile
/// screen can prefill anything already on file (name from sign-up, or partial
/// data from a previous visit) instead of forcing the user to re-enter it.
final _currentProfileProvider = FutureProvider.autoDispose<Profile>((ref) {
  return ref.watch(getMyProfileProvider)();
});

AutoDisposeFutureProvider<List<OptionListItem>> _optionsProvider(
  OptionListType type,
) {
  return FutureProvider.autoDispose<List<OptionListItem>>((ref) {
    return ref.watch(adminRepositoryProvider).listOptions(type);
  });
}

final _facultyOptionsProvider = _optionsProvider(OptionListType.faculty);
final _fieldOfStudyOptionsProvider = _optionsProvider(
  OptionListType.fieldOfStudy,
);
final _degreeOptionsProvider = _optionsProvider(OptionListType.degree);
final _languageOptionsProvider = _optionsProvider(OptionListType.language);

/// "Interests" merges the legacy `hobby` and `interest` option lists into one
/// deduped-by-label set — see `Profile.hobbies`/`Profile.interests` doc note.
final _mergedInterestOptionsProvider =
    FutureProvider.autoDispose<List<OptionListItem>>((ref) async {
      final repo = ref.watch(adminRepositoryProvider);
      final lists = await Future.wait([
        repo.listOptions(OptionListType.interest),
        repo.listOptions(OptionListType.hobby),
      ]);
      final byLabel = <String, OptionListItem>{};
      for (final list in lists) {
        for (final item in list.where((o) => o.active)) {
          byLabel.putIfAbsent(item.label, () => item);
        }
      }
      return byLabel.values.toList();
    });

class CompleteProfileScreen extends ConsumerWidget {
  const CompleteProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(_currentProfileProvider);

    return AuthScaffold(
      title: l10n.completeProfileTitle,
      subtitle: l10n.completeProfileSubtitle,
      child: profileAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
        // Even if the prefetch fails we still let the user fill the form in
        // from scratch rather than trapping them on an error.
        error: (_, _) => const _CompleteProfileForm(initial: null),
        data: (profile) => _CompleteProfileForm(initial: profile),
      ),
    );
  }
}

class _CompleteProfileForm extends ConsumerStatefulWidget {
  const _CompleteProfileForm({required this.initial});

  final Profile? initial;

  @override
  ConsumerState<_CompleteProfileForm> createState() =>
      _CompleteProfileFormState();
}

class _CompleteProfileFormState extends ConsumerState<_CompleteProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _firstNameController = TextEditingController(
    text: _splitName(widget.initial?.fullName).$1,
  );
  late final _lastNameController = TextEditingController(
    text: _splitName(widget.initial?.fullName).$2,
  );
  late final _bioController = TextEditingController(
    text: widget.initial?.bio ?? '',
  );

  /// First word = first name, remainder = last name — a full split into real
  /// first/last columns doesn't exist in the schema (only `full_name`), so
  /// this is a best-effort decomposition for prefilling the two fields.
  static (String, String) _splitName(String? fullName) {
    final trimmed = fullName?.trim() ?? '';
    if (trimmed.isEmpty) return ('', '');
    final parts = trimmed.split(RegExp(r'\s+'));
    return (parts.first, parts.skip(1).join(' '));
  }

  late int? _year = widget.initial?.year;
  late Set<String> _faculties = widget.initial?.faculties.toSet() ?? {};
  late Set<String> _fieldsOfStudy = widget.initial?.fieldsOfStudy.toSet() ?? {};

  /// Merged view of the legacy `hobbies`/`interests` columns — written back
  /// to both on save so every existing reader of either stays correct.
  late Set<String> _interests = {
    ...?widget.initial?.hobbies,
    ...?widget.initial?.interests,
  };
  late Set<String> _languages = widget.initial?.languages.toSet() ?? {};
  late String? _degree = widget.initial?.degree;
  late Gender? _gender = widget.initial?.gender;
  late String? _avatarUrl = widget.initial?.avatarUrl;

  /// Shown under each mandatory picker after a failed submit until the user
  /// fills it in — a plain [Form] validator can't cover the chip/sheet
  /// pickers, so each one carries its own flag. Set together by [_submit] and
  /// cleared individually the moment that field gets a value.
  bool _fieldOfStudyMissing = false;
  bool _facultyMissing = false;
  bool _degreeMissing = false;
  bool _genderMissing = false;
  bool _yearMissing = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Every mandatory field is checked in one pass so a single tap flags all
    // of them at once, rather than the user discovering them one save at a
    // time. Mirrors `Profile.isComplete`, the rule the router's gate uses —
    // the two must agree or a "successful" save would bounce straight back
    // here.
    final formOk = _formKey.currentState!.validate();
    final fieldOfStudyOk = _fieldsOfStudy.isNotEmpty;
    final facultyOk = _faculties.isNotEmpty;
    final degreeOk = _degree != null && _degree!.trim().isNotEmpty;
    final genderOk = _gender != null;
    final yearOk = _year != null;
    setState(() {
      _fieldOfStudyMissing = !fieldOfStudyOk;
      _facultyMissing = !facultyOk;
      _degreeMissing = !degreeOk;
      _genderMissing = !genderOk;
      _yearMissing = !yearOk;
    });
    if (!formOk ||
        !fieldOfStudyOk ||
        !facultyOk ||
        !degreeOk ||
        !genderOk ||
        !yearOk) {
      return;
    }

    final destination = await ref
        .read(completeProfileControllerProvider.notifier)
        .submit(
          fullName:
              '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
          faculties: _faculties.toList(),
          fieldsOfStudy: _fieldsOfStudy.toList(),
          degree: _degree,
          gender: _gender,
          year: _year,
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
          hobbies: _interests.toList(),
          interests: _interests.toList(),
          languages: _languages.toList(),
          avatarUrl: _avatarUrl,
        );
    if (!mounted || destination == null) return;

    // Refresh the router's completion gate before navigating so the (now
    // satisfied) redirect doesn't bounce the user straight back here.
    ref.invalidate(profileGateProvider);
    await ref.read(profileGateProvider.future);
    if (!mounted) return;
    context.goToPostAuthDestination(destination);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(completeProfileControllerProvider);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: AvatarPicker(
              fullName: widget.initial?.fullName ?? '',
              avatarHue: widget.initial?.avatarHue ?? 220,
              avatarUrl: _avatarUrl,
              onUploaded: (url) => setState(() => _avatarUrl = url),
            ),
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _firstNameController,
            label: l10n.fieldFirstName,
            icon: Icons.person_outline,
            validator: (v) =>
                Validators.requiredField(v, l10n.errorEnterFirstName),
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _lastNameController,
            label: l10n.fieldLastName,
            icon: Icons.person_outline,
            validator: (v) =>
                Validators.requiredField(v, l10n.errorEnterLastName),
          ),
          const FullNameWarning(),
          const SizedBox(height: 20),
          OptionListSearchableField(
            title: l10n.profileFieldOfStudyLabel,
            required: true,
            optionsProvider: _fieldOfStudyOptionsProvider,
            selected: _fieldsOfStudy,
            onChanged: (next) => setState(() {
              _fieldsOfStudy = next;
              if (next.isNotEmpty) _fieldOfStudyMissing = false;
            }),
            errorText: _fieldOfStudyMissing
                ? l10n.errorSelectFieldOfStudy
                : null,
          ),
          const SizedBox(height: 16),
          OptionListSearchableField(
            title: l10n.profileFacultyLabel,
            required: true,
            optionsProvider: _facultyOptionsProvider,
            selected: _faculties,
            onChanged: (next) => setState(() {
              _faculties = next;
              if (next.isNotEmpty) _facultyMissing = false;
            }),
            errorText: _facultyMissing ? l10n.errorSelectFaculty : null,
          ),
          const SizedBox(height: 16),
          _SingleChoiceSection(
            title: l10n.profileDegreeLabel,
            optionsProvider: _degreeOptionsProvider,
            selected: _degree,
            onSelected: (value) => setState(() {
              _degree = value;
              _degreeMissing = false;
            }),
            errorText: _degreeMissing ? l10n.errorSelectDegree : null,
          ),
          const SizedBox(height: 16),
          _GenderSection(
            selected: _gender,
            onSelected: (value) => setState(() {
              _gender = value;
              _genderMissing = false;
            }),
            errorText: _genderMissing ? l10n.errorSelectGender : null,
          ),
          const SizedBox(height: 16),
          OptionListSearchableField(
            title: l10n.profileInterestsLabel,
            optionsProvider: _mergedInterestOptionsProvider,
            selected: _interests,
            onChanged: (next) => setState(() => _interests = next),
          ),
          const SizedBox(height: 16),
          OptionListSearchableField(
            title: l10n.profileLanguagesTitle,
            optionsProvider: _languageOptionsProvider,
            selected: _languages,
            onChanged: (next) => setState(() => _languages = next),
          ),
          const SizedBox(height: 16),
          YearOfStudyField(
            year: _year,
            required: true,
            errorText: _yearMissing ? l10n.errorSelectYearOfStudy : null,
            onChanged: (next) => setState(() {
              _year = next;
              if (next != null) _yearMissing = false;
            }),
          ),
          const SizedBox(height: 16),
          // Free-text self-introduction.
          AuthTextField(
            controller: _bioController,
            label: l10n.profileAboutTitle,
            hint: l10n.profileBioHint,
            maxLines: 4,
          ),
          if (state.errorKind != null) ...[
            const SizedBox(height: 12),
            InlineBanner(
              message: l10n.errorSaveProfileFailed,
              tone: BannerTone.error,
            ),
          ],
          const SizedBox(height: 24),
          PrimaryGradientButton(
            label: l10n.buttonContinue,
            loading: state.loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

/// Single-select option-list row (degree type: Bachelor's / Master's / PhD).
class _SingleChoiceSection extends ConsumerWidget {
  const _SingleChoiceSection({
    required this.title,
    required this.optionsProvider,
    required this.selected,
    required this.onSelected,
    this.errorText,
  });

  final String title;
  final AutoDisposeFutureProvider<List<OptionListItem>> optionsProvider;
  final String? selected;
  final ValueChanged<String> onSelected;

  /// Validation message for this mandatory picker, or null when satisfied.
  final String? errorText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final optionsAsync = ref.watch(optionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RequiredFieldLabel(label: title),
        const SizedBox(height: 8),
        optionsAsync.when(
          loading: () => const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, _) => Text(
            l10n.profileOptionsLoadError,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
          data: (options) {
            final active = options
                .where((o) => o.active)
                .map((o) => o.label)
                .toList();
            final language = Localizations.localeOf(context).languageCode;
            // Chips keep canonical values (that's what profiles store);
            // only their visible text is translated.
            final labels = {
              for (final o in options.where((o) => o.active))
                o.label: o.labelFor(language),
            };

            if (active.isEmpty) {
              return Text(
                l10n.profileOptionsEmpty,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedForeground,
                ),
              );
            }
            return FilterChipRow(
              options: active,
              selected: selected ?? '',
              onSelected: onSelected,
              labelBuilder: (value) => labels[value] ?? value,
            );
          },
        ),
        RequiredFieldError(errorText),
      ],
    );
  }
}

/// Gender picker. Unlike the option-list fields this is a fixed, *localized*
/// set — the values are stored as stable keys so they translate per locale.
class _GenderSection extends StatelessWidget {
  const _GenderSection({
    required this.selected,
    required this.onSelected,
    this.errorText,
  });

  final Gender? selected;
  final ValueChanged<Gender> onSelected;

  /// Validation message for this mandatory picker, or null when satisfied.
  final String? errorText;

  static String labelFor(AppLocalizations l10n, Gender gender) =>
      switch (gender) {
        Gender.male => l10n.genderMale,
        Gender.female => l10n.genderFemale,
        Gender.undisclosed => l10n.genderUndisclosed,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = {for (final g in Gender.values) labelFor(l10n, g): g};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RequiredFieldLabel(label: l10n.profileGenderLabel),
        const SizedBox(height: 8),
        FilterChipRow(
          options: labels.keys.toList(),
          selected: selected == null ? '' : labelFor(l10n, selected!),
          onSelected: (label) => onSelected(labels[label]!),
        ),
        RequiredFieldError(errorText),
      ],
    );
  }
}
