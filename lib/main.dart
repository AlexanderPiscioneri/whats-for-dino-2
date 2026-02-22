import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:whats_for_dino_2/models/server_message.dart';
import 'package:whats_for_dino_2/services/firebase_options.dart';
import 'package:whats_for_dino_2/pages/favourites.dart';
import 'package:whats_for_dino_2/pages/feedback.dart';
import 'package:whats_for_dino_2/pages/notifications.dart';
import 'package:whats_for_dino_2/pages/settings.dart';
import 'package:whats_for_dino_2/pages/wfd.dart';
import 'package:whats_for_dino_2/services/noti_service.dart';
import 'package:whats_for_dino_2/services/utils.dart';
import 'package:web/web.dart' as web;

import 'package:whats_for_dino_2/theme/theme_provider.dart';

Color containerColour = Color.fromARGB(73, 0, 0, 0);

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<WfdPageState> wfdKey = GlobalKey<WfdPageState>();

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

Future<void> checkServerMessages() async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;
    final metaDataBox = Hive.box('metaDataBox');

    final doc =
        await FirebaseFirestore.instance
            .collection('metadata')
            .doc('messages')
            .get();

    if (!doc.exists) return;

    final rawMessages = doc.data()?['messages'] as List<dynamic>? ?? [];
    // final rawMessages = [
    //   {
    //     "id": "test_info",
    //     "title": "Sorry For A Bad Launch",
    //     "text": "If you downloaded the app early on you would've found loading the menu to be impossible - sorry for that - if you're seeing this message it means you've updated, and that you'll never see that loading circle ever again.",
    //     "type": "info",
    //     "conditions": {},
    //   },
    //   {
    //     "id": "test_warning",
    //     "title": "Heads Up",
    //     "text": "This is a test warning message. Dismiss this one to see the next.",
    //     "type": "warning",
    //     "conditions": {},
    //   },
    //   {
    //     "id": "show_once",
    //     "title": "Heads Up",
    //     "text": "You should only ever see me once",
    //     "type": "warning",
    //     "showOnce": true,
    //     "buttonText": "Alright I believe you",
    //     "conditions": {},
    //   },
    // ];
    final now = DateTime.now();

    // Load previously seen one-time message IDs
    final seenIds = Set<String>.from(
      metaDataBox.get('seenMessageIds', defaultValue: []) as List,
    );

    final messages =
        rawMessages
            .map((m) => ServerMessage.fromJson(Map<String, dynamic>.from(m)))
            .where((message) {
              if (!message.isActive(now, version)) return false;
              if (message.showOnce && seenIds.contains(message.id))
                return false;
              return true;
            })
            .toList();

    await Future.delayed(const Duration(milliseconds: 500));

    for (final message in messages) {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      final icon = switch (message.type) {
        'warning' => (Icons.warning_amber_rounded, Colors.orange),
        'error' => (Icons.error_rounded, Colors.red),
        _ => (Icons.info_rounded, Colors.blue),
      };

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              icon: Icon(icon.$1, color: icon.$2, size: 36),
              title: Text(
                message.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content: Text(
                message.text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                    message.buttonText,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
      );
      // Mark as seen after dismissal if it's a one-time message
      if (message.showOnce) {
        seenIds.add(message.id);
        await metaDataBox.put('seenMessageIds', seenIds.toList());
      }
    }
  } catch (e) {
    debugPrint("Error checking server messages: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Hive.initFlutter();
  await NotiService().initNotification();

  await Hive.openBox('metaDataBox');
  await Hive.openBox('menuBox');
  await Hive.openBox('mealsBox');
  await Hive.openBox('settingsBox');
  await Hive.openBox('notificationsBox');

  // Initialize Firebase safely
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: WhatsForDinoApp(),
    ),
  );

  // Post-run async tasks (can safely use Firebase here)
  ensureInstallDocument();
}

// Separate async function for Firebase
Future<void> initializeFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // Firestore / server setup can be called safely
    await ensureInstallDocument();
    await checkServerMessages();
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }
}

class WhatsForDinoApp extends StatefulWidget {
  const WhatsForDinoApp({super.key});

  @override
  State<WhatsForDinoApp> createState() => _WhatsForDinoAppState();
}

class _WhatsForDinoAppState extends State<WhatsForDinoApp> {
  int currentPage = 2;

  void navigateToPage(int index) {
    wfdKey.currentState?.animateToToday();
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

      pages = [SettingsPage(), WfdPage(key: wfdKey), FeedbackPage()];

      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        BottomNavigationBarItem(
          icon: Icon(Icons.food_bank),
          label: "What's For Dino",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.messenger), label: "Feedback"),
      ];

      currentPage = 1; // default to WFD

      debugPrint(currentUniversalPlatform.toString());

      final userAgent = web.window.navigator.userAgent.toLowerCase();

      if (userAgent.contains('iphone') ||
          userAgent.contains('ipad') ||
          userAgent.contains('ipod')) {
        openLink("https://apps.apple.com/au/app/whats-for-dino-2/id6758697602");
      } else if (userAgent.contains('android')) {
        // Android not available yet
        // openLink("https://play.google.com/store/apps/details?id=com.AlexanderPiscioneri.WhatsForDino2");
      }
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
        WfdPage(key: wfdKey),
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

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   checkServerMessages();
    // });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ThemeProvider>(context, listen: false).setDarkMode(
        Hive.box('settingsBox').get("enableDarkMode", defaultValue: false),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Provider.of<ThemeProvider>(context, listen: false).setDarkMode(
    //     Hive.box('settingsBox').get("enableDarkMode", defaultValue: false),
    //   );
    // });
    ColorScheme currentColourScheme =
        Provider.of<ThemeProvider>(context).themeData.colorScheme;

    return MaterialApp(
      title: "What's For Dino 2",
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      navigatorKey: navigatorKey,
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
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,

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
