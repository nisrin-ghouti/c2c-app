import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';

/// A tap-to-expand multi-select field: shows the current selection as
/// removable chips (or a placeholder), and opens a searchable, alphabetized
/// checklist in a bottom sheet. Replaces [options]-as-a-flat-`Wrap` widgets
/// (`MultiSelectChips`) for fields expected to grow into long lists
/// (Faculty, Field of Study, Languages, Interests) where scrolling a wall of
/// chips stops being practical.
class SearchableMultiSelectField extends StatelessWidget {
  const SearchableMultiSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.labelBuilder,
    this.required = false,
    this.errorText,
  });

  final String label;

  /// Canonical values, unsorted — this widget alphabetizes by display label.
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  /// Maps a stored option value to its display text, so the sheet/chips show
  /// a translated label while [selected] stays in canonical values.
  final String Function(String value)? labelBuilder;

  final bool required;
  final String? errorText;

  String _labelFor(String value) => labelBuilder?.call(value) ?? value;

  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SearchableMultiSelectSheet(
        title: label,
        options: options,
        selected: selected,
        onChanged: onChanged,
        labelBuilder: labelBuilder,
        searchHint: l10n.searchableFieldSearchHint,
        doneLabel: l10n.searchableFieldDone,
        emptyLabel: l10n.searchableFieldNoMatches,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.foreground,
            ),
            children: [
              TextSpan(text: label),
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.destructive),
                ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.searchableFieldMultipleHint,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _open(context),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: selected.isEmpty
                      ? Text(
                          l10n.searchableFieldPlaceholder,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedForeground,
                          ),
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final value in selected)
                              Chip(
                                label: Text(_labelFor(value)),
                                labelStyle: const TextStyle(fontSize: 12),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                side: BorderSide.none,
                                onDeleted: () =>
                                    onChanged({...selected}..remove(value)),
                              ),
                          ],
                        ),
                ),
                const Icon(
                  Icons.expand_more,
                  size: 20,
                  color: AppColors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: const TextStyle(fontSize: 12, color: AppColors.destructive),
          ),
        ],
      ],
    );
  }
}

class _SearchableMultiSelectSheet extends StatefulWidget {
  const _SearchableMultiSelectSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.searchHint,
    required this.doneLabel,
    required this.emptyLabel,
    this.labelBuilder,
  });

  final String title;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final String Function(String value)? labelBuilder;
  final String searchHint;
  final String doneLabel;
  final String emptyLabel;

  @override
  State<_SearchableMultiSelectSheet> createState() =>
      _SearchableMultiSelectSheetState();
}

class _SearchableMultiSelectSheetState
    extends State<_SearchableMultiSelectSheet> {
  late final Set<String> _selected = {...widget.selected};
  final _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  String _labelFor(String value) => widget.labelBuilder?.call(value) ?? value;

  void _toggle(String value) {
    setState(() {
      if (_selected.contains(value)) {
        _selected.remove(value);
      } else {
        _selected.add(value);
      }
    });
    widget.onChanged({..._selected});
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.options]
      ..sort(
        (a, b) =>
            _labelFor(a).toLowerCase().compareTo(_labelFor(b).toLowerCase()),
      );
    final filtered = _query.trim().isEmpty
        ? sorted
        : sorted
              .where(
                (v) => _labelFor(
                  v,
                ).toLowerCase().contains(_query.trim().toLowerCase()),
              )
              .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        widget.emptyLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final value = filtered[index];
                        return CheckboxListTile(
                          value: _selected.contains(value),
                          onChanged: (_) => _toggle(value),
                          title: Text(_labelFor(value)),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(widget.doneLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
