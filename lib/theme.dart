import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color.fromARGB(255, 13, 71, 161),
  colorScheme: ColorScheme.light(
    surface: const Color.fromARGB(255, 240, 240, 240),
    onSurface: Colors.black,
    primary: const Color.fromARGB(255, 13, 71, 161),
    secondary: Colors.blue.shade300,
    surfaceContainer: const Color.fromARGB(255, 216, 216, 216)
  ),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.blue.shade400,
  colorScheme: ColorScheme.dark(
    surface: const Color.fromARGB(255, 20, 20, 20),
    onSurface: Colors.white,
    primary: Colors.blue.shade400,
    secondary: Colors.blue.shade600,
    surfaceContainer:Color.fromARGB(255, 46, 46, 46),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color.fromARGB(255, 36, 36, 36)
    ),
  )
);