import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/segmented_toggle.dart';
import 'accessibility_controller.dart';
import 'accessibility_settings.dart';

/// Opens the accessibility settings sheet — text scale, reduce motion,
/// high contrast. All three are device-local (`AppPreferences`), take
/// effect immediately, and persist across launches.
void showAccessibilityPanel(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const AccessibilityPanel(),
  );
}

class AccessibilityPanel extends ConsumerWidget {
  const AccessibilityPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(accessibilitySettingsProvider);
    final controller = ref.read(accessibilitySettingsProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              l10n.accessibilityPanelTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.accessibilityTextSizeLabel,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            SegmentedToggle<TextScaleOption>(
              value: settings.textScale,
              options: [
                SegmentOption(
                  value: TextScaleOption.normal,
                  label: l10n.accessibilityTextSizeNormal,
                ),
                SegmentOption(
                  value: TextScaleOption.large,
                  label: l10n.accessibilityTextSizeLarge,
                ),
                SegmentOption(
                  value: TextScaleOption.extraLarge,
                  label: l10n.accessibilityTextSizeExtraLarge,
                ),
              ],
              onChanged: controller.setTextScale,
            ),
            const SizedBox(height: 20),
            _ToggleRow(
              label: l10n.accessibilityReduceMotionLabel,
              value: settings.reduceMotion,
              onChanged: controller.setReduceMotion,
            ),
            const SizedBox(height: 10),
            _ToggleRow(
              label: l10n.accessibilityHighContrastLabel,
              value: settings.highContrast,
              onChanged: controller.setHighContrast,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
