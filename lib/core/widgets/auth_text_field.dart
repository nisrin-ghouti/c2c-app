import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// A form field styled to match the reference screens (rounded cream pill,
/// leading icon). Icon placement and the base reading order come for free
/// from the ambient [Directionality] — the only thing screens opt into
/// explicitly is [forceLtr] for fields whose *content* is always Latin
/// (emails, numeric OTP codes) even inside an RTL layout, matching the
/// reference app's `dir="ltr"` overrides on those same fields.
///
/// When [obscureText] is true the field is treated as a password: it renders a
/// show/hide "eye" toggle in the trailing corner so users can reveal what they
/// typed. That's why this is stateful — the reveal state lives here rather than
/// forcing every password screen to manage it.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.forceLtr = false,
    this.textAlign,
    this.style,
    this.maxLength,
    this.maxLines = 1,
    this.validator,
    this.autovalidateMode,
    this.onFieldSubmitted,
    this.autofillHints,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool forceLtr;
  final TextAlign? textAlign;
  final TextStyle? style;
  final int? maxLength;
  final int maxLines;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final void Function(String)? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  /// Blocks typing while keeping the field's look — pair with [onTap] for
  /// fields whose value is chosen from a picker rather than typed.
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  /// For password fields, whether the text is currently hidden. Starts hidden.
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPassword = widget.obscureText;

    return TextFormField(
      controller: widget.controller,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      obscureText: isPassword && _obscured,
      keyboardType: widget.keyboardType,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      style: widget.style,
      textAlign: widget.textAlign ?? TextAlign.start,
      textDirection: widget.forceLtr ? TextDirection.ltr : null,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      decoration: InputDecoration(
        labelText: widget.label.isEmpty ? null : widget.label,
        hintText: widget.hint,
        counterText: '',
        prefixIcon: widget.icon != null ? Icon(widget.icon, size: 20) : null,
        // Reveal toggle, password fields only.
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                tooltip: _obscured ? l10n.passwordShow : l10n.passwordHide,
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
      ),
    );
  }
}
