import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

ColorScheme colors(BuildContext context) =>
    AdaptiveTheme.of(context).theme.colorScheme;

void changeTheme(BuildContext context, id) {
  if (appThemes.containsKey(id)) {
    AdaptiveTheme.of(context).setTheme(
      light: generateTheme(colorScheme: appThemes[id]!.colorScheme),
      dark: generateTheme(colorScheme: appThemes[id]!.colorScheme),
    );
  }
}

ThemeData generateTheme({required ColorScheme colorScheme}) {
  return ThemeData.from(colorScheme: colorScheme).copyWith(
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogTheme(backgroundColor: colorScheme.background),
    checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.all(colorScheme.primary)),
    listTileTheme: ListTileThemeData(
      tileColor: colorScheme.background,
      iconColor: colorScheme.onBackground,
      textColor: colorScheme.onBackground,
    ),
    expansionTileTheme: ExpansionTileThemeData(
      collapsedBackgroundColor: colorScheme.background,
      collapsedIconColor: colorScheme.onBackground,
      collapsedTextColor: colorScheme.onBackground,
      backgroundColor: colorScheme.background,
      iconColor: colorScheme.onBackground,
      textColor: colorScheme.onBackground,
    ),
  ); /*
  return ThemeData(
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    listTileTheme: ListTileThemeData(
      tileColor: colorScheme.background,
      iconColor: colorScheme.onBackground,
      textColor: colorScheme.onBackground,
    ),
    expansionTileTheme: ExpansionTileThemeData(
      collapsedBackgroundColor: colorScheme.background,
      collapsedIconColor: colorScheme.onBackground,
      collapsedTextColor: colorScheme.onBackground,
      backgroundColor: colorScheme.background,
      iconColor: colorScheme.onBackground,
      textColor: colorScheme.onBackground,
    ),
    dialogTheme: DialogTheme(backgroundColor: colorScheme.background),
    checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.all(colorScheme.primary)),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      //labelStyle: TextStyle(color: colorScheme.onSurface),
      //floatingLabelStyle: TextStyle(color: colorScheme.onSurface),
      //hintStyle: TextStyle(color: colorScheme.onSurface),
      //helperStyle: TextStyle(color: colorScheme.onSurface),
      errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colorScheme.error)),
      /*border: UnderlineInputBorder(
            borderSide: BorderSide(color: colorScheme.onSurface)),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colorScheme.onSurface)),
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colorScheme.onSurface)),
        disabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: colorScheme.onSurface.withAlpha(50)))*/
    ),
  );*/
}

class CustomTheme {
  ColorScheme colorScheme;
  String name;
  CustomTheme({required this.name, required this.colorScheme});
}

Map<int, CustomTheme> appThemes = {
  1: CustomTheme(
      name: 'Standard',
      colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          background: Color.fromARGB(255, 33, 33, 63),
          onBackground: Colors.white,
          primary: Color.fromARGB(255, 169, 200, 212),
          onPrimary: Colors.black,
          secondary: Colors.red,
          onSecondary: Colors.white,
          tertiary: Colors.blueAccent,
          onTertiary: Colors.black,
          surface: Color.fromARGB(255, 0, 61, 85),
          onSurface: Colors.white,
          error: Colors.redAccent,
          onError: Colors.white)),
  2: CustomTheme(
      name: 'Grau',
      colorScheme: const ColorScheme(
          brightness: Brightness.light,
          background: Color.fromARGB(255, 116, 116, 116),
          onBackground: Color.fromARGB(255, 255, 255, 255),
          primary: Color.fromARGB(255, 56, 56, 56),
          onPrimary: Colors.white,
          secondary: Color.fromARGB(255, 65, 11, 8),
          onSecondary: Colors.white,
          tertiary: Colors.blueAccent,
          onTertiary: Colors.black,
          surface: Color.fromARGB(255, 255, 255, 255),
          onSurface: Colors.white,
          error: Color.fromARGB(255, 143, 7, 7),
          onError: Colors.white)),
  3: CustomTheme(
      name: '2017',
      colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          background: Color.fromARGB(255, 0, 82, 18),
          onBackground: Color.fromARGB(255, 255, 255, 255),
          primary: Color.fromARGB(255, 95, 95, 95),
          onPrimary: Color.fromARGB(255, 255, 255, 255),
          secondary: Color.fromARGB(255, 255, 255, 255),
          onSecondary: Color.fromARGB(255, 0, 0, 0),
          tertiary: Colors.blueAccent,
          onTertiary: Colors.black,
          surface: Color.fromARGB(255, 115, 187, 67),
          onSurface: Color.fromARGB(255, 255, 255, 255),
          error: Color.fromARGB(255, 143, 7, 7),
          onError: Colors.white)),
  4: CustomTheme(
      name: '2022',
      colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          background: Color.fromARGB(255, 88, 114, 153),
          onBackground: Color.fromARGB(255, 255, 255, 255),
          primary: Color.fromARGB(255, 255, 255, 255),
          onPrimary: Color.fromARGB(255, 0, 0, 0),
          secondary: Color.fromARGB(255, 239, 244, 230),
          onSecondary: Color.fromARGB(255, 0, 0, 0),
          tertiary: Colors.blueAccent,
          onTertiary: Colors.black,
          surface: Color.fromARGB(255, 1, 78, 136),
          onSurface: Color.fromARGB(255, 255, 255, 255),
          error: Color.fromARGB(255, 199, 3, 3),
          onError: Colors.white)),
  5: CustomTheme(
      name: 'Black & White',
      colorScheme: const ColorScheme(
          brightness: Brightness.light,
          background: Color.fromARGB(255, 255, 255, 255),
          onBackground: Color.fromARGB(255, 0, 0, 0),
          primary: Color.fromARGB(255, 77, 77, 77),
          onPrimary: Color.fromARGB(255, 255, 255, 255),
          secondary: Color.fromARGB(255, 44, 44, 44),
          onSecondary: Color.fromARGB(255, 255, 255, 255),
          tertiary: Color.fromARGB(255, 255, 255, 255),
          onTertiary: Colors.black,
          surface: Color.fromARGB(255, 77, 77, 77),
          onSurface: Color.fromARGB(255, 255, 255, 255),
          error: Color.fromARGB(255, 182, 9, 9),
          onError: Colors.white)),
  6: CustomTheme(
      name: 'Pink Lady',
      colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          background: Color.fromARGB(255, 66, 7, 49),
          onBackground: Color.fromARGB(255, 255, 255, 255),
          primary: Color.fromARGB(255, 214, 13, 197),
          onPrimary: Color.fromARGB(255, 255, 255, 255),
          secondary: Color.fromARGB(255, 247, 210, 0),
          onSecondary: Color.fromARGB(255, 0, 0, 0),
          tertiary: Color.fromARGB(255, 255, 255, 255),
          onTertiary: Colors.black,
          surface: Color.fromARGB(255, 214, 13, 197),
          onSurface: Color.fromARGB(255, 255, 255, 255),
          error: Color.fromARGB(255, 182, 9, 9),
          onError: Colors.white)),
};
