import 'package:dpsg_app/screens/profile_screen.dart';
import 'package:flutter/material.dart';

final kColorSchemes = [
  ColorSchemeMenuEntry(kColorSchemeStandard, 'Standard'),
  ColorSchemeMenuEntry(kColorSchemeStandardWeiss, 'Biber'),
  ColorSchemeMenuEntry(kColorSchemeStandardOrange, 'Wölfling'),
  ColorSchemeMenuEntry(kColorSchemeStandardBlau, 'Jufi'),
  ColorSchemeMenuEntry(kColorSchemeStandardGruen, 'Pfadi'),
  ColorSchemeMenuEntry(kColorSchemeStandardRot, 'Rover'),
  ColorSchemeMenuEntry(kColorSchemeStandardGrau, 'Leiter'),
  ColorSchemeMenuEntry(kColorSchemeStandardViolett, 'Worldscout'),
];

final kColorSchemeStandard = ColorScheme(
  brightness: Brightness.dark,
  primaryContainer: Color.fromARGB(255, 33, 33, 63),
  onPrimaryContainer: Colors.grey[100]!,
  primary: Color.fromARGB(255, 169, 200, 212),
  onPrimary: Colors.grey[900]!,
  secondary: Colors.red,
  onSecondary: Colors.grey[100]!,
  surface: Color.fromARGB(255, 0, 61, 85),
  onSurface: Colors.grey[100]!,
  error: Colors.redAccent,
  onError: Colors.grey[100]!,
);

final kColorSchemeStandardWeiss = ColorScheme(
  brightness: Brightness.light,
  primaryContainer: Color.fromARGB(255, 167, 167, 167),
  onPrimaryContainer: Colors.grey[900]!,
  primary: Color.fromARGB(255, 217, 232, 255),
  onPrimary: Colors.grey[900]!,
  secondary: Color.fromARGB(255, 103, 126, 161),
  onSecondary: Colors.grey[100]!,
  surface: Color.fromARGB(255, 245, 245, 245),
  onSurface: Colors.grey[900]!,
  error: Colors.redAccent,
  onError: Colors.grey[100]!,
);

final kColorSchemeStandardOrange = ColorScheme(
  brightness: Brightness.dark,
  primaryContainer: Color.fromARGB(255, 75, 50, 37),
  onPrimaryContainer: Colors.grey[100]!,
  primary: Color.fromARGB(255, 169, 196, 212),
  onPrimary: Colors.grey[900]!,
  secondary: Color.fromARGB(255, 0, 61, 85),
  onSecondary: Colors.grey[100]!,
  surface: Color.fromARGB(255, 163, 76, 4),
  onSurface: Colors.grey[100]!,
  error: Colors.redAccent,
  onError: Colors.grey[100]!,
);

final kColorSchemeStandardBlau = ColorScheme(
  brightness: Brightness.dark,
  primaryContainer: Color.fromARGB(255, 26, 52, 100),
  onPrimaryContainer: Colors.grey[100]!,
  primary: Color.fromARGB(255, 169, 200, 212),
  onPrimary: Colors.grey[900]!,
  secondary: Color.fromARGB(255, 201, 152, 18),
  onSecondary: Colors.grey[900]!,
  surface: Color.fromARGB(255, 85, 110, 180),
  onSurface: Colors.grey[100]!,
  error: Colors.redAccent,
  onError: Colors.grey[100]!,
);

final kColorSchemeStandardGruen = ColorScheme(
  brightness: Brightness.dark,
  primaryContainer: Color.fromARGB(255, 92, 126, 112),
  onPrimaryContainer: Colors.grey[100]!,
  primary: Color.fromARGB(255, 211, 194, 157),
  onPrimary: Colors.grey[900]!,
  secondary: Color.fromARGB(255, 72, 190, 67),
  onSecondary: Colors.grey[900]!,
  surface: Color.fromARGB(255, 37, 66, 38),
  onSurface: Colors.grey[100]!,
  error: Colors.redAccent,
  onError: Colors.grey[100]!,
);

final kColorSchemeStandardRot = ColorScheme(
  brightness: Brightness.dark,
  primaryContainer: Color.fromARGB(255, 0, 0, 0),
  onPrimaryContainer: Colors.grey[100]!,
  primary: Color.fromARGB(255, 212, 169, 169),
  onPrimary: Colors.grey[900]!,
  secondary: Color.fromARGB(255, 24, 134, 74),
  onSecondary: Colors.grey[100]!,
  surface: Color.fromARGB(255, 83, 6, 6),
  onSurface: Colors.grey[100]!,
  error: Colors.redAccent,
  onError: Colors.grey[100]!,
);

const kColorSchemeStandardGrau = ColorScheme(
  brightness: Brightness.dark,
  primaryContainer: Color.fromARGB(255, 33, 33, 33),
  onPrimaryContainer: Colors.white,
  primary: Color.fromARGB(255, 100, 100, 100),
  onPrimary: Colors.white,
  secondary: Color.fromARGB(255, 75, 89, 116),
  onSecondary: Colors.white,
  surface: Color.fromARGB(255, 50, 50, 50),
  onSurface: Colors.white,
  error: Colors.redAccent,
  onError: Colors.white,
);

final kColorSchemeStandardViolett = ColorScheme(
  brightness: Brightness.dark,
  primaryContainer: Color.fromARGB(255, 105, 69, 105),
  onPrimaryContainer: Colors.grey[100]!,
  primary: Color.fromARGB(255, 212, 169, 212),
  onPrimary: Colors.grey[900]!,
  secondary: Color.fromARGB(255, 21, 161, 204),
  onSecondary: Colors.grey[100]!,
  surface: Color.fromARGB(255, 53, 7, 53),
  onSurface: Colors.grey[100]!,
  error: Colors.redAccent,
  onError: Colors.grey[100]!,
);
