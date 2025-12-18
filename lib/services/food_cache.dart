import 'package:hive/hive.dart';
import 'package:whats_for_dino_2/models/menu.dart';
import 'package:whats_for_dino_2/pages/favourites.dart';
import 'package:whats_for_dino_2/services/dayMenus_cache.dart';

// Public cache
class FoodItemsCache {
  static List<FoodItem> items = [];
  static bool isInitialized = false;
}

// Initialize food items
Future<void> initializeFoodItems() async {
  if (FoodItemsCache.isInitialized) return;

  final favouritesBox = Hive.box('favouritesBox');

  // Load persisted favourites
  final stored = favouritesBox.get('favourites', defaultValue: []);
  FoodItemsCache.items = (stored as List)
      .map((e) => FoodItem.fromJson(Map<String, dynamic>.from(e)))
      .toList();

  // Merge menu items into favourites
  final dayMenus = getDayMenuCache();
  mergeMenuItems(dayMenus);

  FoodItemsCache.isInitialized = true;
  // Save back to Hive
  favouritesBox.put(
    'favourites',
    FoodItemsCache.items.map((e) => e.toJson()).toList(),
  );
}

// Moved merge logic here
void mergeMenuItems(List<DayMenu> dayMenus) {
  final Set<String> currentMenuNames = {};

  for (var day in dayMenus) {
    for (var meal in [
      ...day.breakfast,
      if (day.brunch != null) ...day.brunch!,
      ...day.lunch,
      ...day.dinner,
    ]) {
      currentMenuNames.add(meal.name);

      final index = FoodItemsCache.items.indexWhere((m) => m.name == meal.name);

      if (index == -1 && meal.rating != -1) {
        FoodItemsCache.items.add(
          FoodItem(name: meal.name, communityRating: meal.rating, isFavourite: false),
        );
        continue;
      }

      if (index != -1) {
        if (meal.rating == -1) {
          FoodItemsCache.items.removeAt(index);
        } else if (FoodItemsCache.items[index].communityRating != meal.rating) {
          FoodItemsCache.items[index].communityRating = meal.rating;
        }
      }
    }
  }

  FoodItemsCache.items.removeWhere(
    (item) => !currentMenuNames.contains(item.name) || item.communityRating == -1,
  );
}