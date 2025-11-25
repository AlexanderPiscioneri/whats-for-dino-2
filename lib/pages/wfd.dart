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
  List<DayMenu> dayMenus = [];
  bool isLoading = true;
  DateTime dateTimeNow = DateTime.now();
  String dateText = DateFormat('dd/MM/yyyy').format(DateTime.now());
  String dayText = "${DateFormat('EEEE').format(DateTime.now())} (Today)";
  final menuBox = Hive.box('menuBox');
  int todayIndex = DateTime.now().difference(DateTime(2025, 9, 16)).inDays + 1;

  @override
  void initState() {
    super.initState();
    _initLocalThenServer();
  }

  Future<void> _initLocalThenServer() async {
    // 1. Try reading local data first
    await readLocaldayMenus(); // wait for local load to finish

    if (dayMenus.isNotEmpty) {
      setState(
        () {},
      ); // 2. If we have local data, use it and render immediately
    }

    // 3. Fetch from server in background
    fetchMenus();
  }

  Future<void> readLocaldayMenus() async {
    String? jsonString = menuBox.get('dayMenus');

    if (jsonString != null) {
      List<dynamic> jsonList = jsonDecode(jsonString);

      dayMenus =
          jsonList.map((d) {
            final dayMenuJson = d['dayMenu'] as Map<String, dynamic>;
            return DayMenu.fromJson(dayMenuJson);
          }).toList();
    }
  }

  void writeLocaldayMenus() async {
    // Convert dayMenus list to JSON
    List<Map<String, dynamic>> jsonList =
        dayMenus.map((dayMenu) {
          return {
            "dayMenu": {
              "dayName": dayMenu.dayName,
              "breakfast": dayMenu.breakfast.map((m) => m.toJson()).toList(),
              "brunch": dayMenu.brunch?.map((m) => m.toJson()).toList(),
              "lunch": dayMenu.lunch.map((m) => m.toJson()).toList(),
              "dinner": dayMenu.dinner.map((m) => m.toJson()).toList(),
            },
          };
        }).toList();

    // Store in Hive under a key, e.g., 'dayMenus'
    await menuBox.put('dayMenus', jsonEncode(jsonList));
  }

  Future<void> fetchMenus() async {
    try {
      QuerySnapshot snapshot = await firestoreService.getMenusOnce();
      setState(() {
        menus =
            snapshot.docs
                .map((doc) => Menu.fromJson(doc.data() as Map<String, dynamic>))
                .toList();
        dayMenus = generateFullDayMenusList(menus);
        writeLocaldayMenus();
        print("menu fetched");
      });
    } catch (e) {
      print("Error loading menus: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (dayMenus.isEmpty) {
      return Scaffold(
        backgroundColor: secondaryColour,
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
                "No local menu data, trying to fetch...",
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
              controller: PageController(initialPage: todayIndex),
              scrollDirection: Axis.horizontal,
              itemCount: dayMenus.length,
              itemBuilder: (context, index) {
                final dayMenu = dayMenus[index];

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
                //DateTime currentMenuStartDate = menus[menus.length].startDate;
                //int dayDifference = DateTime.now().difference(currentMenuStartDate).inDays;
                DateTime newDateTime = DateTime.now().add(Duration(days: index - todayIndex));
                setState(() {
                  dayText = dayMenus[index].dayName;
                  //if (DateTime.now().difference(menus[menus.length].endDate).inDays <= 0) {
                    dateText = DateFormat(
                    'dd/MM/yyyy',
                  ).format(newDateTime);
                  if (todayIndex == index) dayText += " (Today)";
                  //}
                  // else {
                  //   dateText = "No menu here yet :(";
                  // }
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

List<DayMenu> generateFullDayMenusList(List<Menu> menus) {
  if (menus.isEmpty) return [];

  // Sort menus by start date just in case
  menus.sort((a, b) => a.startDate.compareTo(b.startDate));

  List<DayMenu> newDayMenus = [];

  for (int m = 0; m < menus.length; m++) {
    final menu = menus[m];

    // Flatten menu weeks into 1 list
    List<DayMenu> cycle = [for (var w in menu.weeks) ...w.days];

    DateTime date = menu.startDate;
    int totalDays = menu.endDate.difference(menu.startDate).inDays + 1;

    for (int i = 0; i < totalDays; i++) {
      DayMenu todayMenu = cycle[i % cycle.length];
      newDayMenus.add(todayMenu);
      date = date.add(const Duration(days: 1));
    }

    // Add a gap day if next menu exists
    if (m < menus.length - 1) {
      final nextMenu = menus[m + 1];
      if (date.isBefore(nextMenu.startDate)) {
        // Compute "average" day between previous end and next start
        int diff = nextMenu.startDate.difference(date).inDays;
        if (diff > 0) {
          newDayMenus.add(blankDay); // placeholder
        }
      }
    }
  }

  return newDayMenus;
}

DayMenu blankDay = DayMenu(
  dayName: "Blank Day",
  breakfast: [MealItem(name: "Nothing Cereal", rating: -1)],
  lunch: [MealItem(name: "Unsatiating Burger", rating: -1)],
  dinner: [MealItem(name: "Hollow Steak", rating: -1)],
);
