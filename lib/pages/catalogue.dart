import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:whats_for_dino_2/models/menu.dart';
import 'package:whats_for_dino_2/services/meals_cache.dart';
import 'package:whats_for_dino_2/services/menu_cache.dart';
import 'package:whats_for_dino_2/services/noti_service.dart';
import 'package:whats_for_dino_2/services/utils.dart';
import 'package:whats_for_dino_2/widgets/ratings_widget.dart';

Future<void> _uploadRating(LocalMealItem item) async {
  final installId = await getInstallId();

  final docRef = FirebaseFirestore.instance
      .collection('installs')
      .doc(installId);

  await docRef.set({
    'ratings': {
      item.name: {
        'notify': item.notify,
        'vote': item.myVote,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    },
  }, SetOptions(merge: true));
}

Future<void> removeStaleRatings(Set<String> validMealNames) async {
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

enum MealVote { none, like, dislike }

class LocalMealItem {
  String name;

  int likes;
  int dislikes;

  bool notify;

  MealVote myVote;

  int numOccurrences;

  LocalMealItem({
    required this.name,
    required this.likes,
    required this.dislikes,
    this.notify = false,
    this.myVote = MealVote.none,
    this.numOccurrences = 0, // NEW default
  });

  Map<String, dynamic> toJson() => {
    "name": name,
    "likes": likes,
    "dislikes": dislikes,
    "notify": notify,
    "myVote": myVote.name,
    "numOccurrences": numOccurrences, // NEW
  };

  factory LocalMealItem.fromJson(Map<String, dynamic> json) => LocalMealItem(
    name: json["name"] ?? "",
    likes: json["likes"] ?? 0,
    dislikes: json["dislikes"] ?? 0,
    notify: json["notify"] ?? false,
    myVote: _voteFromString(json["myVote"]),
    numOccurrences: json["numOccurrences"] ?? 0, // NEW
  );

  static MealVote _voteFromString(dynamic value) {
    switch (value) {
      case "like":
        return MealVote.like;
      case "dislike":
        return MealVote.dislike;
      default:
        return MealVote.none;
    }
  }
}

/// Public accessor
List<LocalMealItem> getMealItemsCache() {
  return MealItemsCache.items;
}

// The page
class CataloguePage extends StatefulWidget {
  final void Function(LocalMealItem)? onItemChanged;

  const CataloguePage({super.key, this.onItemChanged});

  @override
  State<CataloguePage> createState() => _CataloguePageState();
}

enum SortKey { notifications, name, ratio }

class _CataloguePageState extends State<CataloguePage> {
  final TextEditingController _searchController = TextEditingController();
  late Box mealsBox = Hive.box('mealsBox');
  late Box menuBox = Hive.box('menuBox');
  final settingsBox = Hive.box('settingsBox');
  List<LocalMealItem> _filteredItems = [];

  SortKey _sortKey = SortKey.name;
  bool _sortAsc = true;

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

    _searchController.addListener(_onSearchChanged);
    // _filteredItems = List.from(FoodItemsCache.items);

    _loadItems();
  }

  Future<void> _loadItems() async {
    if (!mounted) return;

    setState(() {
      _filteredItems = List.from(MealItemsCache.items);
      _applySort();
      // _sortByTodaysMenu();
    });
  }

  // void _resetFavouritesCache() {
  //   setState(() {
  //     FoodItemsCache.items.clear();
  //     FoodItemsCache.isInitialized = false;
  //     mealsBox.delete('meals');
  //   });

  //   initializeFoodItems();
  // }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems =
          MealItemsCache.items
              .where((item) => item.name.toLowerCase().contains(query))
              .toList();

      _applySort();
    });
  }

  double _score(LocalMealItem m) {
    // return (m.likes + 1) / (m.dislikes + 1);
    return (m.likes - m.dislikes).toDouble();
  }

  void _applySort() {
    _filteredItems.sort((a, b) {
      int result;

      if (settingsBox.get("hapticFeedback", defaultValue: true))
        HapticFeedback.mediumImpact();

      switch (_sortKey) {
        case SortKey.notifications:
          result =
              a.notify == b.notify
                  ? a.name.compareTo(b.name)
                  : (a.notify ? 1 : 0).compareTo(b.notify ? 1 : 0);
          break;

        case SortKey.name:
          result = a.name.compareTo(b.name);
          break;

        case SortKey.ratio:
          final sa = _score(a);
          final sb = _score(b);

          result = sa.compareTo(sb);

          // tie-breakers for stability
          if (result == 0) {
            result = a.likes.compareTo(b.likes);
          }
          if (result == 0) {
            result = -a.dislikes.compareTo(b.dislikes);
          }
          if (result == 0) {
            result = a.name.compareTo(b.name);
          }
          break;
      }

      return _sortAsc ? result : -result;
    });
  }

  void _sortByTodaysMenu() {
    if (MenuCache.dayMenus.isEmpty) return;

    final today = DateTime.now();
    DayMenu? todayMenu;

    for (final day in MenuCache.dayMenus) {
      if (day.dayDate.isEmpty) continue;

      final parsed = DateFormat('dd/MM/yyyy').parse(day.dayDate);
      if (parsed.year == today.year &&
          parsed.month == today.month &&
          parsed.day == today.day) {
        todayMenu = day;
        break;
      }
    }

    if (todayMenu == null) return;

    final List<String> priorityOrder = [
      ...todayMenu.lunch,
      ...todayMenu.dinner,
    ];

    final Map<String, int> priorityIndex = {
      for (int i = 0; i < priorityOrder.length; i++) priorityOrder[i]: i,
    };

    _filteredItems.sort((a, b) {
      final aPriority = priorityIndex[a.name];
      final bPriority = priorityIndex[b.name];

      if (aPriority != null && bPriority != null) {
        return aPriority.compareTo(bPriority);
      }

      if (aPriority != null) return -1;
      if (bPriority != null) return 1;

      return 0;
    });
  }

  void _updateItem(LocalMealItem item) {
    widget.onItemChanged?.call(item);
    _saveMealItemsCacheToHive();
  }

  void _showRatingPicker(LocalMealItem item) {
    final List<int> reversedRatings = [5, 4, 3, 2, 1];

    ColorScheme currentColourScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: currentColourScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
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
                      // setState(() {
                      //   item.myVote = r;
                      //   _updateItem(item);
                      // });
                      // Navigator.pop(context);
                      // _uploadRating(item);
                    },
                  );
                }),
              ],
            ),
          ),
    );
  }

  void rateMeal(String mealName, MealVote newVote) {
    final index = MealItemsCache.items.indexWhere((m) => m.name == mealName);

    if (index == -1) return;

    final meal = MealItemsCache.items[index];

    int likes = meal.likes;
    int dislikes = meal.dislikes;

    // remove previous vote
    switch (meal.myVote) {
      case MealVote.like:
        likes--;
        break;

      case MealVote.dislike:
        dislikes--;
        break;

      case MealVote.none:
        break;
    }

    // apply new vote
    switch (newVote) {
      case MealVote.like:
        likes++;
        break;

      case MealVote.dislike:
        dislikes++;
        break;

      case MealVote.none:
        break;
    }

    meal.likes = likes;
    meal.dislikes = dislikes;
    meal.myVote = newVote;

    _uploadRating(meal);
    _saveMealItemsCacheToHive();
    setState(() {
      final query = _searchController.text.toLowerCase();
      _filteredItems =
          MealItemsCache.items
              .where((item) => item.name.toLowerCase().contains(query))
              .toList();
      _applySort();
      // _sortByTodaysMenu();
    });
  }

  Future<void> _uploadRating(LocalMealItem item) async {
    final installId = await getInstallId();

    final docRef = FirebaseFirestore.instance
        .collection('installs')
        .doc(installId);

    await docRef.set({
      'ratings': {
        item.name: {
          'notify': item.notify,
          'vote': item.myVote.name,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      },
    }, SetOptions(merge: true));
  }

  void setMealNotif(String mealName, bool value) {
    final index = MealItemsCache.items.indexWhere((m) => m.name == mealName);

    if (index == -1) return;

    final meal = MealItemsCache.items[index];
    meal.notify = value;

    _saveMealItemsCacheToHive();
    setState(() {
      final query = _searchController.text.toLowerCase();
      _filteredItems =
          MealItemsCache.items
              .where((item) => item.name.toLowerCase().contains(query))
              .toList();
      _applySort();
    });
  }

  void _saveMealItemsCacheToHive() {
    mealsBox.put('meals', MealItemsCache.items.map((e) => e.toJson()).toList());
  }

  @override
  Widget build(BuildContext context) {
    final notificationsBox = Hive.box('notificationsBox');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 8,
                left: 8,
                right: 8,
                bottom: 0,
              ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              child: Row(
                children: [
                  if (!kIsWeb)
                  _SortButton(
                    label: "Notif",
                    active: _sortKey == SortKey.notifications,
                    asc: _sortAsc,
                    onTap: () {
                      setState(() {
                        if (_sortKey == SortKey.notifications) {
                          _sortAsc = !_sortAsc;
                        } else {
                          _sortKey = SortKey.notifications;
                          _sortAsc = false; // default: true first
                        }
                        _applySort();
                      });
                    },
                    flex: 20,
                  ),
                  _SortButton(
                    label: "Name",
                    active: _sortKey == SortKey.name,
                    asc: _sortAsc,
                    onTap: () {
                      setState(() {
                        if (_sortKey == SortKey.name) {
                          _sortAsc = !_sortAsc;
                        } else {
                          _sortKey = SortKey.name;
                          _sortAsc = true;
                        }
                        _applySort();
                      });
                    },
                    flex: !kIsWeb ? 50 : 60,
                  ),
                  _SortButton(
                    label: "Diff",
                    active: _sortKey == SortKey.ratio,
                    asc: _sortAsc,
                    onTap: () {
                      setState(() {
                        if (_sortKey == SortKey.ratio) {
                          _sortAsc = !_sortAsc;
                        } else {
                          _sortKey = SortKey.ratio;
                          _sortAsc = false; // high ratio first
                        }
                        _applySort();
                      });
                    },
                    flex: 20,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredItems.length,
                itemBuilder: (_, index) {
                  final meal = _filteredItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      left: !kIsWeb ? 8 : 16,
                      right: 8,
                      bottom: 8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (!kIsWeb)
                          Expanded(
                            flex: 10,
                            child: IconButton(
                              color: Colors.white,
                              icon: Icon(
                                meal.notify
                                    ? Icons.notifications_active
                                    : Icons.notifications_none_outlined,
                              ),
                              iconSize: 20,
                              onPressed: () {
                                setState(() {
                                  if (notificationsBox.get(
                                        "enableNotifications",
                                        defaultValue: false,
                                      ) &&
                                      notificationsBox.get(
                                        "notifMeals",
                                        defaultValue: false,
                                      )) {
                                    setMealNotif(meal.name, !meal.notify);
                                  }
                                });
                                NotiService().refreshNotifications();
                              },
                            ),
                          ),

                        Expanded(
                          flex: 60,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Text(
                                meal.name,
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              Text(
                                '${meal.numOccurrences} appearance${meal.numOccurrences == 1 ? '' : 's'} in the current cycle',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),

                        RatingsWidget(
                          meal: meal,
                          onVote: (newVote) {
                            setState(() {
                              if (!kIsWeb) rateMeal(meal.name, newVote);
                            });
                          },
                          colourOverride: Colors.white,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Expanded(
            //   child: ListView.builder(
            //     itemCount: _filteredItems.length,
            //     itemBuilder: (_, index) {
            //       final item = _filteredItems[index];
            //       return ListTile(
            //         title: Text(
            //           item.name,
            //           style: const TextStyle(color: Colors.white),
            //         ),
            //         subtitle: Text(
            //           'Community Rating: ${(item.likes - item.dislikes).toStringAsFixed(1)}',
            //           style: const TextStyle(color: Colors.white70),
            //         ),
            //         trailing: Row(
            //           mainAxisSize: MainAxisSize.min,
            //           children: [
            //             GestureDetector(
            //               onTap: () => _showRatingPicker(item),
            //               child: Container(
            //                 padding: const EdgeInsets.symmetric(
            //                   horizontal: 8,
            //                   vertical: 4,
            //                 ),
            //                 decoration: BoxDecoration(
            //                   border: Border.all(color: Colors.transparent),
            //                   borderRadius: BorderRadius.circular(4),
            //                 ),
            //                 child: Text(
            //                   item.myVote.toString(),
            //                   style: const TextStyle(
            //                     color: Colors.white,
            //                     fontSize: 15,
            //                   ),
            //                 ),
            //               ),
            //             ),
            //             const SizedBox(width: 8),
            //             IconButton(
            //               icon: Icon(
            //                 item.notify
            //                     ? Icons.favorite
            //                     : Icons.favorite_border,
            //                 color: Colors.white,
            //               ),
            //               onPressed: () {
            //                 setState(() {
            //                   item.notify = !item.notify;
            //                   _updateItem(item);
            //                 });
            //                 NotiService().refreshNotifications();
            //                 _uploadRating(item);
            //               },
            //             ),
            //           ],
            //         ),
            //       );
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final String label;
  final bool active;
  final bool asc;
  final VoidCallback onTap;
  final int flex;

  const _SortButton({
    required this.label,
    required this.active,
    required this.asc,
    required this.onTap,
    required this.flex,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: TextButton(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white70,
                fontSize: 16,
              ),
            ),
            if (active)
              Icon(
                asc ? Icons.arrow_upward_sharp : Icons.arrow_downward_sharp,
                size: 18,
                color: Colors.white,
              ),
          ],
        ),
      ),
    );
  }
}
