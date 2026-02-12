import 'package:hive/hive.dart';
import 'package:whats_for_dino_2/models/menu.dart';
import 'package:whats_for_dino_2/pages/favourites.dart';

// Public cache
class MealItemsCache {
  static List<LocalMealItem> items = [];
  // static bool isInitialized = false;
}

// Initialize food items
Future<void> initializeLocalMealItems() async {
  final favouritesBox = Hive.box('favouritesBox');

  // Load persisted favourites
  final stored = favouritesBox.get('favourites', defaultValue: []);
  MealItemsCache.items =
      (stored as List)
          .map((e) => LocalMealItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

  // Save back to Hive
  favouritesBox.put(
    'favourites',
    MealItemsCache.items.map((e) => e.toJson()).toList(),
  );
}

// Given a list of meals, merge them into the local cache, and update 
void mergeMealItems(List<Meal> meals) {
  for (var meal in meals) {
    final index = MealItemsCache.items.indexWhere((m) => m.name == meal.name);

    if (index == -1) {
      MealItemsCache.items.add(
        LocalMealItem(
          name: meal.name,
          communityRating: meal.rating,
          isFavourite: false,
        ),
      );
      continue;
    }

    if (index != -1) {
      if (meal.rating == -1) {
        MealItemsCache.items.removeAt(index);
      } else if (MealItemsCache.items[index].communityRating != meal.rating) {
        MealItemsCache.items[index].communityRating = meal.rating;
      }
    }
  }

  // Remove any meals from the local cache that are not present in the current list of meals
  final List<String> currentMealNames = meals.map((meal) => meal.name).toList();
  MealItemsCache.items.removeWhere(
    (item) =>
        !currentMealNames.contains(item.name) || item.communityRating == -1,
  );

  // Remove any ratings this user has made for meals that no longer exist
  removeStaleRatings(currentMealNames);
}
