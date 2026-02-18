import 'package:flutter/material.dart';

// ============================================================================
// COULEURS GLASSMORPHISM - SUSHI & RED ACCENT
// ============================================================================

class GlassColors {
  // Couleur Sushi Pantone (rose-corail apaisé)
  static const Color sushi = Color(0xFFE8A99F);
  static const Color sushiDark = Color(0xFFD98276);
  static const Color sushiLight = Color(0xFFF5C5BB);

  // Red Accent (rouge vibrant)
  static const Color redAccent = Color(0xFFD63031);
  static const Color redAccentDark = Color(0xFFA91F1F);
  static const Color redAccentLight = Color(0xFFFF5555);

  // Neutrals / Glass (lock-screen values)
  static const Color overlayStart = Color.fromRGBO(255, 255, 255, 0.0);
  static const Color overlayEnd = Color.fromRGBO(255, 255, 255, 0.0);
  static const Color glassWhite = Color.fromRGBO(255, 255, 255, 0.38);
  static const Color glassBorder = Color.fromRGBO(255, 255, 255, 0.28);
  static const Color glassHighlight = Color.fromRGBO(255, 255, 255, 0.18);
  static const Color glassLight = Color.fromRGBO(255, 255, 255, 0.46);
  static const Color glassMid = Color.fromRGBO(255, 255, 255, 0.56);
  static const Color glassDark = Color(0xFF0F0F0F);
  static const Color glassText = Color(0xFF161616);
  static const Color glassShadow = Color.fromRGBO(0, 0, 0, 0.35);

  // Backgrounds
  static const Color bgDark = Color(0xFF0F0F0F);
  static const Color bgLight = Color(0xFFFEFEFE);
}

// ============================================================================
// THEME GLASSMORPHISM
// ============================================================================

class GlassThemeData {
  // ---- GLASS SURFACES ----
  static BoxDecoration glassContainerLight({
    double blurSigma = 8,
    Color? borderColor,
    double borderWidth = 1,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      color: GlassColors.glassWhite,
      border: Border.all(
        color: borderColor ?? GlassColors.glassBorder,
        width: borderWidth == 1 ? 1.5 : borderWidth,
      ),
      boxShadow:
          shadows ??
          [
            BoxShadow(
              color: GlassColors.glassShadow,
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
    );
  }

  static BoxDecoration glassContainerDark({
    double blurSigma = 8,
    Color? borderColor,
    double borderWidth = 1,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      color: GlassColors.glassDark.withAlpha(180),
      border: Border.all(
        color: GlassColors.redAccent.withAlpha(120),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: GlassColors.redAccent.withAlpha(20),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // ---- CARD STYLES ----
  static BoxDecoration glassCard({
    required bool isHovered,
    Color? accentColor,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: Color.fromRGBO(255, 255, 255, isHovered ? 0.48 : 0.42),
      border: Border.all(
        color: isHovered
            ? GlassColors.glassBorder
            : GlassColors.glassBorder.withAlpha(180),
        width: 1.6,
      ),
      boxShadow: [
        BoxShadow(
          color: GlassColors.glassShadow,
          blurRadius: isHovered ? 36 : 28,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  // ---- GRADIENT ACCENTS ----
  static LinearGradient accentGradient({Color? startColor, Color? endColor}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        startColor ?? GlassColors.sushiDark,
        endColor ?? GlassColors.redAccent,
      ],
    );
  }

  static LinearGradient backgroundGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        GlassColors.bgLight,
        GlassColors.sushi.withAlpha(18),
        GlassColors.redAccent.withAlpha(12),
      ],
    );
  }

  // ---- BADGE STYLES ----
  static BoxDecoration glassBadge({
    required Color color,
    bool isActive = false,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      color: isActive ? color.withAlpha(120) : color.withAlpha(60),
      border: Border.all(
        color: color.withAlpha(isActive ? 160 : 100),
        width: isActive ? 1.2 : 1,
      ),
    );
  }
}

// ============================================================================
// TYPOGRAPHY
// ============================================================================

class GlassTypography {
  static const TextStyle headline1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: GlassColors.glassText,
    letterSpacing: -0.5,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: GlassColors.glassText,
    letterSpacing: -0.3,
  );

  static const TextStyle bodyRegular = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: GlassColors.glassText,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: GlassColors.glassText,
    height: 1.4,
  );

  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: GlassColors.glassText,
    letterSpacing: 0.3,
  );

  static const TextStyle button = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.2,
  );
}

// ============================================================================
// GLASS BUTTON STYLES
// ============================================================================

class GlassButtonStyle {
  static ButtonStyle primary() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return GlassColors.redAccentLight;
        }
        return GlassColors.redAccent;
      }),
      foregroundColor: const WidgetStatePropertyAll(Colors.white),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: WidgetStateProperty.all(GlassColors.redAccent.withAlpha(40)),
    );
  }

  static ButtonStyle secondary() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        final opacity = states.contains(WidgetState.hovered) ? 0.26 : 0.2;
        return Color.fromRGBO(255, 255, 255, opacity);
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.hovered)
            ? GlassColors.redAccent
            : GlassColors.sushiDark;
      }),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: GlassColors.glassBorder, width: 1.2),
        ),
      ),
      elevation: const WidgetStatePropertyAll(0),
    );
  }
}

// ============================================================================
// THEME FLUTTER COMPLÈTE
// ============================================================================

ThemeData glassTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: GlassColors.redAccent,
    primary: GlassColors.redAccent,
    secondary: GlassColors.sushiDark,
    surface: GlassColors.glassWhite,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    primaryColor: GlassColors.redAccent,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: GlassColors.glassWhite,
      foregroundColor: GlassColors.glassText,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GlassTypography.headline2,
      iconTheme: const IconThemeData(color: GlassColors.glassText),
      shape: Border(
        bottom: BorderSide(color: GlassColors.sushi.withAlpha(60), width: 1),
      ),
    ),
    cardTheme: CardThemeData(
      color: GlassColors.glassWhite,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: GlassColors.glassBorder, width: 1.6),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: GlassColors.glassLight,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: GlassColors.glassBorder,
          width: 1.2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: GlassColors.glassBorder,
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: GlassColors.redAccent, width: 2),
      ),
      labelStyle: const TextStyle(color: GlassColors.glassText, fontSize: 12),
      hintStyle: TextStyle(
        color: GlassColors.glassText.withAlpha(140),
        fontSize: 12,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: GlassTypography.headline1,
      headlineSmall: GlassTypography.headline2,
      bodyLarge: GlassTypography.bodyRegular,
      bodyMedium: GlassTypography.bodySmall,
      labelSmall: GlassTypography.label,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: GlassButtonStyle.primary(),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: GlassButtonStyle.secondary(),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(GlassColors.redAccent),
        textStyle: const WidgetStatePropertyAll(GlassTypography.bodyRegular),
        overlayColor: WidgetStatePropertyAll(
          GlassColors.redAccent.withAlpha(30),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ),
    dividerColor: GlassColors.sushi.withAlpha(40),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
