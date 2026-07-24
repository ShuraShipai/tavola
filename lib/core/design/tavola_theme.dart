import 'package:flutter/material.dart';

import 'tavola_colors.dart';
import 'tavola_status_colors.dart';
import 'tavola_tokens.dart';

abstract final class TavolaTheme {
  static const lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: TavolaColors.accent,
    onPrimary: TavolaColors.primary,
    primaryContainer: TavolaColors.accentLight,
    onPrimaryContainer: TavolaColors.primary,
    secondary: TavolaColors.secondary,
    onSecondary: TavolaColors.textInverse,
    secondaryContainer: TavolaColors.surfaceVariant,
    onSecondaryContainer: TavolaColors.textPrimary,
    tertiary: TavolaColors.accent,
    onTertiary: TavolaColors.primary,
    tertiaryContainer: TavolaColors.accentLight,
    onTertiaryContainer: TavolaColors.primary,
    error: TavolaColors.error,
    onError: TavolaColors.surface,
    errorContainer: TavolaColors.errorLight,
    onErrorContainer: TavolaColors.error,
    surface: TavolaColors.surface,
    onSurface: TavolaColors.textPrimary,
    surfaceContainerHighest: TavolaColors.surfaceVariant,
    onSurfaceVariant: TavolaColors.textSecondary,
    outline: TavolaColors.borderStrong,
    outlineVariant: TavolaColors.border,
    shadow: TavolaColors.shadow,
    scrim: TavolaColors.overlay,
    inverseSurface: TavolaColors.primary,
    onInverseSurface: TavolaColors.textInverse,
    inversePrimary: TavolaColors.accent,
  );

  static const darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: TavolaColors.accent,
    onPrimary: TavolaColors.primary,
    primaryContainer: TavolaColors.darkSurfaceVariant,
    onPrimaryContainer: TavolaColors.accentLight,
    secondary: TavolaColors.darkTextSecondary,
    onSecondary: TavolaColors.darkBackground,
    secondaryContainer: TavolaColors.darkSurfaceVariant,
    onSecondaryContainer: TavolaColors.darkTextPrimary,
    tertiary: TavolaColors.accent,
    onTertiary: TavolaColors.primary,
    tertiaryContainer: TavolaColors.darkSurfaceVariant,
    onTertiaryContainer: TavolaColors.accentLight,
    error: TavolaColors.error,
    onError: TavolaColors.surface,
    errorContainer: TavolaColors.errorLight,
    onErrorContainer: TavolaColors.error,
    surface: TavolaColors.darkSurface,
    onSurface: TavolaColors.darkTextPrimary,
    surfaceContainerHighest: TavolaColors.darkSurfaceVariant,
    onSurfaceVariant: TavolaColors.darkTextSecondary,
    outline: TavolaColors.darkBorder,
    outlineVariant: TavolaColors.darkBorder,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: TavolaColors.surface,
    onInverseSurface: TavolaColors.textPrimary,
    inversePrimary: TavolaColors.primary,
  );

  static ThemeData get light => _build(lightColorScheme, isDark: false);
  static ThemeData get dark => _build(darkColorScheme, isDark: true);

  static ThemeData _build(ColorScheme scheme, {required bool isDark}) {
    final textTheme = _textTheme(isDark: isDark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? TavolaColors.darkBackground
          : TavolaColors.background,
      fontFamily: 'Inter',
      textTheme: textTheme,
      iconTheme: IconThemeData(
        color: scheme.onSurfaceVariant,
        size: TavolaSize.iconLarge,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: TavolaRadius.large),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TavolaSpace.md,
          vertical: TavolaSpace.sm,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: TavolaColors.textMuted,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
        border: _inputBorder(scheme.outlineVariant),
        enabledBorder: _inputBorder(scheme.outlineVariant),
        focusedBorder: _inputBorder(scheme.tertiary, width: 2),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _buttonStyle(scheme)),
      filledButtonTheme: FilledButtonThemeData(style: _buttonStyle(scheme)),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, TavolaSize.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: TavolaSpace.md),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          shape: const RoundedRectangleBorder(
            borderRadius: TavolaRadius.medium,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(TavolaSize.touchTarget),
          foregroundColor: scheme.onSurfaceVariant,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: TavolaRadius.extraLarge,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: const RoundedRectangleBorder(borderRadius: TavolaRadius.medium),
      ),
      extensions: [
        TavolaStatusColors(
          success: TavolaColors.success,
          successContainer: TavolaColors.successLight,
          warning: TavolaColors.warning,
          warningContainer: TavolaColors.warningLight,
          info: TavolaColors.info,
          infoContainer: TavolaColors.infoLight,
        ),
      ],
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: TavolaRadius.medium,
        borderSide: BorderSide(color: color, width: width),
      );

  static ButtonStyle _buttonStyle(ColorScheme scheme) => FilledButton.styleFrom(
    minimumSize: const Size(0, TavolaSize.buttonHeight),
    padding: const EdgeInsets.symmetric(horizontal: TavolaSpace.md),
    backgroundColor: scheme.primary,
    foregroundColor: scheme.onPrimary,
    disabledBackgroundColor: TavolaColors.disabled,
    disabledForegroundColor: TavolaColors.disabledText,
    shape: const RoundedRectangleBorder(borderRadius: TavolaRadius.medium),
  );

  static TextTheme _textTheme({required bool isDark}) {
    final color = isDark
        ? TavolaColors.darkTextPrimary
        : TavolaColors.textPrimary;
    final secondary = isDark
        ? TavolaColors.darkTextSecondary
        : TavolaColors.textSecondary;
    return TextTheme(
      displayLarge: _text(34, FontWeight.w600, color, -0.68, 1.18),
      displayMedium: _text(28, FontWeight.w600, color, -0.42, 1.22),
      headlineLarge: _text(22, FontWeight.w600, color, -0.22, 1.27),
      headlineMedium: _text(18, FontWeight.w600, color, -0.09, 1.33),
      titleLarge: _text(18, FontWeight.w600, color, -0.09, 1.33),
      titleMedium: _text(15, FontWeight.w600, color, 0, 1.4),
      titleSmall: _text(14, FontWeight.w600, color, 0, 1.43),
      bodyLarge: _text(15, FontWeight.w400, secondary, 0, 1.6),
      bodyMedium: _text(14, FontWeight.w400, secondary, 0, 1.5),
      bodySmall: _text(13, FontWeight.w400, secondary, 0, 1.54),
      labelLarge: _text(14, FontWeight.w600, color, 0, 1.43),
      labelMedium: _text(13, FontWeight.w600, color, 0.13, 1.38),
      labelSmall: _text(12, FontWeight.w700, color, 0.6, 1.33),
    );
  }

  static TextStyle _text(
    double size,
    FontWeight weight,
    Color color,
    double letterSpacing,
    double height,
  ) => TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}
