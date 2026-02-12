import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:whats_for_dino_2/services/firebase_options.dart';
import 'package:whats_for_dino_2/pages/favourites.dart';
import 'package:whats_for_dino_2/pages/feedback.dart';
import 'package:whats_for_dino_2/pages/notifications.dart';
import 'package:whats_for_dino_2/pages/settings.dart';
import 'package:whats_for_dino_2/pages/wfd.dart';
import 'package:whats_for_dino_2/services/noti_service.dart';
import 'package:whats_for_dino_2/services/utils.dart';
import 'package:whats_for_dino_2/theme/theme_provider.dart';

Color containerColour = Color.fromARGB(73, 0, 0, 0);

Future<void> ensureInstallDocument() async {
  final installId = await getInstallId();
  final deviceInfo = await getDeviceInfo();

  final docRef = FirebaseFirestore.instance
      .collection('installs')
      .doc(installId);

  await docRef.set({
    'device': deviceInfo,
    'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Hive.initFlutter();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotiService().initNotification();

  await Hive.openBox('menuBox');
  await Hive.openBox('settingsBox');
  await Hive.openBox('notificationsBox');
  await Hive.openBox('favouritesBox');

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: WhatsForDinoApp(),
    ),
  );

  ensureInstallDocument();
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

  late final List<String> titles;
  late final List<Widget> pages;
  late final List<BottomNavigationBarItem> navItems;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      titles = ["SETTINGS", "WHAT'S FOR DINO", "FEEDBACK"];

      pages = [SettingsPage(), WfdPage(), FeedbackPage()];

      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        BottomNavigationBarItem(
          icon: Icon(Icons.food_bank),
          label: "What's For Dino",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.messenger), label: "Feedback"),
      ];

      currentPage = 1; // default to WFD
    } else {
      titles = [
        "SETTINGS",
        "NOTIFICATIONS",
        "WHAT'S FOR DINO",
        "FEEDBACK",
        "FAVOURITES",
      ];

      pages = [
        SettingsPage(),
        NotificationsPage(),
        WfdPage(),
        FeedbackPage(),
        FavouritesPage(),
      ];

      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: "Notifications",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.food_bank),
          label: "What's For Dino",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.messenger), label: "Feedback"),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: "Favourites",
        ),
      ];

      currentPage = 2; // default to WFD
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ThemeProvider>(context, listen: false).setDarkMode(
        Hive.box('settingsBox').get("enableDarkMode", defaultValue: false),
      );
    });
    ColorScheme currentColourScheme =
        Provider.of<ThemeProvider>(context).themeData.colorScheme;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Provider.of<ThemeProvider>(context).themeData,
      home: Scaffold(
        backgroundColor: currentColourScheme.surface,
        appBar: AppBar(
          title: Text(
            titles[currentPage],
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: currentColourScheme.primary,
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
            canvasColor: currentColourScheme.primary,
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: currentColourScheme.primary,
            currentIndex: currentPage,
            onTap: navigateToPage,
            selectedItemColor: Colors.white,
            unselectedItemColor: currentColourScheme.surface,
            iconSize: 42,
            selectedFontSize: 0,
            unselectedFontSize: 0,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: navItems,
          ),
        ),
      ),
    );
  }
}
