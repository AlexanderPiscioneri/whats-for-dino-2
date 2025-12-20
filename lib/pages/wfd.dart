import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:whats_for_dino_2/models/menu.dart';
import 'package:whats_for_dino_2/services/menu_cache.dart';
import 'package:whats_for_dino_2/services/firestore.dart';
import 'package:whats_for_dino_2/services/food_cache.dart';
import 'package:whats_for_dino_2/services/noti_service.dart';
import 'package:whats_for_dino_2/theme/theme_provider.dart';

class WfdPage extends StatefulWidget {
  const WfdPage({super.key});

  @override
  State<WfdPage> createState() => _WfdPageState();
}

class _WfdPageState extends State<WfdPage> {
  final FirestoreService firestoreService = FirestoreService();
  final menuBox = Hive.box('menuBox');
  final settingsBox = Hive.box('settingsBox');

  late String dateText;
  late String dayText;
  int _pageViewKey = 0; // Add this to force PageView rebuild
  bool menuLoading = true;

  @override
  void initState() {
    super.initState();

    if (!MenuCache.isInitialized) {
      _initializeData();
      // Set temporary values while loading
      dateText = DateFormat('dd/MM/yyyy').format(DateTime.now());
      dayText = "Loading...";
    } else {
      // Data already exists, recreate PageController with today's index
      final todayIndex = _findTodayIndex();
      MenuCache.pageController?.dispose();
      MenuCache.pageController = PageController(initialPage: todayIndex);

      // Initialize labels immediately to match the page being displayed
      dayText = MenuCache.dayMenus[todayIndex].dayName;
      dateText = MenuCache.dayMenus[todayIndex].dayDate;
    }

    initializeFoodItems();
    NotiService().refreshNotifications();
  }

  @override
  void dispose() {
    // Don't dispose the PageController - keep it alive for next time
    super.dispose();
  }

  Future<void> _initializeData() async {
    // Load from local storage
    await _loadFromLocal();

    if (MenuCache.dayMenus.isNotEmpty) {
      final todayIndex = _findTodayIndex();
      MenuCache.pageController = PageController(initialPage: todayIndex);

      if (mounted) {
        setState(() {
          MenuCache.isInitialized = true;
          // Set the correct labels
          dayText = MenuCache.dayMenus[todayIndex].dayName;
          dateText = MenuCache.dayMenus[todayIndex].dayDate;
        });
      }
    }

    // Fetch from server in background
    _fetchFromServer();
  }

  Future<void> _loadFromLocal() async {
    try {
      final data = menuBox.get('dayMenus');
      if (data == null) return;

      final jsonList = jsonDecode(data) as List;
      MenuCache.dayMenus =
          jsonList.map((d) {
            final dayMenuJson = d['dayMenu'] as Map<String, dynamic>;
            return DayMenu.fromJson(dayMenuJson);
          }).toList();

      debugPrint(
        "Loaded ${MenuCache.dayMenus.length} day menus from local storage",
      );
    } catch (e) {
      debugPrint("Error loading from local: $e");
    }
  }

  Future<void> _fetchFromServer() async {
    try {
      QuerySnapshot snapshot = await firestoreService.getMenusOnce();

      final fetchedMenus =
          snapshot.docs
              .map((doc) => Menu.fromJson(doc.data() as Map<String, dynamic>))
              .toList();

      final newDayMenus = generateFullDayMenusList(fetchedMenus);

      debugPrint("Fetched data from server, updating cache...");
      final todayIndex = _findTodayIndexForList(newDayMenus);

      // Recreate PageController with new data and today's index
      MenuCache.pageController?.dispose();
      MenuCache.pageController = PageController(initialPage: todayIndex);

      if (mounted) {
        setState(() {
          MenuCache.menus = fetchedMenus;
          MenuCache.dayMenus = newDayMenus;
          MenuCache.isInitialized = true;
          _pageViewKey++; // Force PageView to rebuild
          // Update labels
          dayText = MenuCache.dayMenus[todayIndex].dayName;
          dateText = MenuCache.dayMenus[todayIndex].dayDate;
        });
      }

      await _saveToLocal();
      debugPrint("Updated menus from server, initial page: $todayIndex");
    } catch (e) {
      debugPrint("Error fetching from server: $e");
    }
  }

  Future<void> _saveToLocal() async {
    try {
      final jsonList =
          MenuCache.dayMenus.map((dayMenu) {
            return {
              "dayMenu": {
                "dayName": dayMenu.dayName,
                "dayDate": dayMenu.dayDate,
                "breakfast": dayMenu.breakfast.map((m) => m.toJson()).toList(),
                "brunch": dayMenu.brunch?.map((m) => m.toJson()).toList(),
                "lunch": dayMenu.lunch.map((m) => m.toJson()).toList(),
                "dinner": dayMenu.dinner.map((m) => m.toJson()).toList(),
              },
            };
          }).toList();

      await menuBox.put('dayMenus', jsonEncode(jsonList));
      debugPrint("Saved ${jsonList.length} day menus to local storage");
    } catch (e) {
      debugPrint("Error saving to local: $e");
    }
  }

  // void _resetCache() async {
  //   // Clear static cache
  //   MenuCache.menus = [];
  //   MenuCache.dayMenus = [];
  //   MenuCache.pageController?.dispose();
  //   MenuCache.pageController = null;
  //   MenuCache.isInitialized = false;

  //   // Clear Hive storage
  //   await menuBox.delete('dayMenus');

  //   // Reinitialize
  //   if (mounted) {
  //     setState(() {
  //       dateText = DateFormat('dd/MM/yyyy').format(DateTime.now());
  //       dayText = "Loading...";
  //       _pageViewKey++;
  //     });
  //     await _initializeData();
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    ColorScheme currentColourScheme = Theme.of(context).colorScheme;

    if (!MenuCache.isInitialized ||
        MenuCache.dayMenus.isEmpty ||
        MenuCache.pageController == null) {
      menuLoading = true;
      return Scaffold(
        backgroundColor: currentColourScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
              const Text(
                "Loading menu data...",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    menuLoading = false;
    final todayIndex = _findTodayIndex();

    return Scaffold(
      backgroundColor: currentColourScheme.surface,
      // Uncomment for development
      // floatingActionButton: FloatingActionButton(
      //   mini: true,
      //   onPressed: _resetCache,
      //   child: Icon(Icons.refresh),
      //   backgroundColor: Colors.red.withOpacity(0.7),
      // ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              color: Colors.transparent,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap:
                      MenuCache.menus.isEmpty
                          ? null
                          : () async {
                            DateTime? selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateFormat(
                                'dd/MM/yyyy',
                              ).parse(MenuCache.dayMenus[todayIndex].dayDate),
                              firstDate: MenuCache.menus.first.startDate,
                              lastDate: MenuCache.menus.last.endDate,
                              selectableDayPredicate: (date) {
                                return MenuCache.dayMenus.any((d) {
                                  try {
                                    if (d.dayDate.isEmpty) return false;
                                    var parts = d.dayDate.split('/');
                                    if (parts.length != 3) return false;
                                    int dayInt = int.parse(parts[0].trim());
                                    int monthInt = int.parse(parts[1].trim());
                                    int yearInt = int.parse(parts[2].trim());
                                    return date.day == dayInt &&
                                        date.month == monthInt &&
                                        date.year == yearInt;
                                  } catch (e) {
                                    return false;
                                  }
                                });
                              },
                              builder: (context, child) {
                                final baseTheme = Theme.of(context);

                                return Theme(
                                  data: baseTheme.copyWith(
                                    // This controls "January 2026"
                                    colorScheme: baseTheme.colorScheme.copyWith(
                                      onSurface: Colors.white,
                                      surfaceTint:
                                          Colors
                                              .transparent, // Doesn't seem to do anything
                                      outline: Colors.transparent,
                                    ),

                                    // OK / CANCEL colour
                                    textButtonTheme: TextButtonThemeData(
                                      style: ButtonStyle(
                                        foregroundColor:
                                            WidgetStateProperty.all(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                  ),
                                  child: DatePickerTheme(
                                    data: DatePickerThemeData(
                                      headerBackgroundColor:
                                          currentColourScheme
                                              .primary, // top bar

                                      headerForegroundColor:
                                          Colors
                                              .white, // header icons + some header text

                                      backgroundColor:
                                          currentColourScheme
                                              .surface, // calendar body

                                      dividerColor: Colors.transparent,

                                      // These styles only affect secondary header text
                                      headerHelpStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      headerHeadlineStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 40,
                                        fontWeight: FontWeight.normal,
                                      ),

                                      // Weekday letters styling
                                      weekdayStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),

                                      dayForegroundColor:
                                          WidgetStateColor.resolveWith((
                                            states,
                                          ) {
                                            if (states.contains(
                                              WidgetState.selected,
                                            )) {
                                              return Colors.white;
                                            }
                                            if (states.contains(
                                              WidgetState.disabled,
                                            )) {
                                              return Colors.white24;
                                            }
                                            return Colors.white70;
                                          }),

                                      todayForegroundColor:
                                          WidgetStateColor.resolveWith((
                                            states,
                                          ) {
                                            return Colors.white;
                                          }),

                                      confirmButtonStyle: ButtonStyle(
                                        shape: WidgetStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ), // smaller radius
                                          ),
                                        ),
                                      ),

                                      cancelButtonStyle: ButtonStyle(
                                        shape: WidgetStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                      ),

                                      yearForegroundColor:
                                          WidgetStateColor.resolveWith((
                                            states,
                                          ) {
                                            if (states.contains(
                                              WidgetState.selected,
                                            )) {
                                              return Colors.white;
                                            }
                                            if (states.contains(
                                              WidgetState.disabled,
                                            )) {
                                              return Colors.white24;
                                            }
                                            return Colors.white70;
                                          }),

                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.zero,
                                      ),
                                    ),
                                    child: child!,
                                  ),
                                );
                              },
                            );

                            if (selectedDate != null) {
                              String selectedDateStr = DateFormat(
                                'dd/MM/yyyy',
                              ).format(selectedDate);
                              int targetIndex = MenuCache.dayMenus.indexWhere(
                                (d) => d.dayDate == selectedDateStr,
                              );
                              if (targetIndex != -1 &&
                                  MenuCache.pageController != null) {
                                MenuCache.pageController!.animateToPage(
                                  targetIndex,
                                  duration: Duration(milliseconds: 1000),
                                  curve: Curves.easeInOutCubic,
                                );
                              }
                            }
                          },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dayText,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          dateText,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 94,
            child: PageView.builder(
              key: ValueKey(_pageViewKey), // Add key to force rebuild
              controller: MenuCache.pageController!,
              scrollDirection: Axis.horizontal,
              itemCount: MenuCache.dayMenus.length,
              itemBuilder: (context, index) {
                final dayMenu = MenuCache.dayMenus[index];

                String dinnerSectionName = "Dinner";
                if (dayMenu.hasEarlyDinner == true) {
                  dinnerSectionName = "E. Dinner";
                  if (settingsBox.get("showTimesOnMenu", defaultValue: true) ==
                      false) {
                    dinnerSectionName =
                        "Early Dinner"; // there is space bc times aren't showing
                  }
                }

                bool isBetweenMenusPage =
                    dayMenu.dayName.contains("||") == false;

                return Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                  child: Container(
                    color:
                        Provider.of<ThemeProvider>(
                          context,
                        ).themeData.colorScheme.secondary,
                    child:
                        isBetweenMenusPage
                            ? ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                _mealSection("Breakfast", dayMenu.breakfast),
                                if (dayMenu.brunch != null)
                                  _mealSection("Brunch", dayMenu.brunch!),
                                _mealSection("Lunch", dayMenu.lunch),
                                _mealSection(dinnerSectionName, dayMenu.dinner),
                              ],
                            )
                            : _betweenMenusPage(dayMenu.dayName),
                  ),
                );
              },
              onPageChanged: (index) {
                setState(() {
                  dayText = MenuCache.dayMenus[index].dayName;
                  dateText = MenuCache.dayMenus[index].dayDate;
                  if (todayIndex == index && dayText.contains("||") == false) {
                    dayText += " (Today)";
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  int _findTodayIndex() {
    return _findTodayIndexForList(MenuCache.dayMenus);
  }

  int _findTodayIndexForList(List<DayMenu> menuList) {
    if (menuList.length < 3) return 0;

    DateTime now = DateTime.now();

    for (int i = 1; i < menuList.length - 1; i++) {
      try {
        if (menuList[i - 1].dayDate.isEmpty ||
            menuList[i + 1].dayDate.isEmpty) {
          continue;
        }

        DateTime previous = DateFormat(
          'dd/MM/yyyy',
        ).parse(menuList[i - 1].dayDate);
        DateTime current = DateFormat('dd/MM/yyyy').parse(menuList[i].dayDate);
        DateTime next = DateFormat('dd/MM/yyyy').parse(menuList[i + 1].dayDate);

        if (now.isAfter(previous) &&
            now.isBefore(next) &&
            current.difference(previous).inDays > 2) {
          return i;
        }

        if (menuList[i].dayDate.isNotEmpty) {
          if (_isSameDay(now, current)) {
            return i;
          }
        }
      } catch (e) {
        debugPrint("Error parsing date at index $i: $e");
        continue;
      }
    }

    try {
      if (menuList.first.dayDate.isNotEmpty) {
        DateTime firstDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(menuList.first.dayDate);
        if (_isSameDay(now, firstDate) || now.isBefore(firstDate)) {
          return 0;
        }
      }

      if (menuList.last.dayDate.isNotEmpty) {
        DateTime lastDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(menuList.last.dayDate);
        if (_isSameDay(now, lastDate) || now.isAfter(lastDate)) {
          return menuList.length - 1;
        }
      }
    } catch (e) {
      debugPrint("Error checking boundaries: $e");
    }

    return 0;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _mealSection(String title, List<MealItem> items) {
    String sectionTitle = title;
    if (settingsBox.get("showTimesOnMenu", defaultValue: true)) {
      sectionTitle = "$title ${mealToTimeString(title)}";
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          sectionTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              item.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

String asciiArt = '''
                              _.-.
                             /  99\\
                            (     `\\
                            |\\ ,  ,|
                    __      | \\____/
              ,.--"`-.".   /   `---'
          _.-'          '-/      |
      _.-"   |   '-.             |_/_
,__.-'  _,.--\\      \\      ((    /-\\
',_..--'      `\\     \\      \\\\_ /
                `-,   )      |\\' 
                  |   |-.,,-" (  
                  |   |   `\\   `',_
                  )    \\    \\,(\\(\\-'
              jgs \\     `-,_
                   \\_(\\-(\\`-`
                      "  "  
''';

String asciiArt2 = '''

                                              ____
  ___                                      .-~. /_"-._
`-._~-.                                  / /_ "~o\\  :Y
      \\  \\                                / : \\~x.  ` ')
      ]  Y                              /  |  Y< ~-.__j
     /   !                        _.--~T : l  l<  /.-~
    /   /                 ____.--~ .   ` l /~\\ <|Y
   /   /             .-~~"        /| .    ',-~\\ \\L|
  /   /             /     .^   \\ Y~Y \\.^>/l_   "--'
 /   Y           .-"(  .  l__  j_j l_/ /~_.-~    .
Y    l          /    \\  )    ~~~." / `/"~ / \\.__/l_
|     \\     _.-"      ~-{__     l  :  l._Z~-.___.--~
|      ~---~           /   ~~"---\\_  ' __[>
l  .                _.^   ___     _>-y~
 \\  \\     .      .-~   .-~   ~>--"  /
  \\  ~---"            /     ./  _.-'
   "-.,_____.,_  _.--~\\     _.-~
               ~~     (   _}       -Row
                      `. ~(
                        )  \\
                  /,`--'~\\--'~\\
''';

  Widget _betweenMenusPage(String dayName) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          asciiArt,
          style: const TextStyle(fontFamily: "Courier New", fontSize: 8, fontWeight: FontWeight.w900),
        ),
        Divider(
          color: Theme.of(context).colorScheme.surface,
          indent: 10,
          endIndent: 10,
          thickness: 5,
        ),
        Text(
          dayName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
        ),
        Divider(
          color: Theme.of(context).colorScheme.surface,
          indent: 10,
          endIndent: 10,
          thickness: 5,
        ),
        Text(
          asciiArt2,
          style: const TextStyle(fontFamily: "Courier New", fontSize: 8, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

String mealToTimeString(String meal) {
  switch (meal) {
    case "Breakfast":
      return "(7:30 am - 10 am)";
    case "Brunch":
      return "(10am - 12 pm)";
    case "Lunch":
      return "(12 pm - 2:15 pm)";
    case "Dinner":
      return "(5 pm - 7:30 pm)";
    case "E. Dinner":
      return "(4:30 pm - 5:30 pm)";
    case "Early Dinner":
      return "(4:30 pm - 5:30 pm)";
    default:
      return "meal is not recognised";
  }
}

List<DayMenu> generateFullDayMenusList(List<Menu> menus) {
  if (menus.isEmpty) return [];

  menus.sort((a, b) => a.startDate.compareTo(b.startDate));

  List<DayMenu> newDayMenus = [];

  for (int m = 0; m < menus.length; m++) {
    final menu = menus[m];

    List<DayMenu> cycle = [for (var w in menu.weeks) ...w.days];

    DateTime date = menu.startDate;
    int totalDays = menu.endDate.difference(menu.startDate).inDays + 1;

    for (int i = 0; i < totalDays; i++) {
      DayMenu todayMenu = cycle[i % cycle.length].copy();
      todayMenu.dayDate = DateFormat('dd/MM/yyyy').format(date);

      // Find all exceptions for this day
      final exceptionsForDay = menu.exceptions.where(
        (e) => e.dayDate == todayMenu.dayDate,
      );

      // Apply all exceptions for this day if there are any
      for (final exception in exceptionsForDay) {
        exception.applyTo(todayMenu);
      }

      newDayMenus.add(todayMenu);
      date = date.add(const Duration(days: 1));
    }

    if (m < menus.length - 1) {
      final nextMenu = menus[m + 1];
      if (date.isBefore(nextMenu.startDate)) {
        int diff = nextMenu.startDate.difference(date).inDays;
        if (diff > 0) {
          newDayMenus.add(
            DayMenu(
              dayName: "${menu.name} || ${nextMenu.name}",
              dayDate: DateFormat(
                'dd/MM/yyyy',
              ).format(date.add(Duration(days: diff ~/ 2))),
              breakfast: [
                MealItem(
                  name: "$diff days between ${menu.name} and ${nextMenu.name}",
                  rating: -1,
                ),
              ],
              lunch: [
                MealItem(
                  name: "Whatever you can get your hands on",
                  rating: -1,
                ),
              ],
              dinner: [MealItem(name: "Nothing", rating: -1)],
            ),
          );
        }
      }
    }
  }

  return newDayMenus;
}
