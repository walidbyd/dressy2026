import 'package:flutter/material.dart';
import '../core/vendor/constant/ps_constants.dart';
import 'ps_colors.dart';

ThemeData themeData(ThemeData baseTheme) {
  //final baseTheme = ThemeData.light();

  if (baseTheme.brightness == Brightness.dark) {
    // PsColors.loadColor2(false);

    // Dark Theme
    return baseTheme.copyWith(
      primaryColor: PsColors.primary300,
      primaryColorDark: PsColors.achromatic800,
      primaryColorLight: PsColors.achromatic800,
      scaffoldBackgroundColor: PsColors.achromatic800,
      textTheme: TextTheme(
        displayLarge: TextStyle(
            color: PsColors.text50,
            fontFamily: PsConst.ps_default_font_family),
        displayMedium: TextStyle(
            color: PsColors.text50,
            fontFamily: PsConst.ps_default_font_family),
        displaySmall: TextStyle(
            color: PsColors.text50,
            fontFamily: PsConst.ps_default_font_family),
        headlineMedium: TextStyle(
          color: PsColors.text50,
          fontFamily: PsConst.ps_default_font_family,
        ),
        headlineSmall: TextStyle(
            color: PsColors.text50,
            fontFamily: PsConst.ps_default_font_family,
            fontWeight: FontWeight.bold),
        titleLarge: TextStyle(
            color: PsColors.text50,
            fontFamily: PsConst.ps_default_font_family),
        titleMedium: TextStyle(
            color: PsColors.text50,
            fontFamily: PsConst.ps_default_font_family,
            fontWeight: FontWeight.bold),
        titleSmall: TextStyle(
            color: PsColors.text50,
            fontFamily: PsConst.ps_default_font_family,
            fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(
          color: PsColors.text50,
          fontFamily: PsConst.ps_default_font_family,
        ),
        bodyMedium: TextStyle(
            color: PsColors.text50,
            fontFamily: PsConst.ps_default_font_family,
            fontWeight: FontWeight.bold),
        labelLarge: TextStyle(
            color: PsColors.text50,
            fontFamily: PsConst.ps_default_font_family),
        bodySmall: TextStyle(
            color: PsColors.text50,
            fontFamily: PsConst.ps_default_font_family),
        labelSmall: TextStyle(
            color: PsColors.text50,
            fontFamily: PsConst.ps_default_font_family),
      ),
      iconTheme: IconThemeData(color: PsColors.primary300),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PsColors.primary500,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFD8C7CC), width: 1.0),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PsColors.primary300,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme:
          AppBarTheme(backgroundColor: PsColors.achromatic800), //coreBackgroundColor),
    );
  } else {
    // PsColors.loadColor2(true);
    // White / Warm Theme
    return baseTheme.copyWith(
        primaryColor: PsColors.primary500,
        primaryColorDark: PsColors.achromatic50,
        primaryColorLight: PsColors.achromatic50,
        scaffoldBackgroundColor: PsColors.backgroundColor,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: PsColors.primary500,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: PsColors.primary500,
            side: const BorderSide(color: Color(0xFFD8C7CC), width: 1.0),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: PsColors.primary500,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(
              color: PsColors.text800,
              fontFamily: PsConst.ps_default_font_family),
          displayMedium: TextStyle(
              color: PsColors.text800,
              fontFamily: PsConst.ps_default_font_family),
          displaySmall: TextStyle(
              color: PsColors.text800,
              fontFamily: PsConst.ps_default_font_family),
          headlineMedium: TextStyle(
            color: PsColors.text800,
            fontFamily: PsConst.ps_default_font_family,
          ),
          headlineSmall: TextStyle(
              color: PsColors.text800,
              fontFamily: PsConst.ps_default_font_family,
              fontWeight: FontWeight.bold),
          titleLarge: TextStyle(
              color: PsColors.text800,
              fontFamily: PsConst.ps_default_font_family),
          titleMedium: TextStyle(
              color: PsColors.text800,
              fontFamily: PsConst.ps_default_font_family,
              fontWeight: FontWeight.bold),
          titleSmall: TextStyle(
              color: PsColors.text800,
              fontFamily: PsConst.ps_default_font_family,
              fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(
            color: PsColors.text800,
            fontFamily: PsConst.ps_default_font_family,
          ),
          bodyMedium: TextStyle(
              color: PsColors.text800,
              fontFamily: PsConst.ps_default_font_family,
              fontWeight: FontWeight.bold),
          labelLarge: TextStyle(
              color: PsColors.text800,
              fontFamily: PsConst.ps_default_font_family),
          bodySmall: TextStyle(
              color: PsColors.text800,
              fontFamily: PsConst.ps_default_font_family),
          labelSmall: TextStyle(
              color: PsColors.text800,
              fontFamily: PsConst.ps_default_font_family),
        ),
        iconTheme: IconThemeData(color: PsColors.primary500),
        appBarTheme: AppBarTheme(
            backgroundColor: PsColors.achromatic50)); //coreBackgroundColor));
  }
}
