import 'package:flutter/painting.dart';

import 'app_theme.dart';

/// Text style using the bundled Inter variable font, so typography works with
/// no network connection. Weight is set through the font's `wght` axis.
TextStyle txt(
  double size, {
  Color color = AppColors.textPrimary,
  int weight = 400,
  double? spacing,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'Inter',
    fontSize: size,
    color: color,
    letterSpacing: spacing,
    height: height,
    fontVariations: [FontVariation('wght', weight.toDouble())],
  );
}
