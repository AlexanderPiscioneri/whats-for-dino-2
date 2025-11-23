import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:whats_for_dino_2/main.dart';
import 'package:whats_for_dino_2/models/menu.dart';
import 'package:whats_for_dino_2/services/firestore.dart';

class WfdPage extends StatefulWidget {
  const WfdPage({super.key});

  @override
  State<WfdPage> createState() => _WfdPageState();
}

class _WfdPageState extends State<WfdPage> {
  final FirestoreService firestoreService = FirestoreService();

  List<Menu> menus = [];
  List<_DatedMenuDay> fullDays = [];
  bool isLoading = true;
  DateTime dateTimeNow = DateTime.now();
  String dateText = DateFormat('dd/MM/yyyy').format(DateTime.now());
  String dayText = "${DateFormat('EEEE').format(DateTime.now())} (Today)";
  final menuBox = Hive.box('menuBox');
  int todayIndex = -1;

  PageController _pageController = PageController(
    initialPage: 0,
  ); // add near your other fields

  @override
  void initState() {
    super.initState();
    dateTimeNow = DateTime.now();
    // todayIndex = menuBox.get("todayIndex", defaultValue: -1);
    todayIndex = menuBox.get('todayIndex', defaultValue: 0);
    _pageController = PageController(initialPage: todayIndex);
    _initLocalThenServer();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initLocalThenServer() async {
    // 1. Try reading local data first
    await readLocalFullDays(); // wait for local load to finish

    if (fullDays.isNotEmpty) {
      todayIndex = fullDays.indexWhere(
        (d) =>
            d.dateTime.year == dateTimeNow.year &&
            d.dateTime.month == dateTimeNow.month &&
            d.dateTime.day == dateTimeNow.day,
      );

      menuBox.put('todayIndex', todayIndex);

      _pageController.jumpToPage(todayIndex);

      // update header text
      dayText = DateFormat('EEEE').format(fullDays[todayIndex].dateTime);
      dayText += " (Today)";
      dateText = DateFormat('dd/MM/yyyy').format(fullDays[todayIndex].dateTime);

      setState(
        () {},
      ); // 2. If we have local data, use it and render immediately
    }

    // 3. Fetch from server in background
    fetchMenus();
  }

  Future<void> readLocalFullDays() async {
    String? jsonString = menuBox.get('fullDays');

    if (jsonString != null) {
      List<dynamic> jsonList = jsonDecode(jsonString);
      fullDays =
          jsonList.map((d) {
            final dayMenuJson = d['dayMenu'] as Map<String, dynamic>;
            return _DatedMenuDay(
              DateTime.parse(d['dateTime']),
              DayMenu.fromJson(dayMenuJson),
            );
          }).toList();
    }
  }

  void writeLocalFullDays() async {
    // Convert fullDays list to JSON
    List<Map<String, dynamic>> jsonList =
        fullDays.map((d) {
          return {
            "dateTime": d.dateTime.toIso8601String(),
            "dayMenu": {
              "dayName": d.dayMenu.dayName,
              "breakfast": d.dayMenu.breakfast.map((m) => m.toJson()).toList(),
              "brunch": d.dayMenu.brunch?.map((m) => m.toJson()).toList(),
              "lunch": d.dayMenu.lunch.map((m) => m.toJson()).toList(),
              "dinner": d.dayMenu.dinner.map((m) => m.toJson()).toList(),
            },
          };
        }).toList();

    // Store in Hive under a key, e.g., 'fullDays'
    await menuBox.put('fullDays', jsonEncode(jsonList));
  }

  Future<void> fetchMenus() async {
    try {
      QuerySnapshot snapshot = await firestoreService.getMenusOnce();
      setState(() {
        menus =
            snapshot.docs
                .map((doc) => Menu.fromJson(doc.data() as Map<String, dynamic>))
                .toList();
        fullDays = generateFullDayList(menus);
        writeLocalFullDays();
        print("menu fetched");
      });
    } catch (e) {
      print("Error loading menus: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (fullDays.isEmpty) {
      return Scaffold(
        backgroundColor: secondaryColour,
        body: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              const Text("No local menu data, trying to fetch..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: secondaryColour,
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
              ), // optional padding
              child: Row(
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
          Expanded(
            flex: 94,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              itemCount: fullDays.length,
              itemBuilder: (context, index) {
                final dayMenu = fullDays[index].dayMenu;

                return Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                  child: Container(
                    color: Colors.white,
                    child: ListView(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        // --- Meals ---
                        mealSection("Breakfast", dayMenu.breakfast),
                        if (dayMenu.brunch != null)
                          mealSection("Brunch", dayMenu.brunch!),
                        mealSection("Lunch", dayMenu.lunch),
                        mealSection("Dinner", dayMenu.dinner),
                      ],
                    ),
                  ),
                );
              },
              onPageChanged: (index) {
                DateTime dateTime = fullDays[index].dateTime;
                setState(() {
                  dayText = DateFormat('EEEE').format(dateTime);
                  dateText = DateFormat('dd/MM/yyyy').format(dateTime); // or format index → date
                  if (todayIndex == index) dayText += " (Today)";
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget mealSection(String title, List<MealItem> items) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        "$title ${titleToTime(title)}",
        textAlign: TextAlign.center, // ensures title stays centered
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 6),

      // Print each menu item
      ...items.map(
        (item) => Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Text(
            item.name,
            textAlign: TextAlign.center, // center the text
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
        ),
      ),

      const SizedBox(height: 16),
    ],
  );
}

String titleToTime(String title) {
  switch (title) {
    case "Breakfast":
      return "(7:30 am - 10 am)";
    case "Brunch":
      return "(10am - 12 pm)";
    case "Lunch":
      return "(12 pm - 2:15 pm)";
    case "Dinner":
      return "(5 pm - 7:30 pm)";
    case "Early Dinner":
      return "(4:30 pm - 5:30 pm)";
    default:
      return "Meal title is not recognised";
  }
}

class _DatedMenuDay {
  final DateTime dateTime;
  final DayMenu dayMenu;

  _DatedMenuDay(this.dateTime, this.dayMenu);
}

List<_DatedMenuDay> generateFullDayList(List<Menu> menus) {
  if (menus.isEmpty) return [];

  // Sort menus by start date just in case
  menus.sort((a, b) => a.startDate.compareTo(b.startDate));

  List<_DatedMenuDay> fullDays = [];

  for (int m = 0; m < menus.length; m++) {
    final menu = menus[m];

    // Flatten menu weeks into 1 list
    List<DayMenu> cycle = [for (var w in menu.weeks) ...w.days];

    DateTime date = menu.startDate;
    int totalDays = menu.endDate.difference(menu.startDate).inDays + 1;

    for (int i = 0; i < totalDays; i++) {
      DayMenu todayMenu = cycle[i % cycle.length];
      fullDays.add(_DatedMenuDay(date, todayMenu));
      date = date.add(const Duration(days: 1));
    }

    // Add a gap day if next menu exists
    if (m < menus.length - 1) {
      final nextMenu = menus[m + 1];
      if (date.isBefore(nextMenu.startDate)) {
        // Compute "average" day between previous end and next start
        int diff = nextMenu.startDate.difference(date).inDays;
        if (diff > 0) {
          DateTime midDate = date.add(Duration(days: diff ~/ 2));
          fullDays.add(_DatedMenuDay(midDate, blankDay)); // placeholder
        }
      }
    }
  }

  return fullDays;
}

DayMenu blankDay = DayMenu(
  dayName: "Blank Day",
  breakfast: [MealItem(name: "Nothing Cereal", rating: -1)],
  lunch: [MealItem(name: "Unsatiating Burger", rating: -1)],
  dinner: [MealItem(name: "Hollow Steak", rating: -1)],
);
