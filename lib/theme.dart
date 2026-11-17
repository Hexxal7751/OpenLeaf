import 'package:flutter/material.dart';

// Palette pulled from the OpenLeaf logo: deep space indigo with
// cyan, magenta and amber accents.
const kSpace = Color(0xFF0B0A24);
const kPanel = Color(0xFF17143F);
const kPanelHigh = Color(0xFF221E58);
const kCyan = Color(0xFF3DD5F3);
const kMagenta = Color(0xFFE84FD0);
const kAmber = Color(0xFFFFB347);

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: kCyan,
    onPrimary: Color(0xFF00212A),
    secondary: kMagenta,
    onSecondary: Colors.white,
    tertiary: kAmber,
    surface: kPanel,
    onSurface: Color(0xFFEDEBFF),
    error: Color(0xFFFF6B6B),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kSpace,
    appBarTheme: const AppBarTheme(
      backgroundColor: kSpace,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: Color(0xFFEDEBFF),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kPanelHigh,
    ),
  );
}
