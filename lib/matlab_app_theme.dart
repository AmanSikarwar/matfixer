import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'matlab_chat_theme.dart';

/// A utility class that provides MATLAB-themed ThemeData for Flutter applications.
class MatlabAppTheme {
  /// Creates a light MATLAB-themed ThemeData for the application.
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: MatlabColors.primaryBlue,
        onPrimary: MatlabColors.white,
        secondary: MatlabColors.secondaryBlue,
        onSecondary: MatlabColors.white,
        error: Colors.red,
        onError: MatlabColors.white,
        surface: MatlabColors.white,
        onSurface: MatlabColors.textColor,
        tertiary: MatlabColors.accentOrange,
        onTertiary: MatlabColors.white,
        surfaceTint: MatlabColors.lightBlueBackground,
      ),
      scaffoldBackgroundColor: MatlabColors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: MatlabColors.primaryBlue,
        foregroundColor: MatlabColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.roboto(
          color: MatlabColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardTheme(
        color: MatlabColors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: MatlabColors.borderGray, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MatlabColors.primaryBlue,
          foregroundColor: MatlabColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MatlabColors.primaryBlue,
          side: BorderSide(color: MatlabColors.primaryBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MatlabColors.primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: MatlabColors.accentOrange,
        foregroundColor: MatlabColors.white,
        shape: const CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MatlabColors.lightBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: MatlabColors.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: MatlabColors.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: MatlabColors.primaryBlue, width: 2),
        ),
        hintStyle: TextStyle(color: MatlabColors.borderGray),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.roboto(
          color: MatlabColors.textColor,
          fontSize: 32,
          fontWeight: FontWeight.w500,
        ),
        displayMedium: GoogleFonts.roboto(
          color: MatlabColors.textColor,
          fontSize: 28,
          fontWeight: FontWeight.w500,
        ),
        displaySmall: GoogleFonts.roboto(
          color: MatlabColors.textColor,
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
        headlineLarge: GoogleFonts.roboto(
          color: MatlabColors.secondaryBlue,
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
        headlineMedium: GoogleFonts.roboto(
          color: MatlabColors.secondaryBlue,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        headlineSmall: GoogleFonts.roboto(
          color: MatlabColors.secondaryBlue,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: GoogleFonts.roboto(
          color: MatlabColors.textColor,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: GoogleFonts.roboto(
          color: MatlabColors.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: GoogleFonts.roboto(
          color: MatlabColors.textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.roboto(
          color: MatlabColors.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.roboto(
          color: MatlabColors.textColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.roboto(
          color: MatlabColors.textColor,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: GoogleFonts.roboto(
          color: MatlabColors.textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: GoogleFonts.roboto(
          color: MatlabColors.textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: GoogleFonts.roboto(
          color: MatlabColors.textColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: MatlabColors.borderGray,
        thickness: 1,
        space: 16,
      ),
      iconTheme: IconThemeData(color: MatlabColors.primaryBlue, size: 24),
      chipTheme: ChipThemeData(
        backgroundColor: MatlabColors.lightBackground,
        disabledColor: MatlabColors.lightBackground.withOpacity(0.5),
        selectedColor: MatlabColors.primaryBlue,
        secondarySelectedColor: MatlabColors.secondaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: GoogleFonts.roboto(
          color: MatlabColors.textColor,
          fontSize: 14,
        ),
        secondaryLabelStyle: GoogleFonts.roboto(
          color: MatlabColors.white,
          fontSize: 14,
        ),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: MatlabColors.borderGray),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: MatlabColors.secondaryBlue,
        contentTextStyle: GoogleFonts.roboto(
          color: MatlabColors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Creates a dark MATLAB-themed ThemeData for the application.
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: MatlabDarkColors.primaryBlue,
        onPrimary: MatlabDarkColors.textColor,
        secondary: MatlabDarkColors.secondaryBlue,
        onSecondary: MatlabDarkColors.nearBlack,
        error: Colors.redAccent,
        onError: MatlabDarkColors.textColor,
        surface: MatlabDarkColors.darkBackground,
        onSurface: MatlabDarkColors.textColor,
        tertiary: MatlabDarkColors.accentOrange,
        onTertiary: MatlabDarkColors.nearBlack,
        surfaceTint: MatlabDarkColors.darkBlueBackground,
      ),
      scaffoldBackgroundColor: MatlabDarkColors.nearBlack,
      appBarTheme: AppBarTheme(
        backgroundColor: MatlabDarkColors.darkBackground,
        foregroundColor: MatlabDarkColors.textColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.roboto(
          color: MatlabDarkColors.textColor,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardTheme(
        color: MatlabDarkColors.darkBackground,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: MatlabDarkColors.borderGray, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MatlabDarkColors.primaryBlue,
          foregroundColor: MatlabDarkColors.textColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MatlabDarkColors.primaryBlue,
          side: BorderSide(color: MatlabDarkColors.primaryBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MatlabDarkColors.primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: MatlabDarkColors.accentOrange,
        foregroundColor: MatlabDarkColors.nearBlack,
        shape: const CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MatlabDarkColors.darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: MatlabDarkColors.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: MatlabDarkColors.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: MatlabDarkColors.primaryBlue, width: 2),
        ),
        hintStyle: TextStyle(color: MatlabDarkColors.borderGray),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.roboto(
          color: MatlabDarkColors.textColor,
          fontSize: 32,
          fontWeight: FontWeight.w500,
        ),
        displayMedium: GoogleFonts.roboto(
          color: MatlabDarkColors.textColor,
          fontSize: 28,
          fontWeight: FontWeight.w500,
        ),
        displaySmall: GoogleFonts.roboto(
          color: MatlabDarkColors.textColor,
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
        headlineLarge: GoogleFonts.roboto(
          color: MatlabDarkColors.secondaryBlue,
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
        headlineMedium: GoogleFonts.roboto(
          color: MatlabDarkColors.secondaryBlue,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        headlineSmall: GoogleFonts.roboto(
          color: MatlabDarkColors.secondaryBlue,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: GoogleFonts.roboto(
          color: MatlabDarkColors.textColor,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: GoogleFonts.roboto(
          color: MatlabDarkColors.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: GoogleFonts.roboto(
          color: MatlabDarkColors.textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.roboto(
          color: MatlabDarkColors.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.roboto(
          color: MatlabDarkColors.textColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.roboto(
          color: MatlabDarkColors.textColor,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: GoogleFonts.roboto(
          color: MatlabDarkColors.textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: GoogleFonts.roboto(
          color: MatlabDarkColors.textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: GoogleFonts.roboto(
          color: MatlabDarkColors.textColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: MatlabDarkColors.borderGray,
        thickness: 1,
        space: 16,
      ),
      iconTheme: IconThemeData(color: MatlabDarkColors.primaryBlue, size: 24),
      chipTheme: ChipThemeData(
        backgroundColor: MatlabDarkColors.darkBlueBackground,
        disabledColor: MatlabDarkColors.darkBlueBackground.withOpacity(0.5),
        selectedColor: MatlabDarkColors.primaryBlue,
        secondarySelectedColor: MatlabDarkColors.secondaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: GoogleFonts.roboto(
          color: MatlabDarkColors.textColor,
          fontSize: 14,
        ),
        secondaryLabelStyle: GoogleFonts.roboto(
          color: MatlabDarkColors.nearBlack,
          fontSize: 14,
        ),
        brightness: Brightness.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: MatlabDarkColors.borderGray),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: MatlabDarkColors.darkBlueBackground,
        contentTextStyle: GoogleFonts.roboto(
          color: MatlabDarkColors.textColor,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
