import 'package:flutter/material.dart';

class AppLogoHeader extends StatelessWidget {
  const AppLogoHeader({
    super.key,
    this.height = 24,
    this.width,
    this.logoAsset = 'assets/logo/logo_full.png',
  });

  final double height;
  final double? width;
  final String logoAsset;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      logoAsset,
      height: height,
      width: width,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
