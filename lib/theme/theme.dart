import 'package:flutter/material.dart';

const Color defaultPrimary = Color.fromARGB(255, 35, 117, 35);
const Color defaultSurface = Color.fromARGB(255, 29, 88, 29);

ThemeData lightMode = ThemeData(
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.black26,

  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface: defaultSurface, // Background
    primary: defaultPrimary, // Top and bottom bars
    secondary: Colors.white, // Page background
  ),

  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: defaultSurface, // bar color
    indicatorColor: Colors.transparent, // removes grey circle
    height: 60,
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return IconThemeData(color: Colors.white, size: 36);
      }
      return IconThemeData(color: Colors.grey, size: 32);
    }),
  ),

);

ThemeData darkMode = ThemeData(
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.black26,
  
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    surface: Colors.grey.shade800,
    primary: Colors.grey.shade900,
    secondary: Colors.grey.shade900,
  ),

  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.grey.shade900, // bar color
    indicatorColor: Colors.transparent, // removes grey circle
    height: 60,
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return IconThemeData(color: Colors.white, size: 36);
      }
      return IconThemeData(color: Colors.grey, size: 32);
    }),
  ),

);
