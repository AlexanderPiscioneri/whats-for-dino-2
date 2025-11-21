import 'package:flutter/material.dart';
import 'package:whats_for_dino_2/pages/feedback%20copy.dart';
import 'package:whats_for_dino_2/pages/feedback.dart';
import 'package:whats_for_dino_2/pages/notifications.dart';
import 'package:whats_for_dino_2/pages/settings.dart';
import 'package:whats_for_dino_2/pages/wfd.dart';

Color containerColour = Color.fromARGB(73, 0, 0, 0);
Color mainColour = Color.fromARGB(255, 35, 117, 35);
Color secondaryColour = Color.fromARGB(255, 29, 88, 29);

void main() {
  runApp(WhatsForDinoApp());
}

class WhatsForDinoApp extends StatefulWidget {
  const WhatsForDinoApp({super.key});

  @override
  State<WhatsForDinoApp> createState() => _WhatsForDinoAppState();
}

class _WhatsForDinoAppState extends State<WhatsForDinoApp> {
  int currentPage = 2;

  void navigateToPage(int index) {
    setState(() {
      currentPage = index;
    });
  }

  final List titles = [
    "SETTINGS",
    "NOTIFICATIONS",
    "WHAT'S FOR DINO",
    "FEEDBACK",
    "FAVOURITES",
  ];

  final List pages = [
    SettingsPage(),
    NotificationsPage(),
    WfdPage(),
    FeedbackPage(),
    FavouritesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: mainColour,
          surface: mainColour, // sets BottomNavigationBar background
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: mainColour, // bar color
          indicatorColor: Colors.transparent, // removes grey circle
          height: 60,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: Colors.white, size: 36);
            }
            return IconThemeData(color: Colors.grey, size: 32);
          }),
        ),
      ),
      home: Scaffold(
        backgroundColor: secondaryColour,
        appBar: AppBar(
          title: Text(
            titles[currentPage],
            style: TextStyle(fontWeight: FontWeight.w400, color: Colors.white),
            textScaler: TextScaler.linear(1.2),
          ),
          backgroundColor: mainColour,
          elevation: 8, // <-- SHADOW
          shadowColor: Colors.black, // <-- SHADOW COLOR
          surfaceTintColor:
              Colors.transparent, // <-- REQUIRED (Material 3 hides shadow)
          centerTitle: true,
        ),
        body: pages[currentPage],
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            canvasColor: mainColour,
          ),
          child: BottomNavigationBar(
            backgroundColor: mainColour,
            currentIndex: currentPage,
            onTap: navigateToPage,
            selectedItemColor: Colors.white,
            unselectedItemColor: secondaryColour,
            iconSize: 36,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: "Settings",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications),
                label: "Notifications",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.food_bank),
                label: "What's For Dino",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.messenger),
                label: "Feedback",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: "Favourites",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
