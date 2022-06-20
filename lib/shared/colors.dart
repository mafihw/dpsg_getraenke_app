import 'package:flutter/material.dart';

const kBackgroundColor = Color.fromARGB(255, 33, 33, 63);
const kPrimaryColor = Color.fromARGB(255, 169, 200, 212);
const kSecondaryColor = Colors.red;
const kMainColor = Color.fromARGB(255, 0, 61, 85);

const kColorScheme = ColorScheme(
  background: kBackgroundColor,
  onBackground: Colors.white,
  brightness: Brightness.dark,
  primary: kPrimaryColor,
  onPrimary: Colors.black,
  secondary: Colors.red,
  onSecondary: Colors.white,
  surface: kMainColor,
  onSurface: Colors.white,
  error: Colors.redAccent,
  onError: Colors.white,
);
