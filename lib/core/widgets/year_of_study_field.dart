import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import 'auth_text_field.dart';
import 'required_field_label.dart';

/// Tap-to-select "year of study" field.
///
/// `year` is the academic year (1st–4th, or 5+), NOT a calendar year — the
/// Matches filter buckets on 1/2/3/4/+5 and profiles render "Year {n}". So this
/// offers those exact choices instead of a date picker or a free-text number,
/// which let users enter values the rest of the app can't interpret.
class YearOfStudyField extends StatefulWidget {
  const YearOfStudyField({
    super.key,
    required this.year,
    required this.onChanged,
    this.required = false,
    this.errorText,
  });

  /// Currently selected year, or null when unset.
  final int? year;
  final ValueChanged<int?> onChanged;

  /// Marks the label with the same red ` *` every other mandatory profile
  /// field uses. Display only — the caller still decides what to do about an
  /// empty value.
  final bool required;

  /// Validation message to show under the field, or null when satisfied.
  ///
  /// Not a [FormField] validator: the value is picked from a sheet, so the
  /// text field itself is read-only display and the owning screen tracks
  /// "missing" alongside its other picker flags.
  final String? errorText;

  @override
  State<YearOfStudyField> createState() => _YearOfStudyFieldState();
}

class _YearOfStudyFieldState extends State<YearOfStudyField> {
  /// Years offered. 5 stands for "5 or more", shown as "+5" to match the
  /// Matches filter's own `+5` bucket.
  static const _options = [1, 2, 3, 4, 5];

  static String _display(int year) => year >= 5 ? '+5' : '$year';
  static String _textFor(int? year) => year == null ? '' : _display(year);

  /// Display-only: the value lives in `widget.year`, and the field is
  /// read-only, so the two can't drift apart.
  late final _controller = TextEditingController(text: _textFor(widget.year));

  @override
  void didUpdateWidget(covariant YearOfStudyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.year != oldWidget.year) _controller.text = _textFor(widget.year);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick(AppLocalizations l10n) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                l10n.profileYearLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            for (final option in _options)
              ListTile(
                title: Text(
                  option >= 5
                      ? _display(option)
                      : l10n.profileYearShort(option),
                ),
                trailing: option == widget.year
                    ? const Icon(
                        Icons.check,
                        size: 18,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null) widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final field = AuthTextField(
      controller: _controller,
      label: widget.required
          ? '${l10n.profileYearLabel} *'
          : l10n.profileYearLabel,
      icon: Icons.school_outlined,
      readOnly: true,
      onTap: () => _pick(l10n),
    );
    if (widget.errorText == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field,
        RequiredFieldError(widget.errorText),
      ],
    );
  }
}
