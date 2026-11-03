import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';

class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;

  /// No longer shown as visible text (icon-only bar) — kept for
  /// accessibility (`Semantics`/`Tooltip`).
  final String label;
}

/// The 5-tab bottom bar: a floating rounded pill, icon-only, with the
/// selected (non-center) tab shown as a solid rounded-square badge behind
/// its icon. Replaces Material's [NavigationBar], which renders every
/// destination identically — this design also needs the middle one (Scan,
/// the app's primary action) rendered as a raised gradient circle that
/// floats half-out of the bar, sitting on a white halo "notch".
///
/// [items] stay in *logical* (reading-order) sequence — Home first, Profile
/// last — so the [Row] mirrors them for RTL locales exactly the way
/// [NavigationBar] did, with Scan staying centered either way.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
    this.centerIndex = 2,
    this.itemWrapper,
  });

  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  /// Which destination gets the enlarged floating treatment.
  final int centerIndex;

  /// Optionally wraps one tab's widget by index — lets an ancestor (e.g. a
  /// coach-mark tour) spotlight a specific tab (wrap it in `Showcase(...)`)
  /// without this widget needing to know anything about the tour library.
  final Widget Function(int index, Widget child)? itemWrapper;

  @override
  Widget build(BuildContext context) {
    // The device's own bottom inset (gesture bar / home indicator) goes into
    // the OUTER margin below the floating pill, not a `SafeArea` squeezed
    // inside a fixed-height box — that was the actual bug: `SafeArea`
    // padded the *inside* of the pill, pushing the icon row upward and
    // leaving a visibly bigger gap under the icons than above them.
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 20 + bottomInset),
      child: Container(
        // No `clipBehavior` on purpose — the center circle intentionally
        // overflows both the top *and* bottom edges to create the raised
        // "poking through" look.
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.foreground.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SizedBox(
          height: 54,
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final child = index == centerIndex
                          ? _CenterNavItem(
                              item: items[index],
                              selected: index == currentIndex,
                              onTap: () => onSelect(index),
                            )
                          : _NavItem(
                              item: items[index],
                              selected: index == currentIndex,
                              onTap: () => onSelect(index),
                            );
                      return itemWrapper?.call(index, child) ?? child;
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: Tooltip(
        message: item.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          // Explicit ripple tints — without these, InkWell falls back to the
          // ambient Material defaults, which read as a washed-out pink here.
          splashColor: AppColors.foreground.withValues(alpha: 0.12),
          highlightColor: AppColors.foreground.withValues(alpha: 0.08),
          child: Center(
            // Selected = solid dark rounded-square badge behind a white
            // icon; idle = plain muted icon, no background — matches the
            // icon-only reference design.
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected ? AppColors.foreground : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                size: 23,
                color: selected ? Colors.white : AppColors.mutedForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The floating middle destination, matching the reference design: a
/// primary-gradient circle (always gradient — selected or not, exactly like
/// the mock) sitting on a white circular halo that overflows above the bar's
/// top edge to form the raised "notch" bump. Deliberately kept larger than
/// the other (icon-only) tabs — the app's primary action.
class _CenterNavItem extends StatelessWidget {
  const _CenterNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  static const double _circleSize = 58;
  static const double _haloPadding = 5;
  static const double _barHeight = 54;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: Tooltip(
        message: item.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          splashColor: AppColors.primaryStrong.withValues(alpha: 0.12),
          highlightColor: AppColors.primaryStrong.withValues(alpha: 0.08),
          child: Center(
            // The halo is taller than the bar itself and centered on the
            // slot (via OverflowBox's default center alignment), so it
            // overflows evenly above the top edge and below the bottom edge
            // instead of sitting flush with one side.
            child: SizedBox(
              height: _barHeight,
              child: OverflowBox(
                maxWidth: _circleSize + _haloPadding * 2 + 4,
                maxHeight: _circleSize + _haloPadding * 2 + 4,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(_haloPadding),
                  decoration: BoxDecoration(
                    // White halo — reads as the bar's edge curving around
                    // the button, exactly like the reference image.
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    // The primary ring is the selected indicator.
                    border: Border.all(
                      color: selected
                          ? AppColors.primaryStrong
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    width: _circleSize,
                    height: _circleSize,
                    decoration: BoxDecoration(
                      // Always the primary gradient — matching the mock,
                      // where the QR button is lavender→blue even at rest.
                      gradient: AppGradients.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      selected ? item.selectedIcon : item.icon,
                      size: 29,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
