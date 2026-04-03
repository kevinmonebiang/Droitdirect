import 'package:flutter/material.dart';

ThemeData buildCamrlexTheme() {
  const navy = Color(0xFF11284A);
  const navySoft = Color(0xFF1D3A67);
  const gold = Color(0xFFC8A96B);
  const mist = Color(0xFFF3F5F8);
  const panel = Color(0xFFFFFFFF);
  const ink = Color(0xFF162334);
  const body = Color(0xFF586579);
  const line = Color(0xFFE0E6ED);
  const success = Color(0xFF1F7A4D);
  const error = Color(0xFFB3261E);

  final scheme = ColorScheme.fromSeed(
    seedColor: navy,
    primary: navy,
    secondary: gold,
    error: error,
    surface: panel,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: scheme,
    scaffoldBackgroundColor: mist,
    dividerColor: line,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: ink,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: panel,
      hintStyle: const TextStyle(color: Color(0xFF8A94A6)),
      labelStyle: const TextStyle(
        color: body,
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: navy, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: navy,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(40),
      ),
      selectedColor: const Color(0xFFE4EDF8),
      backgroundColor: panel,
      side: const BorderSide(color: line),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFFF9FBFD),
      indicatorColor: const Color(0xFFE4EDF8),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? navy : body,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? navy : body,
          size: 24,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: navySoft,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        color: ink,
        height: 1.05,
      ),
      headlineMedium: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w900,
        color: ink,
        height: 1.08,
      ),
      titleLarge: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        height: 1.55,
        color: body,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        color: body,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      CamrlexColors(
        navy: navy,
        navySoft: navySoft,
        gold: gold,
        mist: mist,
        panel: panel,
        ink: ink,
        body: body,
        line: line,
        success: success,
      ),
    ],
  );
}

class CamrlexColors extends ThemeExtension<CamrlexColors> {
  const CamrlexColors({
    required this.navy,
    required this.navySoft,
    required this.gold,
    required this.mist,
    required this.panel,
    required this.ink,
    required this.body,
    required this.line,
    required this.success,
  });

  final Color navy;
  final Color navySoft;
  final Color gold;
  final Color mist;
  final Color panel;
  final Color ink;
  final Color body;
  final Color line;
  final Color success;

  @override
  CamrlexColors copyWith({
    Color? navy,
    Color? navySoft,
    Color? gold,
    Color? mist,
    Color? panel,
    Color? ink,
    Color? body,
    Color? line,
    Color? success,
  }) {
    return CamrlexColors(
      navy: navy ?? this.navy,
      navySoft: navySoft ?? this.navySoft,
      gold: gold ?? this.gold,
      mist: mist ?? this.mist,
      panel: panel ?? this.panel,
      ink: ink ?? this.ink,
      body: body ?? this.body,
      line: line ?? this.line,
      success: success ?? this.success,
    );
  }

  @override
  CamrlexColors lerp(ThemeExtension<CamrlexColors>? other, double t) {
    if (other is! CamrlexColors) {
      return this;
    }
    return CamrlexColors(
      navy: Color.lerp(navy, other.navy, t) ?? navy,
      navySoft: Color.lerp(navySoft, other.navySoft, t) ?? navySoft,
      gold: Color.lerp(gold, other.gold, t) ?? gold,
      mist: Color.lerp(mist, other.mist, t) ?? mist,
      panel: Color.lerp(panel, other.panel, t) ?? panel,
      ink: Color.lerp(ink, other.ink, t) ?? ink,
      body: Color.lerp(body, other.body, t) ?? body,
      line: Color.lerp(line, other.line, t) ?? line,
      success: Color.lerp(success, other.success, t) ?? success,
    );
  }
}

extension CamrlexThemeX on BuildContext {
  CamrlexColors get camrlex => Theme.of(this).extension<CamrlexColors>()!;
}
