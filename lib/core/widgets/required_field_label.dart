import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Section label for a mandatory picker that isn't a [FormField] — the
/// degree, gender and year-of-study rows on the two profile screens.
///
/// Those are chip/sheet pickers, so a plain [Form] validator can't reach them
/// and each screen tracks its own "missing" flag instead. This renders the
/// label and that flag's message in the same shape
/// `SearchableMultiSelectField` already uses for its own required fields (bold
/// 13px label, red ` *` suffix, 12px destructive error underneath), so a
/// mandatory chip picker is indistinguishable from a mandatory search field.
class RequiredFieldLabel extends StatelessWidget {
  const RequiredFieldLabel({
    super.key,
    required this.label,
    this.required = true,
  });

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
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
    );
  }
}

/// The validation message under a mandatory picker, or nothing when [message]
/// is null. Matches `SearchableMultiSelectField`'s own error styling and
/// spacing so every required field on a profile form reads the same.
class RequiredFieldError extends StatelessWidget {
  const RequiredFieldError(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, color: AppColors.destructive),
      ),
    );
  }
}
