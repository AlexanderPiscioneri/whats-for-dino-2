// Static storage for persistent data across widget rebuilds
import 'package:flutter/widgets.dart';
import 'package:whats_for_dino_2/models/menu.dart';

// Public cache
class MenuCache {
  static List<Menu> menus = [];
  static List<DayMenu> dayMenus = [];
  static PageController pageController = PageController(initialPage: 0, viewportFraction: 1);
  static bool isInitialized = false;
}

/// Public accessor
List<DayMenu> getDayMenuCache() {
  return MenuCache.dayMenus;
}

