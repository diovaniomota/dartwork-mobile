import 'package:flutter/material.dart';

/// Palette for Work ERP Mobile.
class AppColors {
  // Brand
  static const brandBlue = Color(0xFF0D5EA1);
  static const brandGreen = Color(0xFF159A86);
  static const brandAmber = Color(0xFFE49524);

  // Primary aliases
  static const primary = brandBlue;
  static const primaryDark = brandGreen;

  // Semantic colors
  static const success = Color(0xFF1D986F);
  static const warning = Color(0xFFE4A11B);
  static const danger = Color(0xFFD95B4F);
  static const info = Color(0xFF1A81A8);

  // Light theme
  static const lightBg = Color(0xFFEEF4FF);
  static const lightBgSoft = Color(0xFFF9FCFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightSidebar = Color(0xFFF6FBFF);
  static const lightHover = Color(0xFFEAF3FF);
  static const lightTextPrimary = Color(0xFF122746);
  static const lightTextSecondary = Color(0xFF4D6388);
  static const lightTextMuted = Color(0xFF788AAE);
  static const lightBorder = Color(0xFFD7E3F7);
  static const lightBorderStrong = Color(0xFFC1D3EE);
  static const lightSurfaceElevated = Color(0xFFF7FAFF);

  // Dark theme — preto neutro, alinhado com o desktop (globals.css [data-theme='dark'])
  static const darkBg = Color(0xFF111111); // --bg-body
  static const darkBgSoft = Color(0xFF161616); // --bg-sidebar
  static const darkCard = Color(0xFF1B1B1B); // --bg-card
  static const darkSidebar = Color(0xFF161616);
  static const darkHover = Color(0xFF242424); // --bg-hover
  static const darkInput = Color(0xFF191919); // --bg-input
  static const darkTextPrimary = Color(0xFFF5F5F5); // --text-primary
  static const darkTextSecondary = Color(0xFFC9C9C9); // --text-secondary
  static const darkTextMuted = Color(0xFF8F8F8F); // --text-muted
  static const darkBorder = Color(0xFF2D2D2D); // --border-color
  static const darkBorderStrong = Color(0xFF353535); // --button-secondary-border
  static const darkSurfaceElevated = Color(0xFF202020); // --bg-secondary

  // Accent verde do dark mode (igual ao desktop --accent-primary)
  static const darkAccent = Color(0xFF64C98B);
  static const darkAccentSecondary = Color(0xFF3D8F63);

  // Login gradients
  static const loginGradientStart = Color(0xFF061325);
  static const loginGradientMid = Color(0xFF0B2041);
  static const loginGradientEnd = Color(0xFF0F2E5C);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandBlue, brandGreen],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandBlue, brandAmber],
  );

  static const surfaceGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lightBgSoft, lightBg],
  );

  static const surfaceGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBgSoft, darkBg],
  );

  static const loginBgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [loginGradientStart, loginGradientMid, loginGradientEnd],
  );
}
