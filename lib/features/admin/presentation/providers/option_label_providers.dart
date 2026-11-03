import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/option_list_item.dart';
import '../../domain/entities/option_list_type.dart';
import 'admin_providers.dart';

/// Options for one admin-curated list, cached for the whole app.
///
/// Not `autoDispose`: these lists are small, change rarely, and are read from
/// many screens at once (filters, forms, event cards, benefit cards). Letting
/// them drop between screens would re-fetch the same rows constantly.
final optionListProvider =
    FutureProvider.family<List<OptionListItem>, OptionListType>((ref, type) {
      return ref.watch(adminRepositoryProvider).listOptions(type);
    });

/// Translates a *stored* option value into the current app language.
///
/// Events and benefits persist their category as the canonical English label,
/// so display sites have a plain string and no id. This resolves that string
/// against the option list and returns the localized label — falling back to
/// the stored text when the list hasn't loaded yet, when the option was since
/// deleted, or when no translation was entered.
///
/// Always returns something printable: a category must never render blank
/// just because a lookup missed.
String localizedOptionLabel(
  WidgetRef ref,
  BuildContext context, {
  required OptionListType type,
  required String? storedLabel,
}) {
  final stored = storedLabel?.trim() ?? '';
  if (stored.isEmpty) return '';

  final options = ref.watch(optionListProvider(type)).valueOrNull;
  if (options == null) return stored;

  final languageCode = Localizations.localeOf(context).languageCode;
  for (final option in options) {
    if (option.label == stored) return option.labelFor(languageCode);
  }
  return stored;
}

/// [localizedOptionLabel] for a list of stored values, joined for display.
/// Returns an empty string for an empty list so callers can apply their own
/// placeholder.
String localizedOptionLabels(
  WidgetRef ref,
  BuildContext context, {
  required OptionListType type,
  required List<String> storedLabels,
  String separator = ', ',
}) {
  return storedLabels
      .map(
        (v) => localizedOptionLabel(ref, context, type: type, storedLabel: v),
      )
      .where((v) => v.isNotEmpty)
      .join(separator);
}

/// Renders a stored option value translated into the app language.
///
/// A widget rather than a plain function so it can be dropped into the many
/// `StatelessWidget` cards that show a category but have no `WidgetRef`.
class OptionLabelText extends ConsumerWidget {
  const OptionLabelText({
    super.key,
    required this.type,
    required this.value,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final OptionListType type;
  final String? value;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = localizedOptionLabel(
      ref,
      context,
      type: type,
      storedLabel: value,
    );
    return Text(label, style: style, maxLines: maxLines, overflow: overflow);
  }
}
