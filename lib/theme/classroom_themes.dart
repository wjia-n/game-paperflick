import 'package:flutter/material.dart';

/// Paper Flick visual system: classroom-desk warmth, physical materials,
/// pseudo-3D depth. No neon, no cyberpunk, no AI-dashboard looks.
///
/// Each [DeskThemeDef] bundles: wall color, desk surface colors, bin color,
/// paper tint, accent, and text colors — a complete classroom mood.
class DeskThemeDef {
  final String id;
  final String name;
  final bool pro; // Pro-only themes
  final Color wallTop;
  final Color wallBottom;
  final Color deskLight;
  final Color deskDark;
  final Color deskLine;
  final Color binColor;
  final Color binDark;
  final Color binRim;
  final Color paperTint;
  final Color paperShadow;
  final Color accent;
  final Color accentDark;
  final Color text;
  final Color muted;
  final Color card;
  final Color chipBg;

  const DeskThemeDef({
    required this.id,
    required this.name,
    this.pro = false,
    required this.wallTop,
    required this.wallBottom,
    required this.deskLight,
    required this.deskDark,
    required this.deskLine,
    required this.binColor,
    required this.binDark,
    required this.binRim,
    required this.paperTint,
    required this.paperShadow,
    required this.accent,
    required this.accentDark,
    required this.text,
    required this.muted,
    required this.card,
    required this.chipBg,
  });

  static ThemeData appTheme(DeskThemeDef t) {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: t.wallBottom,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: t.accent,
        onPrimary: Colors.white,
        secondary: t.accentDark,
        onSecondary: Colors.white,
        error: const Color(0xFFB3261E),
        onError: Colors.white,
        surface: t.card,
        onSurface: t.text,
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: t.text),
        bodyLarge: TextStyle(color: t.text),
      ),
    );
  }
}

/// 14 classroom themes. The first 5 are free; the rest are Pro.
class DeskThemes {
  static const List<DeskThemeDef> all = [
    DeskThemeDef(
      id: 'classroom',
      name: 'Classic Classroom',
      wallTop: Color(0xFFF6ECD9),
      wallBottom: Color(0xFFE9D9BC),
      deskLight: Color(0xFFC99A63),
      deskDark: Color(0xFF9A6B3C),
      deskLine: Color(0xFF8A5F34),
      binColor: Color(0xFF8A8F96),
      binDark: Color(0xFF5F646B),
      binRim: Color(0xFF4A4E54),
      paperTint: Color(0xFFFDFBF4),
      paperShadow: Color(0xFFE3DCC8),
      accent: Color(0xFFC0562F),
      accentDark: Color(0xFF8F3A1E),
      text: Color(0xFF3B2416),
      muted: Color(0xFF8A6F52),
      card: Color(0xFFFFF8EA),
      chipBg: Color(0xFFEAD9B8),
    ),
    DeskThemeDef(
      id: 'chalkboard',
      name: 'Chalkboard Night',
      wallTop: Color(0xFF2E4038),
      wallBottom: Color(0xFF1E2C26),
      deskLight: Color(0xFF8A6B45),
      deskDark: Color(0xFF5E4628),
      deskLine: Color(0xFF4E3A20),
      binColor: Color(0xFF3F6B5A),
      binDark: Color(0xFF2A4A3E),
      binRim: Color(0xFF1E372E),
      paperTint: Color(0xFFF3EFE2),
      paperShadow: Color(0xFFD8D2BE),
      accent: Color(0xFFF2C14E),
      accentDark: Color(0xFFC08A1E),
      text: Color(0xFFF5EFDD),
      muted: Color(0xFFA8B5A4),
      card: Color(0xFF2E4038),
      chipBg: Color(0xFF24352E),
    ),
    DeskThemeDef(
      id: 'sunny',
      name: 'Sunny Library',
      wallTop: Color(0xFFFFF3D6),
      wallBottom: Color(0xFFFBE3A8),
      deskLight: Color(0xFFE0B878),
      deskDark: Color(0xFFB8894E),
      deskLine: Color(0xFFA87840),
      binColor: Color(0xFFB0894A),
      binDark: Color(0xFF7E622F),
      binRim: Color(0xFF5E4A22),
      paperTint: Color(0xFFFFFDF6),
      paperShadow: Color(0xFFEDE4C8),
      accent: Color(0xFFD9822B),
      accentDark: Color(0xFFA85E16),
      text: Color(0xFF4A3218),
      muted: Color(0xFF9A7B4E),
      card: Color(0xFFFFF6DF),
      chipBg: Color(0xFFF6E3B4),
    ),
    DeskThemeDef(
      id: 'study',
      name: 'Cozy Study',
      wallTop: Color(0xFFEFE2CE),
      wallBottom: Color(0xFFDECBAA),
      deskLight: Color(0xFF7A5233),
      deskDark: Color(0xFF54371F),
      deskLine: Color(0xFF462C18),
      binColor: Color(0xFF9C4A2F),
      binDark: Color(0xFF6E3120),
      binRim: Color(0xFF522416),
      paperTint: Color(0xFFF9F4E6),
      paperShadow: Color(0xFFE2D6B8),
      accent: Color(0xFFB5432A),
      accentDark: Color(0xFF7E2D1C),
      text: Color(0xFFF4EAD6),
      muted: Color(0xFFC4A985),
      card: Color(0xFF6B4729),
      chipBg: Color(0xFF5A3A22),
    ),
    DeskThemeDef(
      id: 'papermill',
      name: 'Paper Mill',
      wallTop: Color(0xFFFAFAF7),
      wallBottom: Color(0xFFE8E8E2),
      deskLight: Color(0xFFD9C9A8),
      deskDark: Color(0xFFB3A07E),
      deskLine: Color(0xFFA08C6C),
      binColor: Color(0xFF7A8894),
      binDark: Color(0xFF56616C),
      binRim: Color(0xFF424C56),
      paperTint: Color(0xFFFFFFFF),
      paperShadow: Color(0xFFDAD8CE),
      accent: Color(0xFF3F7FB5),
      accentDark: Color(0xFF2A5A82),
      text: Color(0xFF2E2E2E),
      muted: Color(0xFF8A8A86),
      card: Color(0xFFFFFFFF),
      chipBg: Color(0xFFDCDCD6),
    ),
    DeskThemeDef(
      id: 'rainy',
      name: 'Rainy Window',
      pro: true,
      wallTop: Color(0xFFDCE4EA),
      wallBottom: Color(0xFFB9C6D2),
      deskLight: Color(0xFF9A7B56),
      deskDark: Color(0xFF6E5739),
      deskLine: Color(0xFF5C4830),
      binColor: Color(0xFF5E7E96),
      binDark: Color(0xFF3F5A6E),
      binRim: Color(0xFF2F4454),
      paperTint: Color(0xFFF7F9FA),
      paperShadow: Color(0xFFD4DDE2),
      accent: Color(0xFF2F7FB5),
      accentDark: Color(0xFF1E5A84),
      text: Color(0xFF243038),
      muted: Color(0xFF6B7E8C),
      card: Color(0xFFF2F5F7),
      chipBg: Color(0xFFCBD6DF),
    ),
    DeskThemeDef(
      id: 'autumn',
      name: 'Autumn Desk',
      pro: true,
      wallTop: Color(0xFFF8E8CE),
      wallBottom: Color(0xFFEBCB98),
      deskLight: Color(0xFFB8763F),
      deskDark: Color(0xFF8A5427),
      deskLine: Color(0xFF76461E),
      binColor: Color(0xFF8A5A33),
      binDark: Color(0xFF5E3C20),
      binRim: Color(0xFF482D17),
      paperTint: Color(0xFFFCF6E8),
      paperShadow: Color(0xFFE8D4B0),
      accent: Color(0xFFC2512A),
      accentDark: Color(0xFF8A3517),
      text: Color(0xFF442A12),
      muted: Color(0xFF9A7448),
      card: Color(0xFFFFF1DA),
      chipBg: Color(0xFFF0D5A8),
    ),
    DeskThemeDef(
      id: 'mint',
      name: 'Mint Office',
      pro: true,
      wallTop: Color(0xFFE4F2EA),
      wallBottom: Color(0xFFC2DEC9),
      deskLight: Color(0xFFD8B98A),
      deskDark: Color(0xFFA98A5E),
      deskLine: Color(0xFF967850),
      binColor: Color(0xFF4E9A7B),
      binDark: Color(0xFF356C55),
      binRim: Color(0xFF26523F),
      paperTint: Color(0xFFFDFEF9),
      paperShadow: Color(0xFFD8E4D4),
      accent: Color(0xFF2E8B66),
      accentDark: Color(0xFF1C5E45),
      text: Color(0xFF24402F),
      muted: Color(0xFF6E9480),
      card: Color(0xFFF4FBF5),
      chipBg: Color(0xFFCFE6D4),
    ),
    DeskThemeDef(
      id: 'vintage',
      name: 'Vintage Ink',
      pro: true,
      wallTop: Color(0xFF2B2620),
      wallBottom: Color(0xFF1A1712),
      deskLight: Color(0xFF6E4E2E),
      deskDark: Color(0xFF4A3319),
      deskLine: Color(0xFF3A2913),
      binColor: Color(0xFFB08D4A),
      binDark: Color(0xFF7E642F),
      binRim: Color(0xFF5E4B22),
      paperTint: Color(0xFFF1E6C8),
      paperShadow: Color(0xFFD4C49C),
      accent: Color(0xFFD9A441),
      accentDark: Color(0xFF9A7226),
      text: Color(0xFFF1E6C8),
      muted: Color(0xFFA89468),
      card: Color(0xFF2E2921),
      chipBg: Color(0xFF3A332A),
    ),
    DeskThemeDef(
      id: 'sky',
      name: 'Morning Sky',
      pro: true,
      wallTop: Color(0xFFE2EEF8),
      wallBottom: Color(0xFFBCD4E8),
      deskLight: Color(0xFFC9A96F),
      deskDark: Color(0xFF9A7A48),
      deskLine: Color(0xFF87693C),
      binColor: Color(0xFF5A86A8),
      binDark: Color(0xFF3D5E76),
      binRim: Color(0xFF2D465A),
      paperTint: Color(0xFFFDFEFE),
      paperShadow: Color(0xFFD4E0E8),
      accent: Color(0xFF2F7FB5),
      accentDark: Color(0xFF1F5A82),
      text: Color(0xFF22303C),
      muted: Color(0xFF6B8296),
      card: Color(0xFFF2F8FC),
      chipBg: Color(0xFFC8DCEC),
    ),
    DeskThemeDef(
      id: 'terracotta',
      name: 'Terracotta',
      pro: true,
      wallTop: Color(0xFFF7E4D2),
      wallBottom: Color(0xFFECC49C),
      deskLight: Color(0xFFC08A5A),
      deskDark: Color(0xFF8F6138),
      deskLine: Color(0xFF7C532E),
      binColor: Color(0xFFB85C33),
      binDark: Color(0xFF7E3C20),
      binRim: Color(0xFF5E2C17),
      paperTint: Color(0xFFFBF4E6),
      paperShadow: Color(0xFFE8D2B4),
      accent: Color(0xFFA8431E),
      accentDark: Color(0xFF722C12),
      text: Color(0xFF4A2A16),
      muted: Color(0xFF9A6E48),
      card: Color(0xFFFFEDD8),
      chipBg: Color(0xFFF2D0A8),
    ),
    DeskThemeDef(
      id: 'pine',
      name: 'Pine Forest',
      pro: true,
      wallTop: Color(0xFFE8F0E4),
      wallBottom: Color(0xFFC4D8BA),
      deskLight: Color(0xFFB08A5C),
      deskDark: Color(0xFF7E5E3A),
      deskLine: Color(0xFF6C5030),
      binColor: Color(0xFF3F6B45),
      binDark: Color(0xFF2A4A2F),
      binRim: Color(0xFF1E3722),
      paperTint: Color(0xFFF9FBF4),
      paperShadow: Color(0xFFD8E0CC),
      accent: Color(0xFF4E8A54),
      accentDark: Color(0xFF2F5E34),
      text: Color(0xFF243820),
      muted: Color(0xFF6B8A62),
      card: Color(0xFFF4F8EC),
      chipBg: Color(0xFFCFDFC0),
    ),
    DeskThemeDef(
      id: 'rosewood',
      name: 'Rosewood',
      pro: true,
      wallTop: Color(0xFFF5E2E0),
      wallBottom: Color(0xFFEBC2BC),
      deskLight: Color(0xFF7A3E33),
      deskDark: Color(0xFF542620),
      deskLine: Color(0xFF461F18),
      binColor: Color(0xFF8A4A5A),
      binDark: Color(0xFF5E3040),
      binRim: Color(0xFF48242F),
      paperTint: Color(0xFFFDF6F2),
      paperShadow: Color(0xFFE8D4CC),
      accent: Color(0xFFB5435E),
      accentDark: Color(0xFF7E2D42),
      text: Color(0xFF4A2230),
      muted: Color(0xFF9A6E78),
      card: Color(0xFFFFECEA),
      chipBg: Color(0xFFF2D0CC),
    ),
    DeskThemeDef(
      id: 'midnightdesk',
      name: 'Midnight Desk',
      pro: true,
      wallTop: Color(0xFF343A4A),
      wallBottom: Color(0xFF1F2330),
      deskLight: Color(0xFF6B5236),
      deskDark: Color(0xFF483722),
      deskLine: Color(0xFF3A2C1B),
      binColor: Color(0xFF8A94A8),
      binDark: Color(0xFF5A6276),
      binRim: Color(0xFF444A5E),
      paperTint: Color(0xFFF4F2EC),
      paperShadow: Color(0xFFD4D2C8),
      accent: Color(0xFFF2B64E),
      accentDark: Color(0xFFB87E22),
      text: Color(0xFFF0ECE0),
      muted: Color(0xFF9AA0B0),
      card: Color(0xFF2E3442),
      chipBg: Color(0xFF262B38),
    ),
  ];

  static DeskThemeDef byId(String id, {DeskThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }

  static bool isProTheme(String id) => all.any((t) => t.id == id && t.pro);
}

/// Paper ball styles — 10 physical paper looks. First 4 free.
class PaperStyles {
  static const names = [
    'Classic White',
    'Lined Notebook',
    'Graph Grid',
    'Yellow Legal',
    'Kraft Paper',
    'Blue Tint',
    'Old Parchment',
    'Polka Dot',
    'Map Print',
    'Chalk Dust',
  ];
  static const emojis = ['⬜', '📓', '📐', '📒', '📦', '🩵', '📜', '⚪', '🗺️', '✏️'];

  static const _proFrom = 4;
  static bool isPro(int i) => i >= _proFrom;

  /// Tint applied over the theme's paper color.
  static Color tint(int i) {
    const tints = [
      0xFFFFFFFF, 0xFFFCFCF8, 0xFFF4FAFF, 0xFFFFF3C4,
      0xFFE8C98A, 0xFFDCEBF7, 0xFFEFE0B0, 0xFFFBEAEE,
      0xFFF2E8D0, 0xFFECECEC,
    ];
    return Color(tints[i.clamp(0, tints.length - 1)]);
  }
}

/// Bin styles — 10 office waste bins. First 4 free.
class BinStyles {
  static const names = [
    'Wire Mesh',
    'Blue Plastic',
    'Metal Office',
    'Red Plastic',
    'Wooden Box',
    'Woven Basket',
    'Cardboard Box',
    'Painted Tin',
    'Copper Pail',
    'Green Canvas',
  ];
  static const emojis = ['🗑️', '🪣', '🥫', '🧺', '📦', '🧺', '📦', '🥫', '🪙', '🌿'];

  static const _proFrom = 4;
  static bool isPro(int i) => i >= _proFrom;

  /// Extra body tint multiplied over the theme's bin color (null = theme color).
  static Color? bodyTint(int i) {
    const tints = [
      null, 0xFF3B7DD8, 0xFF9AA3AD, 0xFFD83B3B,
      0xFF8A5A33, 0xFFB98A4E, 0xFFB0894A, 0xFF4E9A7B,
      0xFFB87333, 0xFF5E8A5A,
    ];
    final v = tints[i.clamp(0, tints.length - 1)];
    return v == null ? null : Color(v);
  }
}

/// Desk surface styles — 10 looks. First 4 free.
class DeskStyles {
  static const names = [
    'Warm Oak',
    'Light Pine',
    'Green Felt',
    'Gray Office',
    'Dark Walnut',
    'Checkered',
    'Blue Plastic',
    'Birch Ply',
    'Corkboard',
    'Leather Top',
  ];
  static const emojis = ['🪵', '🌲', '🟩', '⬜', '🌰', '🏁', '🟦', '🪵', '🧱', '👜'];

  static const _proFrom = 4;
  static bool isPro(int i) => i >= _proFrom;

  /// Surface tint pair (light, dark) over the theme's desk colors.
  static (Color, Color)? surfaceTint(int i) {
    const pairs = [
      null, (0xFFD9B07A, 0xFFB0894A), (0xFF4E8A5E, 0xFF35603F),
      (0xFFB8BCC2, 0xFF8A8E96), (0xFF6B4A2E, 0xFF4A3018),
      null, (0xFF4E6FA8, 0xFF33497A), (0xFFE8D5AE, 0xFFC8AC7C),
      (0xFFC8A878, 0xFF9A7A50), (0xFF6B3E33, 0xFF4A2A22),
    ];
    final v = pairs[i.clamp(0, pairs.length - 1)];
    if (v == null) return null;
    return (Color(v.$1), Color(v.$2));
  }
}

/// Shared text/paint helpers in the classroom art direction.
class Desk {
  static TextStyle display(double size, {required DeskThemeDef theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: theme.text,
        letterSpacing: 0.5,
      );

  static TextStyle label(double size, {required DeskThemeDef theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: theme.accent,
        letterSpacing: 1.2,
      );

  static TextStyle body(double size,
          {required DeskThemeDef theme, Color? color}) =>
      TextStyle(fontSize: size, color: color ?? theme.text);

  /// Pseudo-3D card: warm paper surface, deep shadow, subtle top light.
  static BoxDecoration cardDeco(DeskThemeDef t, {double radius = 16}) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.card, Color.lerp(t.card, t.muted, 0.12)!],
        ),
        border: Border.all(color: t.accent.withValues(alpha: 0.45), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            offset: const Offset(0, 6),
            blurRadius: 14,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.35),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      );

  /// Chunky classroom button: wood-desk base, cream top, pressed depth.
  static BoxDecoration buttonDeco(DeskThemeDef t,
          {double radius = 14, bool pressed = false}) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: pressed
              ? [t.accentDark, t.accent]
              : [Color.lerp(t.accent, Colors.white, 0.25)!, t.accent],
        ),
        border: Border.all(color: t.accentDark, width: 2),
        boxShadow: pressed
            ? [const BoxShadow()]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  offset: const Offset(0, 5),
                  blurRadius: 8,
                ),
              ],
      );

  /// Warm wall backdrop with a desk band at the bottom — the classroom feel.
  static Widget backdrop(DeskThemeDef t, {required Widget child}) =>
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.wallTop, t.wallBottom],
            stops: const [0.0, 0.62],
          ),
        ),
        child: child,
      );
}
