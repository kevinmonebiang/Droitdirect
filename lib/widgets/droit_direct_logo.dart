import 'package:flutter/material.dart';

class DroitDirectLogo extends StatelessWidget {
  const DroitDirectLogo({
    super.key,
    this.size = 76,
    this.showWordmark = true,
    this.textColor,
  });

  final double size;
  final bool showWordmark;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 2.0);
    const asset = 'assets/branding/logo.png';
    final dimension = showWordmark ? size * 1.16 : size;

    return SizedBox(
      width: dimension,
      height: dimension,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        cacheWidth: (dimension * pixelRatio).round(),
        cacheHeight: (dimension * pixelRatio).round(),
      ),
    );
  }
}
