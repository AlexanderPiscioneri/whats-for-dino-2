import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:whats_for_dino_2/models/server_message.dart';
import 'package:whats_for_dino_2/services/firebase_options.dart';
import 'package:whats_for_dino_2/pages/catalogue.dart';
import 'package:whats_for_dino_2/pages/feedback.dart';
import 'package:whats_for_dino_2/pages/notifications.dart';
import 'package:whats_for_dino_2/pages/settings.dart';
import 'package:whats_for_dino_2/pages/wfd.dart';
import 'package:whats_for_dino_2/services/noti_service.dart';
import 'package:whats_for_dino_2/services/utils.dart';
import 'package:whats_for_dino_2/services/web_utils.dart';
import 'package:whats_for_dino_2/theme/theme_provider.dart';

Color containerColour = Color.fromARGB(73, 0, 0, 0);

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<WfdPageState> wfdKey = GlobalKey<WfdPageState>();

Future<void> ensureInstallDocument() async {
  if (kIsWeb) return;
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
    //     "id": "26T1_BandNight",
    //     "title": "",
    //     "text": "Special menu and live performances this evening.",
    //     "type": "",
    //     "conditions": {"dateFrom": "08/05/2026", "dateTo": "08/05/2026"},
    //     "imageName": "26T1_BandNight.png",
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

    for (final message in messages) {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      final icon = switch (message.type) {
        'warning' => (Icons.warning_amber, Colors.orange),
        'error' => (Icons.error_outline_sharp, Colors.red),
        'info' => (Icons.info_outline, Colors.white),
        _ => null,
      };

      ImageProvider? imageProvider;

      if (message.imageUrl != null) {
        imageProvider = NetworkImage(message.imageUrl!);

        await precacheImage(imageProvider, context);
      }
      
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              icon: null,
              title: null,
              contentPadding: EdgeInsets.zero,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null || message.title.isNotEmpty)
                    Container(
                      color: Theme.of(context).colorScheme.surface,
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        color: Theme.of(context).colorScheme.primary,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (icon != null)
                              Icon(icon.$1, color: icon.$2, size: 36),
                            if (message.title.isNotEmpty)
                              Text(
                                message.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (icon == null && message.title.isEmpty)
                    Container(
                      color: Theme.of(context).colorScheme.surface,
                      height: 4,
                    ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 4,
                        right: 4,
                        top: 0,
                        bottom: 0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (imageProvider != null)
                            Image(image: imageProvider, fit: BoxFit.scaleDown),
                          if (message.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                message.text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            message.buttonText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
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
  checkServerMessages();
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
    if (settingsBox.get("hapticFeedback", defaultValue: true))
      HapticFeedback.mediumImpact();
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
      // titles = ["SETTINGS", "WHAT'S FOR DINO", "FEEDBACK"];

      // pages = [SettingsPage(), WfdPage(key: wfdKey), FeedbackPage()];

      // navItems = const [
      //   BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
      //   BottomNavigationBarItem(
      //     icon: Icon(Icons.food_bank),
      //     label: "What's For Dino",
      //   ),
      //   BottomNavigationBarItem(icon: Icon(Icons.messenger), label: "Feedback"),
      // ];

      // currentPage = 1; // default to WFD

      final userAgent = getUserAgent();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (userAgent.contains('iphone') ||
            userAgent.contains('ipad') ||
            userAgent.contains('ipod')) {
          _showStorePopup(
            title: "Download on the App Store",
            url: "https://apps.apple.com/au/app/whats-for-dino-2/id6758697602",
          );
        } else if (userAgent.contains('android')) {
          _showStorePopup(
            title: "Download on Google Play",
            url:
                "https://play.google.com/store/apps/details?id=com.AlexanderPiscioneri.WhatsForDino2",
          );
        }
      });
    }

    titles = [
      "SETTINGS",
      "NOTIFICATIONS",
      "WHAT'S FOR DINO",
      "FEEDBACK",
      "CATALOGUE",
    ];

    pages = [
      SettingsPage(),
      NotificationsPage(),
      WfdPage(key: wfdKey),
      FeedbackPage(),
      CataloguePage(),
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
      BottomNavigationBarItem(icon: Icon(Icons.list), label: "Catalogue"),
    ];

    currentPage = 2; // default to WFD

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   checkServerMessages();
    // });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ThemeProvider>(context, listen: false).setDarkMode(
        Hive.box('settingsBox').get("enableDarkMode", defaultValue: false),
      );
    });
  }

  void _showStorePopup({required String title, required String url}) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(ctx).colorScheme.primary,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: const Text(
            "WFD is better as a native mobile app.\n\nWould you like to download it now?",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // <-- THIS makes it square
                ),
              ),
              child: const Text("Not Now"),
            ),

            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                openLink(url);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // <-- square
                ),
              ),
              child: const Text(
                "Download",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
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
