import 'package:flutter/material.dart';

class Palette {
  static const Color ink = Color(0xFF09090B);
  static const Color base = Color(0xFF100B0C);
  static const Color aubergine = Color(0xFF1A0E10);
  static const Color surface = Color(0xFF171113);
  static const Color card = Color(0xFF1F1517);
  static const Color cardWarm = Color(0xFF2A191B);
  static const Color border = Color(0xFF332427);
  static const Color borderWarm = Color(0xFF493033);
  static const Color text = Color(0xFFF8F5F2);
  static const Color muted = Color(0xFF9D8C90);
  static const Color faint = Color(0xFF716167);
  static const Color soft = Color(0xFFE6D8D1);
  static const Color red = Color(0xFFFF5A36);
  static const Color crimson = Color(0xFFEC1313);
  static const Color orange = Color(0xFFFFA63D);
  static const Color yellow = Color(0xFFFFD166);
  static const Color cyan = Color(0xFF53D1FF);
  static const Color green = Color(0xFF3DD598);
}

class PaletteLight {
  static const Color ink = Color(0xFF1A1213);
  static const Color base = Color(0xFFF6F1ED);
  static const Color aubergine = Color(0xFFF3E9E5);
  static const Color surface = Color(0xFFFFFBF8);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardWarm = Color(0xFFF6ECE7);
  static const Color border = Color(0xFFE5D7D0);
  static const Color borderWarm = Color(0xFFDABBB1);
  static const Color text = Color(0xFF221718);
  static const Color muted = Color(0xFF7B6668);
  static const Color faint = Color(0xFF9A8688);
  static const Color soft = Color(0xFF5C4E51);
  static const Color red = Color(0xFFE94B2B);
  static const Color crimson = Color(0xFFC73631);
  static const Color orange = Color(0xFFD97706);
  static const Color yellow = Color(0xFFCA8A04);
  static const Color cyan = Color(0xFF0284C7);
  static const Color green = Color(0xFF0F9F6E);
}

extension SpetoTextStyles on BuildContext {
  ThemeData get _spetoTheme => Theme.of(this);
  bool get _spetoIsDark => _spetoTheme.brightness == Brightness.dark;

  Color get spetoSupportColor => _spetoIsDark
      ? Palette.soft.withValues(alpha: 0.78)
      : PaletteLight.soft.withValues(alpha: 0.88);

  Color get spetoMetaColor => _spetoIsDark
      ? Palette.soft.withValues(alpha: 0.72)
      : PaletteLight.soft.withValues(alpha: 0.82);

  TextStyle? spetoScreenTitleStyle({
    Color? color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return _spetoTheme.textTheme.titleLarge?.copyWith(
      fontSize: fontSize ?? 17,
      fontWeight: fontWeight,
      letterSpacing: -0.2,
      height: 1.08,
      color: color ?? _spetoTheme.colorScheme.onSurface,
    );
  }

  TextStyle? spetoSectionTitleStyle({
    Color? color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return _spetoTheme.textTheme.titleLarge?.copyWith(
      fontSize: fontSize ?? 16.5,
      fontWeight: fontWeight,
      letterSpacing: -0.3,
      height: 1.12,
      color: color ?? _spetoTheme.colorScheme.onSurface,
    );
  }

  TextStyle? spetoFeatureTitleStyle({
    Color? color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w800,
    double height = 1.15,
  }) {
    return _spetoTheme.textTheme.headlineSmall?.copyWith(
      fontSize: fontSize ?? 26,
      fontWeight: fontWeight,
      letterSpacing: -0.85,
      height: height,
      color: color ?? _spetoTheme.colorScheme.onSurface,
    );
  }

  TextStyle? spetoCardTitleStyle({
    Color? color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return _spetoTheme.textTheme.bodyLarge?.copyWith(
      fontSize: fontSize ?? 15.5,
      fontWeight: fontWeight,
      letterSpacing: -0.15,
      height: 1.16,
      color: color ?? _spetoTheme.colorScheme.onSurface,
    );
  }

  TextStyle? spetoDescriptionStyle({
    Color? color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.55,
  }) {
    return _spetoTheme.textTheme.bodyMedium?.copyWith(
      fontSize: fontSize ?? 13.5,
      fontWeight: fontWeight,
      letterSpacing: -0.15,
      height: height,
      color: color ?? spetoSupportColor,
    );
  }

  TextStyle? spetoMetaStyle({
    Color? color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w300,
    double height = 1.32,
  }) {
    return _spetoTheme.textTheme.bodySmall?.copyWith(
      fontSize: fontSize ?? 11.2,
      fontWeight: fontWeight,
      letterSpacing: 0,
      height: height,
      color: color ?? spetoMetaColor,
    );
  }

  TextStyle? spetoOverlineStyle({
    Color? color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w900,
  }) {
    return _spetoTheme.textTheme.labelLarge?.copyWith(
      fontSize: fontSize ?? 11,
      fontWeight: fontWeight,
      letterSpacing: 2.8,
      color: color ?? (_spetoIsDark ? Palette.orange : PaletteLight.orange),
    );
  }
}
