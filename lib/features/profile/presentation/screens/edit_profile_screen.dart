import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/push/push_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../../../../core/widgets/filter_chip_row.dart';
import '../../../../core/widgets/inline_banner.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
import '../../../../core/widgets/required_field_label.dart';
import '../../../../core/widgets/root_scaffold_messenger.dart';
import '../../../../core/widgets/year_of_study_field.dart';
import '../../../admin/domain/entities/option_list_item.dart';
import '../../../admin/domain/entities/option_list_type.dart';
import '../../../admin/presentation/providers/admin_providers.dart';
import '../../../admin/presentation/widgets/option_list_searchable_field.dart';
import '../../../auth/domain/entities/gender.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../auth/presentation/widgets/avatar_picker.dart';
import '../../../auth/presentation/widgets/full_name_warning.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

final _facultyOptionsProvider =
    FutureProvider.autoDispose<List<OptionListItem>>((ref) {
      return ref
          .watch(adminRepositoryProvider)
          .listOptions(OptionListType.faculty);
    });

final _fieldOfStudyOptionsProvider =
    FutureProvider.autoDispose<List<OptionListItem>>((ref) {
      return ref
          .watch(adminRepositoryProvider)
          .listOptions(OptionListType.fieldOfStudy);
    });

final _degreeOptionsProvider = FutureProvider.autoDispose<List<OptionListItem>>(
  (ref) {
    return ref
        .watch(adminRepositoryProvider)
        .listOptions(OptionListType.degree);
  },
);

final _languageOptionsProvider =
    FutureProvider.autoDispose<List<OptionListItem>>((ref) {
      return ref
          .watch(adminRepositoryProvider)
          .listOptions(OptionListType.language);
    });

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

/// Edit form for everything shown on `MyProfileScreen`, including first/last
/// name (email stays fixed) — mirrors `CompleteProfileScreen`'s
/// Form/AuthTextField/PrimaryGradientButton pattern, extended with
/// searchable multi-select fields for faculty/field/interests/languages.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final Profile profile;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _firstNameController = TextEditingController(
    text: _splitName(widget.profile.fullName).$1,
  );
  late final _lastNameController = TextEditingController(
    text: _splitName(widget.profile.fullName).$2,
  );
  late final _bioController = TextEditingController(
    text: widget.profile.bio ?? '',
  );
  int? _year;
  late Set<String> _faculties;
  late Set<String> _fieldsOfStudy;
  String? _degree;
  Gender? _gender;
  String? _avatarUrl;
  bool _avatarCleared = false;

  /// Merged view of the legacy `hobbies`/`interests` columns — written back
  /// to both on save so every existing reader of either stays correct.
  late Set<String> _interests;
  late Set<String> _languages;
  bool _submitting = false;

  /// One flag per mandatory picker, shown under that picker after a failed
  /// save until it gets a value — the chip/sheet pickers can't be covered by
  /// a plain [Form] validator. Same set `CompleteProfileScreen` keeps, so
  /// editing enforces exactly what onboarding does.
  bool _fieldOfStudyMissing = false;
  bool _facultyMissing = false;
  bool _degreeMissing = false;
  bool _genderMissing = false;
  bool _yearMissing = false;
  String? _errorMessage;
  bool _deleting = false;

  bool get _namesComplete =>
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty;

  void _onNameChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_onNameChanged);
    _lastNameController.addListener(_onNameChanged);
    _year = widget.profile.year;
    _faculties = widget.profile.faculties.toSet();
    _fieldsOfStudy = widget.profile.fieldsOfStudy.toSet();
    _degree = widget.profile.degree;
    _gender = widget.profile.gender;
    _avatarUrl = widget.profile.avatarUrl;
    _interests = {...widget.profile.hobbies, ...widget.profile.interests};
    _languages = widget.profile.languages.toSet();
  }

  /// First word = first name, remainder = last name — mirrors
  /// `CompleteProfileScreen`'s split, since only `full_name` exists in the
  /// schema.
  static (String, String) _splitName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return ('', '');
    final parts = trimmed.split(RegExp(r'\s+'));
    return (parts.first, parts.skip(1).join(' '));
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_onNameChanged);
    _lastNameController.removeListener(_onNameChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    // Checked in one pass, so a single tap flags every missing field at once.
    // Mirrors `Profile.isComplete` (and `CompleteProfileScreen._submit`):
    // saving a profile that the router's gate would call incomplete has to be
    // impossible, or the user is bounced to Complete Profile right after a
    // "successful" save.
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
      // A picker's error can be far enough down the form to be off screen —
      // the banner at the save button says why nothing happened.
      setState(() => _errorMessage = l10n.profileRequiredFieldsMissing);
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(saveProfileProvider)(
        fullName:
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        faculties: _faculties.toList(),
        fieldsOfStudy: _fieldsOfStudy.toList(),
        degree: _degree,
        gender: _gender,
        avatarUrl: _avatarUrl,
        clearAvatar: _avatarCleared,
        year: _year,
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        hobbies: _interests.toList(),
        interests: _interests.toList(),
        languages: _languages.toList(),
      );
      if (!mounted) return;
      ref.invalidate(myProfileProvider);
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = l10n.profileEditError;
      });
    }
  }

  /// Two-step, explicitly destructive confirmation before deleting. The
  /// account and its personal data are removed server-side by the
  /// `delete-account` edge function; the session is cleared afterwards, so
  /// the router drops back to the signed-out route on its own.
  ///
  /// Lives at the foot of this form rather than in the settings card: App
  /// Store Guideline 5.1.1(v) only asks that deletion be reachable from
  /// inside the app, not that it be prominent, and a red button sitting
  /// beside "Log out" read as a routine choice.
  Future<void> _confirmDeleteAccount(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profileDeleteAccountConfirmTitle),
        content: Text(l10n.profileDeleteAccountConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.profileDeleteAccountConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      // Drop this device's push token first: the RPC needs the auth context,
      // which is gone once the account is deleted.
      await ref.read(pushServiceProvider).unregisterToken();
      await ref.read(deleteAccountProvider)();
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(l10n.profileDeleteAccountError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileEditTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: AvatarPicker(
                  fullName: widget.profile.fullName,
                  avatarHue: widget.profile.avatarHue,
                  avatarUrl: _avatarUrl,
                  onUploaded: (url) => setState(() {
                    _avatarUrl = url;
                    _avatarCleared = false;
                  }),
                  onRemoved: () => setState(() {
                    _avatarUrl = null;
                    _avatarCleared = true;
                  }),
                ),
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _firstNameController,
                label: l10n.fieldFirstName,
                validator: (v) =>
                    Validators.requiredField(v, l10n.errorEnterFirstName),
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _lastNameController,
                label: l10n.fieldLastName,
                validator: (v) =>
                    Validators.requiredField(v, l10n.errorEnterLastName),
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const FullNameWarning(),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _bioController,
                label: l10n.profileAboutTitle,
                hint: l10n.profileBioHint,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              OptionListSearchableField(
                title: l10n.profileFieldOfStudyLabel,
                required: true,
                errorText: _fieldOfStudyMissing
                    ? l10n.errorSelectFieldOfStudy
                    : null,
                optionsProvider: _fieldOfStudyOptionsProvider,
                selected: _fieldsOfStudy,
                onChanged: (next) => setState(() {
                  _fieldsOfStudy = next;
                  if (next.isNotEmpty) _fieldOfStudyMissing = false;
                }),
              ),
              const SizedBox(height: 16),
              OptionListSearchableField(
                title: l10n.profileFacultyLabel,
                required: true,
                errorText: _facultyMissing ? l10n.errorSelectFaculty : null,
                optionsProvider: _facultyOptionsProvider,
                selected: _faculties,
                onChanged: (next) => setState(() {
                  _faculties = next;
                  if (next.isNotEmpty) _facultyMissing = false;
                }),
              ),
              const SizedBox(height: 16),
              RequiredFieldLabel(label: l10n.profileDegreeLabel),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, _) {
                  final optionsAsync = ref.watch(_degreeOptionsProvider);
                  return optionsAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (options) {
                      final language = Localizations.localeOf(
                        context,
                      ).languageCode;
                      final labels = {
                        for (final o in options.where((o) => o.active))
                          o.label: o.labelFor(language),
                      };
                      return FilterChipRow(
                        options: labels.keys.toList(),
                        selected: _degree ?? '',
                        onSelected: (label) => setState(() {
                          _degree = label;
                          _degreeMissing = false;
                        }),
                        labelBuilder: (value) => labels[value] ?? value,
                      );
                    },
                  );
                },
              ),
              RequiredFieldError(
                _degreeMissing ? l10n.errorSelectDegree : null,
              ),
              const SizedBox(height: 16),
              RequiredFieldLabel(label: l10n.profileGenderLabel),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final labels = {
                    for (final g in Gender.values) _genderLabel(l10n, g): g,
                  };
                  return FilterChipRow(
                    options: labels.keys.toList(),
                    selected: _gender == null
                        ? ''
                        : _genderLabel(l10n, _gender!),
                    onSelected: (label) => setState(() {
                      _gender = labels[label];
                      _genderMissing = false;
                    }),
                  );
                },
              ),
              RequiredFieldError(
                _genderMissing ? l10n.errorSelectGender : null,
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
              const SizedBox(height: 20),
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
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                InlineBanner(message: _errorMessage!, tone: BannerTone.error),
              ],
              const SizedBox(height: 24),
              PrimaryGradientButton(
                label: l10n.profileSaveAction,
                loading: _submitting,
                onPressed: _namesComplete ? () => _submit(l10n) : null,
              ),
              // Deliberately the quietest thing on the screen — plain black
              // text, no icon, no fill, below the save button — so it stays
              // reachable without competing with the form itself.
              const SizedBox(height: 28),
              Center(
                child: TextButton(
                  onPressed: _deleting
                      ? null
                      : () => _confirmDeleteAccount(l10n),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    // Small text, but the default tap target is left alone
                    // so it stays comfortably reachable.
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    _deleting
                        ? l10n.profileDeleteAccountInProgress
                        : l10n.profileDeleteAccountAction,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

String _genderLabel(AppLocalizations l10n, Gender gender) => switch (gender) {
  Gender.male => l10n.genderMale,
  Gender.female => l10n.genderFemale,
  Gender.undisclosed => l10n.genderUndisclosed,
};
