import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One of the three small tappable tiles under the hero heading
/// (notifications / upcoming events / my events calendar).
class HomeStatCard extends StatelessWidget {
  const HomeStatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.label,
    this.count,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String label;
  final int? count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Count shown as a small corner badge on the icon — same
              // `Badge` treatment as the chat/notification icons in
              // `AppHeaderBar` — so both cards keep the identical
              // icon+label layout regardless of whether one has a count.
              Badge(
                label: Text('${count ?? 0}'),
                isLabelVisible: count != null && count! > 0,
                offset: const Offset(4, -4),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
