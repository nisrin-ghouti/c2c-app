import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/filter_chip_row.dart';
import '../../../../core/widgets/searchable_multi_select_field.dart';
import '../../../admin/domain/entities/option_list_type.dart';
import '../../../admin/presentation/providers/option_label_providers.dart';
import '../../../admin/presentation/providers/admin_providers.dart';
import '../../../auth/domain/entities/gender.dart';
import '../../domain/entities/match_candidate.dart';
import 'match_filters.dart';

final _filterOptionsProvider = FutureProvider.autoDispose
    .family<List<String>, OptionListType>((ref, type) async {
      final items = await ref.watch(adminRepositoryProvider).listOptions(type);
      return items.where((o) => o.active).map((o) => o.label).toList();
    });

/// Interests merges the curated `hobby` + `interest` option lists, mirroring
/// the same merge used on the profile-edit screens.
final _mergedInterestFilterOptionsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
      final repo = ref.watch(adminRepositoryProvider);
      final lists = await Future.wait([
        repo.listOptions(OptionListType.interest),
        repo.listOptions(OptionListType.hobby),
      ]);
      final labels = <String>{};
      for (final list in lists) {
        labels.addAll(list.where((o) => o.active).map((o) => o.label));
      }
      return labels.toList();
    });

class MatchFiltersPanel extends ConsumerWidget {
  const MatchFiltersPanel({
    super.key,
    required this.candidates,
    required this.filters,
    required this.onChanged,
    required this.onApply,
  });

  final List<MatchCandidate> candidates;
  final MatchFilters filters;
  final ValueChanged<MatchFilters> onChanged;

  /// Called when the user taps "Apply filters" — the parent collapses the
  /// panel so picking filters ends with one clear, deliberate confirmation
  /// step instead of just trailing off.
  final VoidCallback onApply;

  bool get _hasActiveFilters =>
      filters.faculty.isNotEmpty ||
      filters.fieldOfStudy.isNotEmpty ||
      filters.language.isNotEmpty ||
      filters.interests.isNotEmpty ||
      filters.degree != filters.allLabel ||
      filters.year != filters.allLabel ||
      filters.gender != filters.allLabel;

  List<String> _multiOptionsFor(
    WidgetRef ref,
    AutoDisposeFutureProvider<List<String>> curatedProvider,
    List<String> Function(MatchCandidate) selector,
  ) {
    final curated = ref.watch(curatedProvider).valueOrNull ?? const [];
    final present = optionsForListField(candidates, selector);
    return {...curated, ...present}.toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Text(
                  l10n.filtersTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              if (_hasActiveFilters)
                TextButton(
                  onPressed: () => onChanged(
                    MatchFilters(
                      allLabel: filters.allLabel,
                      searchQuery: filters.searchQuery,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.destructive,
                  ),
                  child: Text(l10n.filtersClearAll),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SearchableMultiSelectField(
            label: l10n.filterFacultyLabel,
            options: _multiOptionsFor(
              ref,
              _filterOptionsProvider(OptionListType.faculty),
              (c) => c.facultyValues,
            ),
            selected: filters.faculty,
            onChanged: (next) => onChanged(filters.copyWith(faculty: next)),
            labelBuilder: (value) => localizedOptionLabel(
              ref,
              context,
              type: OptionListType.faculty,
              storedLabel: value,
            ),
          ),
          const SizedBox(height: 12),
          SearchableMultiSelectField(
            label: l10n.filterFieldOfStudyLabel,
            options: _multiOptionsFor(
              ref,
              _filterOptionsProvider(OptionListType.fieldOfStudy),
              (c) => c.fieldOfStudyValues,
            ),
            selected: filters.fieldOfStudy,
            onChanged: (next) =>
                onChanged(filters.copyWith(fieldOfStudy: next)),
            labelBuilder: (value) => localizedOptionLabel(
              ref,
              context,
              type: OptionListType.fieldOfStudy,
              storedLabel: value,
            ),
          ),
          const SizedBox(height: 12),
          SearchableMultiSelectField(
            label: l10n.filterLanguageLabel,
            options: _multiOptionsFor(
              ref,
              _filterOptionsProvider(OptionListType.language),
              (c) => c.languages,
            ),
            selected: filters.language,
            onChanged: (next) => onChanged(filters.copyWith(language: next)),
            labelBuilder: (value) => localizedOptionLabel(
              ref,
              context,
              type: OptionListType.language,
              storedLabel: value,
            ),
          ),
          const SizedBox(height: 12),
          SearchableMultiSelectField(
            label: l10n.profileInterestsLabel,
            options: () {
              final curated =
                  ref.watch(_mergedInterestFilterOptionsProvider).valueOrNull ??
                  const [];
              final present = optionsForListField(
                candidates,
                (c) => c.mergedInterests.toList(),
              );
              return {...curated, ...present}.toList();
            }(),
            selected: filters.interests,
            onChanged: (next) => onChanged(filters.copyWith(interests: next)),
            labelBuilder: (value) {
              final fromInterest = localizedOptionLabel(
                ref,
                context,
                type: OptionListType.interest,
                storedLabel: value,
              );
              return fromInterest != value
                  ? fromInterest
                  : localizedOptionLabel(
                      ref,
                      context,
                      type: OptionListType.hobby,
                      storedLabel: value,
                    );
            },
          ),
          const SizedBox(height: 10),
          _SingleFilterRow(
            label: l10n.filterDegreeLabel,
            options: optionsForField(
              candidates,
              filters.allLabel,
              (c) => c.degree,
            ),
            optionType: OptionListType.degree,
            selected: filters.degree,
            onSelected: (v) => onChanged(filters.copyWith(degree: v)),
          ),
          _SingleFilterRow(
            label: l10n.filterYearLabel,
            options: yearOptions(candidates, filters.allLabel),
            selected: filters.year,
            onSelected: (v) => onChanged(filters.copyWith(year: v)),
          ),
          _SingleFilterRow(
            label: l10n.filterGenderLabel,
            options: genderOptions(filters.allLabel),
            selected: filters.gender,
            labelBuilder: (value) => switch (Gender.fromDbValue(value)) {
              Gender.male => l10n.genderMale,
              Gender.female => l10n.genderFemale,
              Gender.undisclosed => l10n.genderUndisclosed,
              null => value,
            },
            onSelected: (v) => onChanged(filters.copyWith(gender: v)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onApply,
              child: Text(l10n.filtersApply),
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleFilterRow extends ConsumerWidget {
  const _SingleFilterRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.optionType,
    this.labelBuilder,
  });

  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  /// For admin-curated option lists (faculty/degree/…) — looks the label up
  /// via [localizedOptionLabel].
  final OptionListType? optionType;

  /// For fixed, non-curated value sets (e.g. gender) — takes precedence over
  /// [optionType] when both would otherwise apply.
  final String Function(String value)? labelBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          FilterChipRow(
            options: options,
            selected: selected,
            onSelected: onSelected,
            labelBuilder:
                labelBuilder ??
                (optionType == null
                    ? null
                    : (value) => localizedOptionLabel(
                        ref,
                        context,
                        type: optionType!,
                        storedLabel: value,
                      )),
          ),
        ],
      ),
    );
  }
}
