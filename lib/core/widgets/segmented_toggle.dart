import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SegmentOption<T> {
  const SegmentOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;

  /// Optional leading icon shown before [label] (e.g. the Surveys tabs).
  /// Omitted call sites keep the plain text-only look.
  final IconData? icon;
}

/// The pill-shaped two-way tab switcher used for "Login / Sign up" and
/// "Password / Email code". Options are laid out in a plain [Row], which
/// automatically mirrors for RTL locales via the ambient [Directionality]
/// — pass options in the same *logical* order as the reference web app's
/// DOM (see AuthScreen for the exact order that reproduces the screenshots).
class SegmentedToggle<T> extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.compact = false,
    this.selectedColor,
  });

  final List<SegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool compact;

  /// Text/icon color for the selected segment. Defaults to
  /// [AppColors.foreground] (every existing call site's look); pass e.g.
  /// [AppColors.primaryStrong] for a tinted selected state (Surveys tabs).
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _SegmentButton(
                label: option.label,
                icon: option.icon,
                selected: option.value == value,
                compact: compact,
                selectedColor: selectedColor ?? AppColors.foreground,
                onTap: () => onChanged(option.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.compact,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final bool compact;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : AppColors.mutedForeground;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(vertical: compact ? 8 : 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.foreground.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: compact ? 14 : 16, color: color),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 11 : 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
