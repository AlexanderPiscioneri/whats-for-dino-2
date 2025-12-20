import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whats_for_dino_2/services/food_cache.dart';
import 'package:whats_for_dino_2/services/noti_service.dart';
import 'package:whats_for_dino_2/services/utils.dart';

Future<void> _uploadRating(FoodItem item) async {
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

class FoodItem {
  final String name;
  double communityRating; // can map to menu rating if needed
  bool isFavourite;
  int? myRating;

  FoodItem({
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

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
    name: json["name"],
    communityRating: json["communityRating"].toDouble(),
    isFavourite: json["isFavourite"] ?? true,
    myRating: json["myRating"],
  );
}

/// Public accessor
List<FoodItem> getFoodItemsCache() {
  return FoodItemsCache.items;
}

// The page
class FavouritesPage extends StatefulWidget {
  final void Function(FoodItem)? onItemChanged;

  const FavouritesPage({super.key, this.onItemChanged});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  final TextEditingController _searchController = TextEditingController();
  late Box favouritesBox;
  late Box menuBox;
  List<FoodItem> _filteredItems = [];

  final Map<int, String> ratingLabels = {
    1: 'Terrible',
    2: 'Bad',
    3: 'Neutral',
    4: 'Good',
    5: 'Great',
  };

  @override
  void initState() {
    super.initState();
    favouritesBox = Hive.box('favouritesBox');
    menuBox = Hive.box('menuBox');

    _searchController.addListener(_onSearchChanged);
    _filteredItems = List.from(FoodItemsCache.items);
  }

  // void _resetFavouritesCache() {
  //   setState(() {
  //     FoodItemsCache.items.clear();
  //     FoodItemsCache.isInitialized = false;
  //     favouritesBox.delete('favourites');
  //   });

  //   initializeFoodItems();
  // }

  void _saveToHive() {
    favouritesBox.put(
      'favourites',
      FoodItemsCache.items.map((e) => e.toJson()).toList(),
    );
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems =
          FoodItemsCache.items
              .where((item) => item.name.toLowerCase().contains(query))
              .toList();
    });
  }

  void _updateItem(FoodItem item) {
    widget.onItemChanged?.call(item);
    _saveToHive();
  }

  void _showRatingPicker(FoodItem item) {
    final List<int> reversedRatings = [5, 4, 3, 2, 1];

    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder:
            (_) => Container(
              height: 250,
              color: Colors.transparent,
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem:
                      item.myRating != null
                          ? reversedRatings.indexOf(item.myRating!)
                          : 0,
                ),
                itemExtent: 32,
                onSelectedItemChanged: (index) {
                  setState(() {
                    item.myRating = reversedRatings[index];
                    _updateItem(item);
                  });

                  _uploadRating(item);
                },
                children:
                    reversedRatings
                        .map(
                          (r) => Center(
                            child: Text(
                              '$r - ${ratingLabels[r]}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder:
            (_) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    reversedRatings
                        .map(
                          (r) => ListTile(
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
                          ),
                        )
                        .toList(),
              ),
            ),
      );
    }
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
                keyboardAppearance: MediaQuery.of(context).platformBrightness, // Ignore the theme of the app, use the theme of the device
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
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
                              style: const TextStyle(color: Colors.white, fontSize: 15),
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
