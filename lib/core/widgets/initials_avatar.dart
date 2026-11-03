import 'package:flutter/material.dart';

/// Colored circle avatar built from a profile's `avatar_hue` + initials —
/// the reference app's fallback for students without an uploaded photo.
/// Shared across features (home's "new students", matches' candidate list)
/// since it's a pure presentational leaf widget with no feature logic.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.initials,
    required this.hue,
    this.imageUrl,
    this.size = 48,
  });

  final String initials;
  final int hue;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.68).toColor();

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl!),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}
