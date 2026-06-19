import 'package:hive/hive.dart';
import 'package:whats_for_dino_2/models/menu.dart';
import 'package:whats_for_dino_2/pages/catalogue.dart';

// Public cache
class MealItemsCache {
  static Map<String, String> aliases = {};
  static List<LocalMealItem> items = [];
  // static bool isInitialized = false;

  // Resolve canonical name transitively
  static String canonicalName(String name) {
    while (aliases.containsKey(name)) {
      name = aliases[name]!;
    }
    return name;
  }
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
  mealsBox.put('meals', MealItemsCache.items.map((e) => e.toJson()).toList());
}

// Given a list of meals, merge them into the local cache, and update
void mergeMealItems(List<Meal> meals) {
  final Map<String, Meal> incoming = {for (final m in meals) m.name: m};

  final Set<String> incomingNames = incoming.keys.toSet();

  // 1. Update existing + add new
  for (final meal in meals) {
    final canonicalName = MealItemsCache.canonicalName(meal.name);

    final index = MealItemsCache.items.indexWhere(
      (m) => MealItemsCache.canonicalName(m.name) == canonicalName,
    );

    if (index == -1) {
      MealItemsCache.items.add(
        LocalMealItem(
          name: canonicalName,
          likes: meal.likes,
          dislikes: meal.dislikes,
          notify: false,
        ),
      );
      continue;
    }

    final existing = MealItemsCache.items[index];

    // Migrate old alias names to canonical name
    existing.name = canonicalName;

    existing.likes = meal.likes;
    existing.dislikes = meal.dislikes;
  }

  // 2. Remove stale meals / deduplicate (keep first occurrence)

  final canonicalIncomingNames = <String>{};

  final filteredIncoming = <String>{};

  for (final m in meals) {
    final canonical = MealItemsCache.canonicalName(m.name);

    if (!filteredIncoming.contains(canonical)) {
      filteredIncoming.add(canonical);
    }

    canonicalIncomingNames.add(canonical);
  }

  // remove duplicates from local cache (keep first occurrence)
  final seen = <String>{};

  MealItemsCache.items.removeWhere((item) {
    final canonical = MealItemsCache.canonicalName(item.name);

    if (seen.contains(canonical)) {
      return true;
    }

    seen.add(canonical);

    return !canonicalIncomingNames.contains(canonical);
  });
}
