import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whats_for_dino_2/services/meals_cache.dart';
import 'package:whats_for_dino_2/services/noti_service.dart';
import 'package:whats_for_dino_2/services/utils.dart';

Future<void> _uploadRating(LocalMealItem item) async {
  if (item.myRating == null) return;

  final installId = await getInstallId();

  final docRef = FirebaseFirestore.instance
      .collection('installs')
      .doc(installId);

  await docRef.set({
    'ratings': {
      item.name: {
        'isFavourite': item.isFavourite,
        'rating': item.myRating,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    },
  }, SetOptions(merge: true));
}

Future<void> removeStaleRatings(List<String> validMealNames) async {
  final installId = await getInstallId();
  final firestore = FirebaseFirestore.instance;

  // Fetch current ratings
  final installRef = firestore.collection('installs').doc(installId);
  final installSnap = await installRef.get();

  if (!installSnap.exists) {
    debugPrint("No install document found, nothing to clean");
    return;
  }

  final data = installSnap.data();
  final ratings = data?['ratings'] as Map<String, dynamic>?;

  if (ratings == null || ratings.isEmpty) {
    debugPrint("No ratings found, nothing to clean");
    return;
  }

  // Find stale ratings
  final Map<String, dynamic> deletions = {};

  for (final ratingName in ratings.keys) {
    if (!validMealNames.contains(ratingName)) {
      deletions['ratings.$ratingName'] = FieldValue.delete();
      debugPrint("Removing stale rating: $ratingName");
    }
  }

  // Apply deletions
  if (deletions.isNotEmpty) {
    await installRef.update(deletions);
    debugPrint("Removed ${deletions.length} stale ratings");
  } else {
    debugPrint("No stale ratings found");
  }
}

class LocalMealItem {
  final String name;
  double communityRating; // can map to menu rating if needed
  bool isFavourite;
  int? myRating;

  LocalMealItem({
    required this.name,
    required this.communityRating,
    this.isFavourite = true,
    this.myRating,
  });

  Map<String, dynamic> toJson() => {
    "name": name,
    "communityRating": communityRating,
    "isFavourite": isFavourite,
    "myRating": myRating,
  };

  factory LocalMealItem.fromJson(Map<String, dynamic> json) => LocalMealItem(
    name: json["name"],
    communityRating: json["communityRating"].toDouble(),
    isFavourite: json["isFavourite"] ?? true,
    myRating: json["myRating"],
  );
}

/// Public accessor
List<LocalMealItem> getMealItemsCache() {
  return MealItemsCache.items;
}

// The page
class FavouritesPage extends StatefulWidget {
  final void Function(LocalMealItem)? onItemChanged;

  const FavouritesPage({super.key, this.onItemChanged});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  final TextEditingController _searchController = TextEditingController();
  late Box mealsBox;
  late Box menuBox;
  List<LocalMealItem> _filteredItems = [];

  final Map<int, String> ratingLabels = {
    1: 'I don\'t like it at all',
    2: 'I don\'t like it much',
    3: 'I\'m neutral on it',
    4: 'I like it',
    5: 'I love it',
  };

  @override
  void initState() {
    super.initState();
    mealsBox = Hive.box('mealsBox');
    menuBox = Hive.box('menuBox');

    _searchController.addListener(_onSearchChanged);
    // _filteredItems = List.from(FoodItemsCache.items);

    _loadItems();
  }

  Future<void> _loadItems() async {
  // await initializeFoodItems(); // <-- ensure cache is ready
  if (!mounted) return;

  setState(() {
    _filteredItems = List.from(MealItemsCache.items);
  });
}

  // void _resetFavouritesCache() {
  //   setState(() {
  //     FoodItemsCache.items.clear();
  //     FoodItemsCache.isInitialized = false;
  //     mealsBox.delete('favourites');
  //   });

  //   initializeFoodItems();
  // }

  void _saveToHive() {
    mealsBox.put(
      'favourites',
      MealItemsCache.items.map((e) => e.toJson()).toList(),
    );
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems =
          MealItemsCache.items
              .where((item) => item.name.toLowerCase().contains(query))
              .toList();
    });
  }

  void _updateItem(LocalMealItem item) {
    widget.onItemChanged?.call(item);
    _saveToHive();
  }

  void _showRatingPicker(LocalMealItem item) {
    final List<int> reversedRatings = [5, 4, 3, 2, 1];

    ColorScheme currentColourScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: currentColourScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(0),
        ),
      ),
      builder:
          (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 24.0,
                  ),
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // title color
                    ),
                  ),
                ),
                Divider(
                  color: currentColourScheme.primary,
                ), // optional divider below title
                // Rating buttons
                ...reversedRatings.map((r) {
                  return ListTile(
                    title: Text(
                      '$r - ${ratingLabels[r]}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      setState(() {
                        item.myRating = r;
                        _updateItem(item);
                      });
                      Navigator.pop(context);
                      _uploadRating(item);
                    },
                  );
                }),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                keyboardAppearance:
                    MediaQuery.of(
                      context,
                    ).platformBrightness, // Ignore the theme of the app, use the theme of the device
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.transparent),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredItems.length,
                itemBuilder: (_, index) {
                  final item = _filteredItems[index];
                  return ListTile(
                    title: Text(
                      item.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Community Rating: ${item.communityRating.toStringAsFixed(1)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _showRatingPicker(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.transparent),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.myRating?.toString() ?? '-',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            item.isFavourite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              item.isFavourite = !item.isFavourite;
                              _updateItem(item);
                            });
                            NotiService().refreshNotifications();
                            _uploadRating(item);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
