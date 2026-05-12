import 'package:hive/hive.dart';
import 'package:whats_for_dino_2/models/menu.dart';
import 'package:whats_for_dino_2/pages/catalogue.dart';

// Public cache
class MealItemsCache {
  static List<LocalMealItem> items = [];
  // static bool isInitialized = false;
}

// Initialize food items
Future<void> initializeMealItemsCache() async {
  final mealsBox = Hive.box('mealsBox');

  // Load persisted meals
  final stored = mealsBox.get('meals', defaultValue: []);
  MealItemsCache.items =
      (stored as List)
          .map((e) => LocalMealItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

  // Save back to Hive
  mealsBox.put(
    'meals',
    MealItemsCache.items.map((e) => e.toJson()).toList(),
  );
}

// Given a list of meals, merge them into the local cache, and update 
void mergeMealItems(List<Meal> meals) {
  final Map<String, Meal> incoming = {for (final m in meals) m.name: m};

  final Set<String> incomingNames = incoming.keys.toSet();

  // 1. Update existing + add new
  for (final meal in meals) {
    final index = MealItemsCache.items.indexWhere((m) => m.name == meal.name);

    if (index == -1) {
      MealItemsCache.items.add(
        LocalMealItem(
          name: meal.name,
          likes: meal.likes,
          dislikes: meal.dislikes,
          notify: false,
        ),
      );
      continue;
    }

    final existing = MealItemsCache.items[index];

    // update ONLY server-side fields
    existing.likes = meal.likes;
    existing.dislikes = meal.dislikes;
  }

  // 2. Remove stale meals
  MealItemsCache.items.removeWhere(
    (item) => !incomingNames.contains(item.name),
  );

  // 3. Remove stale user preferences
  removeStaleRatings(incomingNames);
}
