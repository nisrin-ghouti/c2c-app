import 'package:flutter/material.dart';

/// The C2C wordmark, as supplied (`assets/logo/logo_transparent.png`).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height = 96});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/logo_transparent.png',
      height: height,
      filterQuality: FilterQuality.high,
    );
  }
}
