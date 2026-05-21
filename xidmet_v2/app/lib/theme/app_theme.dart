import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Brand colours ─────────────────────────────────────────────────────────────
const kPrimary       = Color(0xFF7C3AED);
const kPrimaryLight  = Color(0xFFEDE9FE);
const kPrimaryDark   = Color(0xFFA78BFA); // lighter purple for dark backgrounds
const kSecondary     = Color(0xFF10B981);
const kSuccess       = Color(0xFF22C55E);
const kDanger        = Color(0xFFEF4444);
const kWarning       = Color(0xFFF59E0B);
const kOnPrimary     = Color(0xFFFFFFFF);

// ── Light palette ─────────────────────────────────────────────────────────────
const kSurface         = Color(0xFFFFFFFF);
const kBackground      = Color(0xFFF5F3FF);
const kTextPrimary     = Color(0xFF1A1A2E);
const kTextSecondary   = Color(0xFF6B7280);
const kOutline         = Color(0xFFE5E7EB);

// ── Dark palette ──────────────────────────────────────────────────────────────
const kDarkBg            = Color(0xFF0D0D1A);
const kDarkSurface       = Color(0xFF161625);
const kDarkSurfaceHigh   = Color(0xFF1E1E35);
const kDarkOutline        = Color(0xFF2D2D50);
const kDarkTextPrimary   = Color(0xFFF0EEF8);
const kDarkTextSecondary = Color(0xFF9CA3AF);

// ── Aliases ───────────────────────────────────────────────────────────────────
const kError  = kDanger;
const kBorder = kOutline;

// ── Radii ─────────────────────────────────────────────────────────────────────
const kRadiusSm = 8.0;
const kRadiusMd = 12.0;
const kRadiusLg = 16.0;
const kRadiusXl = 24.0;
const kRadius   = kRadiusLg;

// ── Theme builder ─────────────────────────────────────────────────────────────
ThemeData buildTheme({bool dark = false}) {
  final bg     = dark ? kDarkBg          : kBackground;
  final surf   = dark ? kDarkSurface     : kSurface;
  final surfHi = dark ? kDarkSurfaceHigh : const Color(0xFFF0EEFF);
  final onSurf = dark ? kDarkTextPrimary : kTextPrimary;
  final onSurf2= dark ? kDarkTextSecondary : kTextSecondary;
  final outline= dark ? kDarkOutline     : kOutline;
  final primary= dark ? kPrimaryDark     : kPrimary;

  final cs = ColorScheme.fromSeed(
    seedColor: kPrimary,
    brightness: dark ? Brightness.dark : Brightness.light,
  ).copyWith(
    primary: primary,
    onPrimary: kOnPrimary,
    secondary: kSecondary,
    surface: surf,
    onSurface: onSurf,
    surfaceContainerLowest: bg,
    surfaceContainerLow: dark ? const Color(0xFF121220) : const Color(0xFFF8F6FF),
    surfaceContainer: surfHi,
    surfaceContainerHigh: dark ? const Color(0xFF242440) : const Color(0xFFE9E5FF),
    outline: outline,
    outlineVariant: dark ? const Color(0xFF1E1E30) : const Color(0xFFF3F0FF),
    error: kDanger,
  );

  final base = dark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);

  return base.copyWith(
    colorScheme: cs,
    scaffoldBackgroundColor: bg,

    // ── AppBar ───────────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: surf,
      foregroundColor: onSurf,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: dark ? Colors.black54 : Colors.black12,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: onSurf,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: onSurf),
      systemOverlayStyle: dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: surf,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: surf,
            ),
    ),

    // ── Bottom Navigation ────────────────────────────────────────────────────
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surf,
      selectedItemColor: primary,
      unselectedItemColor: onSurf2,
      elevation: 0,
    ),

    // ── Input ────────────────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfHi,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusMd),
        borderSide: BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusMd),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusMd),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusMd),
        borderSide: const BorderSide(color: kDanger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusMd),
        borderSide: const BorderSide(color: kDanger, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(color: onSurf2),
      hintStyle: TextStyle(color: onSurf2.withOpacity(0.6)),
    ),

    // ── Buttons ──────────────────────────────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: kOnPrimary,
        disabledBackgroundColor: primary.withOpacity(0.38),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: kOnPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: primary),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    // ── Card ─────────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: surf,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusLg),
        side: BorderSide(color: outline),
      ),
    ),

    // ── Chip ─────────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: dark ? kDarkSurfaceHigh : kPrimaryLight,
      labelStyle: TextStyle(color: primary, fontWeight: FontWeight.w600),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSm)),
    ),

    // ── Switch ───────────────────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? primary : (dark ? kDarkTextSecondary : Colors.grey.shade400)),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? primary.withOpacity(0.3)
              : (dark ? kDarkSurfaceHigh : Colors.grey.shade200)),
    ),

    // ── Divider ──────────────────────────────────────────────────────────────
    dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),

    // ── Dialog ───────────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: surf,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusXl)),
      titleTextStyle: TextStyle(
        color: onSurf,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      contentTextStyle: TextStyle(color: onSurf2, fontSize: 14, height: 1.5),
    ),

    // ── SnackBar ─────────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFF2D2D50) : const Color(0xFF1A1A2E),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
    ),

    // ── ListTile ─────────────────────────────────────────────────────────────
    listTileTheme: ListTileThemeData(
      iconColor: onSurf2,
      titleTextStyle: TextStyle(color: onSurf, fontSize: 14, fontWeight: FontWeight.w600),
      subtitleTextStyle: TextStyle(color: onSurf2, fontSize: 12),
    ),

    // ── Tab Bar ──────────────────────────────────────────────────────────────
    tabBarTheme: TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white60,
      indicatorColor: Colors.white,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),

    // ── Progress Indicator ────────────────────────────────────────────────────
    progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
  );
}
