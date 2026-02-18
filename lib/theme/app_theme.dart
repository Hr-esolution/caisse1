import 'package:flutter/material.dart';

import '../data/glass_theme.dart';

/// Palette "glass" unifiée pour toutes les vues.
/// On conserve les noms historiques pour limiter les changements ailleurs
/// tout en basculant les teintes vers Sushi + Red Accent.
class AppColors {
  static const deepTeal = GlassColors.redAccent; // accent principal
  static const burntOrange = GlassColors.sushiDark; // accent chaud
  static const livingCoral = GlassColors.sushi; // ton doux
  static const offWhite = GlassColors.bgLight; // fond clair
  static const charcoalDark = GlassColors.glassText; // texte
  static const neutralLight = Color.fromARGB(153, 245, 245, 245); // gris clair

  // Backward-compatible aliases used across the app
  static const cloudDancer = offWhite;
  static const taupeDore = neutralLight;
  static const grisModerne = GlassColors.glassText;
  static const charbon = charcoalDark;
  static const blancPur = GlassColors.glassWhite;
  static const terraCotta = burntOrange;
  static const bleuGris = deepTeal;
  static const grisLeger = neutralLight;
  static const grisPale = GlassColors.glassLight;
}

class AppSpacing {
  static const xs = 2.0;
  static const sm = 4.0;
  static const md = 8.0;
  static const lg = 16.0;
  static const xl = 28.0;
}

class AppTypography {
  static const headline1 = GlassTypography.headline1;
  static const headline2 = GlassTypography.headline2;
  static const bodyLarge = GlassTypography.bodyRegular;
  static const bodySmall = GlassTypography.bodySmall;
  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: GlassColors.glassText,
  );

  static const button = GlassTypography.button;

  static const mono = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    fontFamily: 'RobotoMono',
    fontFamilyFallback: ['Menlo', 'Courier', 'monospace'],
    color: Color(0xFF0B6B3A), // vert foncé pour prix/compteurs
  );
}
