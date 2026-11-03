import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/searchable_multi_select_field.dart';
import '../../domain/entities/option_list_item.dart';

/// A [SearchableMultiSelectField] fed by an admin-curated option list
/// (faculty/field-of-study/language/interest), with loading/error/retry
/// chrome around the async fetch. Shared by both profile editing screens
/// (`CompleteProfileScreen`/`EditProfileScreen`) so they don't each hand-roll
/// the same async wrapper — previously duplicated as `_PickerSection` and
/// `_MultiSelectSection` respectively.
class OptionListSearchableField extends ConsumerWidget {
  const OptionListSearchableField({
    super.key,
    required this.title,
    required this.optionsProvider,
    required this.selected,
    required this.onChanged,
    this.required = false,
    this.errorText,
  });

  final String title;
  final AutoDisposeFutureProvider<List<OptionListItem>> optionsProvider;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool required;
  final String? errorText;

  Widget _titled(Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final optionsAsync = ref.watch(optionsProvider);

    return optionsAsync.when(
      loading: () => _titled(
        const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (err, _) => _titled(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.profileOptionsLoadError,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
            ),
            Text(
              '$err',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.destructive,
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => ref.invalidate(optionsProvider),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(l10n.actionRetry),
              ),
            ),
          ],
        ),
      ),
      data: (options) {
        final active = options
            .where((o) => o.active)
            .map((o) => o.label)
            .toList();
        final language = Localizations.localeOf(context).languageCode;
        // Selection keeps canonical values (that's what profiles store);
        // only the visible text is translated.
        final labels = {
          for (final o in options.where((o) => o.active))
            o.label: o.labelFor(language),
        };

        if (active.isEmpty) {
          return _titled(
            Text(
              l10n.profileOptionsEmpty,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
            ),
          );
        }
        return SearchableMultiSelectField(
          label: title,
          options: active,
          selected: selected,
          onChanged: onChanged,
          labelBuilder: (value) => labels[value] ?? value,
          required: required,
          errorText: errorText,
        );
      },
    );
  }
}
