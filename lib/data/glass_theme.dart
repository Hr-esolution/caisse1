import 'package:flutter/material.dart';
import '../theme/sushi_design.dart';

/// Compatibility layer that maps legacy Glass* APIs to the Sushi Bold Flat Vivid system.

class GlassColors {
  static const Color sushi = SushiColors.red;
  static const Color sushiDark = SushiColors.redDark;
  static const Color sushiLight = SushiColors.redLight;

  static const Color redAccent = SushiColors.red;
  static const Color redAccentDark = SushiColors.redDark;
  static const Color redAccentLight = SushiColors.redLight;

  static const Color glassWhite = SushiColors.white;
  static const Color glassBorder = SushiColors.divider;
  static const Color glassHighlight = SushiColors.surface;
  static const Color glassLight = SushiColors.surface;
  static const Color glassMid = SushiColors.surface;
  static const Color glassDark = SushiColors.inkSoft;
  static const Color glassText = SushiColors.ink;
  static const Color glassShadow = SushiColors.ink;

  static const Color bgLight = SushiColors.bg;
  static const Color bgDark = SushiColors.inkSoft;
}

class GlassThemeData {
  static BoxDecoration glassContainerLight({
    double blurSigma = 0,
    Color? borderColor,
    double borderWidth = 1,
    List<BoxShadow>? shadows,
  }) =>
      SushiDeco.card(
        selected: false,
      ).copyWith(
        border: Border.all(
          color: borderColor ?? SushiColors.divider,
          width: borderWidth,
        ),
        boxShadow: shadows,
      );

  static BoxDecoration glassContainerDark({
    double blurSigma = 0,
    Color? borderColor,
    double borderWidth = 1,
  }) =>
      SushiDeco.card(selected: true);

  static BoxDecoration glassCard({
    required bool isHovered,
    Color? accentColor,
  }) =>
      SushiDeco.card(selected: isHovered);

  static LinearGradient accentGradient({Color? startColor, Color? endColor}) =>
      SushiGradients.primary;

  static LinearGradient backgroundGradient() => SushiGradients.hero;

  static BoxDecoration glassBadge({
    required Color color,
    bool isActive = false,
  }) =>
      SushiDeco.badge(bg: isActive ? color : SushiColors.redPale);
}

class GlassTypography {
  static const TextStyle headline1 = SushiTypo.h1;
  static const TextStyle headline2 = SushiTypo.h2;
  static const TextStyle bodyRegular = SushiTypo.bodyLg;
  static const TextStyle bodySmall = SushiTypo.bodySm;
  static const TextStyle label = SushiTypo.caption;
  static const TextStyle button = SushiTypo.btnMd;
}

class GlassButtonStyle {
  static ButtonStyle primary() => SushiButtonStyle.primary();
  static ButtonStyle secondary() => SushiButtonStyle.secondary();
}

class GlassPane extends StatelessWidget {
  const GlassPane({
    super.key,
    required this.child,
    this.decoration,
    this.padding,
    this.borderRadius,
  });

  final Widget child;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(SushiSpace.lg),
      decoration: decoration ?? SushiDeco.card(),
      child: child,
    );
  }
}

ThemeData glassTheme() => sushiTheme();

ThemeData sushiTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: SushiColors.red,
    primary: SushiColors.red,
    secondary: SushiColors.orange,
    surface: SushiColors.white,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: SushiColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: SushiColors.white,
      foregroundColor: SushiColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: const TextTheme(
      displayLarge: SushiTypo.display,
      headlineLarge: SushiTypo.h1,
      headlineSmall: SushiTypo.h2,
      titleMedium: SushiTypo.h3,
      bodyLarge: SushiTypo.bodyLg,
      bodyMedium: SushiTypo.bodySm,
      labelSmall: SushiTypo.caption,
      bodySmall: SushiTypo.caption,
    ),
    elevatedButtonTheme:
        ElevatedButtonThemeData(style: SushiButtonStyle.primary()),
    outlinedButtonTheme:
        OutlinedButtonThemeData(style: SushiButtonStyle.secondary()),
    textButtonTheme: TextButtonThemeData(style: SushiButtonStyle.secondary()),
    cardTheme: CardThemeData(
      color: SushiColors.white,
      shadowColor: SushiColors.ink,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SushiRadius.xl),
        side: const BorderSide(color: SushiColors.divider, width: 1),
      ),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SushiColors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SushiSpace.md,
        vertical: SushiSpace.sm,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SushiRadius.lg),
        borderSide: const BorderSide(color: SushiColors.divider, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SushiRadius.lg),
        borderSide: const BorderSide(color: SushiColors.divider, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SushiRadius.lg),
        borderSide: const BorderSide(color: SushiColors.red, width: 2),
      ),
      labelStyle: SushiTypo.bodySm,
      hintStyle: SushiTypo.bodySm,
    ),
    dividerColor: SushiColors.divider,
  );
}

class AppColors {
  static const deepTeal = SushiColors.red;
  static const burntOrange = SushiColors.orange;
  static const livingCoral = SushiColors.redLight;
  static const offWhite = SushiColors.white;
  static const charcoalDark = SushiColors.ink;
  static const neutralLight = SushiColors.surface;
  static const cloudDancer = SushiColors.white;
  static const taupeDore = SushiColors.surface;
  static const grisModerne = SushiColors.inkMid;
  static const charbon = SushiColors.ink;
  static const blancPur = SushiColors.white;
  static const terraCotta = SushiColors.red;
  static const bleuGris = SushiColors.teal;
  static const grisLeger = SushiColors.divider;
  static const grisPale = SushiColors.surface;
}

class AppSpacing {
  static const xs = SushiSpace.xs;
  static const sm = SushiSpace.sm;
  static const md = SushiSpace.md;
  static const lg = SushiSpace.lg;
  static const xl = SushiSpace.xl;
  static const xxl = SushiSpace.xxl;
}

class AppTypography {
  static const headline1 = SushiTypo.h1;
  static const headline2 = SushiTypo.h2;
  static const bodyLarge = SushiTypo.bodyLg;
  static const bodySmall = SushiTypo.bodySm;
  static const caption = SushiTypo.caption;
  static const button = SushiTypo.btnMd;
}
