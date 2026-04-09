import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'palette.dart';

class AppTheme {
  static ThemeData build({bool isDark = true}) {
    final ThemeData base = isDark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    final Color primaryColor = isDark ? Palette.red : PaletteLight.red;
    final Color textColor = isDark ? Palette.text : PaletteLight.text;
    final Color baseColor = isDark ? Palette.base : PaletteLight.base;
    final Color cardColor = isDark ? Palette.card : PaletteLight.card;
    final Color warmCardColor = isDark ? Palette.cardWarm : PaletteLight.cardWarm;
    final Color borderColor = isDark ? Palette.border : PaletteLight.border;
    final Color surfaceColor = isDark
        ? Palette.surface
        : PaletteLight.surface;
    final Color errorColor = isDark ? Palette.crimson : PaletteLight.crimson;
    final Color secondaryColor = isDark
        ? Palette.orange
        : PaletteLight.orange;
    final Color mutedColor = isDark ? Palette.muted : PaletteLight.muted;
    final Color iconColor = isDark ? Palette.soft : PaletteLight.soft;
    final ColorScheme scheme = (isDark
            ? const ColorScheme.dark()
            : const ColorScheme.light())
        .copyWith(
          primary: primaryColor,
          secondary: secondaryColor,
          surface: surfaceColor,
          onSurface: textColor,
          onPrimary: Colors.white,
          onSecondary: isDark ? Palette.ink : Colors.white,
          error: errorColor,
          outline: borderColor,
          shadow: Colors.black,
        );

    final TextTheme baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);
    final TextTheme appliedTextTheme = baseTextTheme.apply(
      bodyColor: textColor,
      displayColor: textColor,
    );
    final TextTheme textTheme = appliedTextTheme.copyWith(
      bodyLarge: appliedTextTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: appliedTextTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      bodySmall: appliedTextTheme.bodySmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w300,
        height: 1.35,
      ),
    );

    return base.copyWith(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: baseColor,
      canvasColor: baseColor,
      cardColor: cardColor,
      colorScheme: scheme,
      textTheme: textTheme,
      dividerColor: borderColor,
      splashColor: primaryColor.withValues(alpha: isDark ? 0.12 : 0.08),
      highlightColor: primaryColor.withValues(alpha: isDark ? 0.08 : 0.05),
      iconTheme: IconThemeData(color: iconColor),
      dividerTheme: DividerThemeData(
        color: borderColor.withValues(alpha: isDark ? 0.9 : 1),
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: iconColor),
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: borderColor.withValues(alpha: isDark ? 0.7 : 1),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: warmCardColor,
        hintStyle: textTheme.bodyMedium?.copyWith(color: mutedColor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _inputBorder(borderColor),
        enabledBorder: _inputBorder(borderColor),
        focusedBorder: _inputBorder(primaryColor, width: 1.3),
        errorBorder: _inputBorder(errorColor),
        focusedErrorBorder: _inputBorder(errorColor, width: 1.3),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStatePropertyAll(
          borderColor.withValues(alpha: isDark ? 0.8 : 1),
        ),
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return isDark ? Palette.text : PaletteLight.card;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.34);
          }
          return borderColor.withValues(alpha: isDark ? 0.48 : 0.72);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: warmCardColor,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: textColor),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withValues(alpha: 0.26),
        selectionHandleColor: primaryColor,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
