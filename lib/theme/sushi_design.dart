import 'package:flutter/material.dart';

class SushiColors {
  // Primaires
  static const Color red = Color(0xFFE8003D);
  static const Color redDark = Color(0xFFB5002E);
  static const Color redLight = Color(0xFFFF3366);
  static const Color redPale = Color(0xFFFFE5EC);
  static const Color redSurface = Color(0xFFFFF0F3);

  // Accents
  static const Color orange = Color(0xFFFF6B35);
  static const Color yellow = Color(0xFFFFD60A);
  static const Color green = Color(0xFF00B67A);
  static const Color teal = Color(0xFF0096C7);

  // Neutres
  static const Color ink = Color(0xFF0A0A0A);
  static const Color inkSoft = Color(0xFF1C1C1E);
  static const Color inkMid = Color(0xFF48484A);
  static const Color inkLight = Color(0xFF8E8E93);
  static const Color inkFaint = Color(0xFFC7C7CC);
  static const Color divider = Color(0xFFE5E5EA);
  static const Color surface = Color(0xFFF2F2F7);
  static const Color white = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFFFAFAFA);

  // Status
  static const Color success = Color(0xFF00B67A);
  static const Color warning = Color(0xFFFFD60A);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF0096C7);
}

class SushiRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 28.0;
  static const double full = 999.0;
}

class SushiSpace {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 28.0;
  static const double xxxl = 40.0;
}

class SushiTypo {
  static const TextStyle display = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.2,
    color: SushiColors.ink,
  );
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: SushiColors.ink,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: SushiColors.ink,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: SushiColors.ink,
  );
  static const TextStyle h4 = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: SushiColors.ink,
  );
  static const TextStyle bodyLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.6,
    color: SushiColors.inkSoft,
  );
  static const TextStyle bodyMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.55,
    color: SushiColors.inkSoft,
  );
  static const TextStyle bodySm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: SushiColors.inkMid,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: SushiColors.inkMid,
  );
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: SushiColors.inkLight,
  );
  static const TextStyle btnLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: SushiColors.white,
  );
  static const TextStyle btnMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: SushiColors.white,
  );
  static const TextStyle price = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    fontFamily: 'RobotoMono',
    color: SushiColors.green,
  );
  static const TextStyle priceLg = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    fontFamily: 'RobotoMono',
    color: SushiColors.green,
  );
  static const TextStyle tag = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    color: SushiColors.ink,
  );
}

class SushiShadow {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x240A0A0A), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> button = [
    BoxShadow(color: Color(0x99E8003D), blurRadius: 16, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x330A0A0A), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x1A0A0A0A), blurRadius: 4, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> bottomBar = [
    BoxShadow(color: Color(0x2E0A0A0A), blurRadius: 20, offset: Offset(0, -4)),
  ];
  static const List<BoxShadow> ctaRed = [
    BoxShadow(color: Color(0xCCE8003D), blurRadius: 20, offset: Offset(0, 8)),
  ];
}

class SushiGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [SushiColors.red, SushiColors.redLight],
  );
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [SushiColors.red, SushiColors.orange],
  );
  static const LinearGradient warm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [SushiColors.orange, SushiColors.yellow],
  );
  static const LinearGradient imgOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x8C000000)],
  );
  static const LinearGradient splash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [SushiColors.redLight, SushiColors.red, SushiColors.redDark],
  );
}

class SushiDeco {
  static BoxDecoration card({bool selected = false}) {
    return BoxDecoration(
      color: SushiColors.white,
      borderRadius: BorderRadius.circular(SushiRadius.xl),
      border: Border.all(
        color: selected ? SushiColors.red : SushiColors.divider,
        width: selected ? 2 : 1,
      ),
      boxShadow: SushiShadow.card,
    );
  }

  static BoxDecoration tinted(Color color) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(SushiRadius.xl),
      boxShadow: SushiShadow.card,
    );
  }

  static BoxDecoration featured() {
    return BoxDecoration(
      gradient: SushiGradients.hero,
      borderRadius: BorderRadius.circular(SushiRadius.xl),
      boxShadow: SushiShadow.elevated,
    );
  }

  static BoxDecoration badge({required Color bg}) {
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(SushiRadius.full),
    );
  }

  static BoxDecoration input({bool focused = false}) {
    return BoxDecoration(
      color: SushiColors.white,
      borderRadius: BorderRadius.circular(SushiRadius.lg),
      border: Border.all(
        color: focused ? SushiColors.red : SushiColors.divider,
        width: focused ? 2 : 1,
      ),
    );
  }

  static BoxDecoration bottomNav() {
    return BoxDecoration(
      color: SushiColors.white,
      border: const Border(
        top: BorderSide(color: SushiColors.divider, width: 1),
      ),
      boxShadow: SushiShadow.bottomBar,
    );
  }

  static BoxDecoration navActive() {
    return BoxDecoration(
      color: SushiColors.redPale,
      borderRadius: BorderRadius.circular(SushiRadius.full),
    );
  }

  static BoxDecoration accentTop(Color color) {
    return BoxDecoration(
      color: SushiColors.white,
      borderRadius: BorderRadius.circular(SushiRadius.xl),
      border: const Border(
        top: BorderSide(color: SushiColors.divider, width: 1),
        left: BorderSide(color: SushiColors.divider, width: 1),
        right: BorderSide(color: SushiColors.divider, width: 1),
        bottom: BorderSide(color: SushiColors.divider, width: 1),
      ),
      boxShadow: SushiShadow.card,
    );
  }
}

class SushiButtonStyle {
  static ButtonStyle primary() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return SushiColors.redDark;
        if (states.contains(WidgetState.hovered)) return SushiColors.redLight;
        return SushiColors.red;
      }),
      foregroundColor: const WidgetStatePropertyAll(SushiColors.white),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: SushiSpace.xl,
          vertical: SushiSpace.md,
        ),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SushiRadius.lg),
        ),
      ),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(SushiColors.red),
    );
  }

  static ButtonStyle secondary() {
    return ButtonStyle(
      backgroundColor: const WidgetStatePropertyAll(SushiColors.white),
      foregroundColor: const WidgetStatePropertyAll(SushiColors.red),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: SushiSpace.lg,
          vertical: SushiSpace.sm,
        ),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SushiRadius.lg),
          side: const BorderSide(color: SushiColors.red, width: 1.4),
        ),
      ),
      elevation: const WidgetStatePropertyAll(0),
    );
  }

  static ButtonStyle ghost() {
    return ButtonStyle(
      backgroundColor: const WidgetStatePropertyAll(SushiColors.white),
      foregroundColor: const WidgetStatePropertyAll(SushiColors.ink),
      minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SushiRadius.md),
        ),
      ),
      elevation: const WidgetStatePropertyAll(0),
    );
  }
}

class SushiBadge extends StatelessWidget {
  const SushiBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SushiSpace.sm,
        vertical: SushiSpace.xs,
      ),
      decoration: SushiDeco.badge(bg: color),
      child: Text(
        label,
        style: SushiTypo.tag.copyWith(color: SushiColors.white),
      ),
    );
  }
}

class SushiCTAButton extends StatelessWidget {
  const SushiCTAButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.gradient,
    this.isLoading = false,
    this.disabled = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Gradient? gradient;
  final bool isLoading;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? SushiGradients.primary;
    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: effectiveGradient,
          borderRadius: BorderRadius.circular(SushiRadius.lg),
          boxShadow: SushiShadow.ctaRed,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(SushiRadius.lg),
            onTap: disabled || isLoading ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SushiSpace.xl,
                vertical: SushiSpace.md,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(SushiColors.white),
                      ),
                    )
                  else if (icon != null) ...[
                    Icon(icon, size: 18, color: SushiColors.white),
                    const SizedBox(width: SushiSpace.sm),
                  ],
                  Text(label, style: SushiTypo.btnLg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
