import 'package:flutter/material.dart';
import 'package:whats_for_dino_2/theme/theme.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = lightMode;

  ThemeData get themeData => _themeData;

  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    if (value) {
      themeData = darkMode;
    } else {
      themeData = lightMode;
    }
  }
}
