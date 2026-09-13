import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:whats_for_dino_2/services/utils.dart';
import 'package:whats_for_dino_2/theme/theme_provider.dart';
import 'package:whats_for_dino_2/widgets/standard_switch_list_tile.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _appVersionText = "";
  final settingsBox = Hive.box('settingsBox');

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();

    setState(() {
      _appVersionText = "Version ${info.version}, Build ${info.buildNumber}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              StandardSwitchListTile(
                title: "Dark Mode",
                value: settingsBox.get("enableDarkMode", defaultValue: false),
                onChanged: (value) {
                  settingsBox.put("enableDarkMode", value);
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).setDarkMode(value);
                  if (settingsBox.get("hapticFeedback", defaultValue: true))
                    HapticFeedback.mediumImpact();
                },
                activeColour: Theme.of(context).colorScheme.primary,
              ),
              StandardSwitchListTile(
                title: "Haptic Feedback",
                value: settingsBox.get("hapticFeedback", defaultValue: true),
                onChanged: (value) {
                  settingsBox.put("hapticFeedback", value);
                  setState(() {});
                  if (settingsBox.get("hapticFeedback", defaultValue: true))
                    HapticFeedback.mediumImpact();
                },
                activeColour: Theme.of(context).colorScheme.primary,
              ),
              Divider(
                color: Theme.of(context).colorScheme.primary,
                indent: 20,
                endIndent: 20,
              ),
              StandardSwitchListTile(
                title: "Show Meal Times",
                value: settingsBox.get("showTimesOnMenu", defaultValue: true),
                onChanged: (value) {
                  settingsBox.put("showTimesOnMenu", value);
                  setState(() {});
                  if (settingsBox.get("hapticFeedback", defaultValue: true))
                    HapticFeedback.mediumImpact();
                },
                activeColour: Theme.of(context).colorScheme.primary,
              ),
              if (!kIsWeb)
                StandardSwitchListTile(
                  title: "Show Notif Buttons",
                  value: settingsBox.get(
                    "showNotifButtons",
                    defaultValue: true,
                  ),
                  onChanged: (value) {
                    settingsBox.put("showNotifButtons", value);
                    setState(() {});
                    if (settingsBox.get("hapticFeedback", defaultValue: true))
                      HapticFeedback.mediumImpact();
                  },
                  activeColour: Theme.of(context).colorScheme.primary,
                ),
              StandardSwitchListTile(
                title: "Center Meal Text",
                value: settingsBox.get("centerMealText", defaultValue: false),
                onChanged: (value) {
                  settingsBox.put("centerMealText", value);
                  setState(() {});
                  if (settingsBox.get("hapticFeedback", defaultValue: true))
                    HapticFeedback.mediumImpact();
                },
                activeColour: Theme.of(context).colorScheme.primary,
              ),
              StandardSwitchListTile(
                title: "Show Ratings",
                value: settingsBox.get("showRatings", defaultValue: true),
                onChanged: (value) {
                  settingsBox.put("showRatings", value);
                  setState(() {});
                  if (settingsBox.get("hapticFeedback", defaultValue: true))
                    HapticFeedback.mediumImpact();
                },
                activeColour: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          ...feedbackItems(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_appVersionText, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<Widget> feedbackItems() {
    ColorScheme currentColourScheme = Theme.of(context).colorScheme;
    return [
      // Padding(
      //   padding: const EdgeInsets.symmetric(horizontal: 8.0),
      //   child: Text(
      //     'All feedback is always welcome.',
      //     textAlign: TextAlign.center,
      //     style: TextStyle(
      //       color: Colors.white,
      //       fontSize: 40,
      //       fontWeight: FontWeight.w400,
      //     ),
      //   ),
      // ),
      // Divider(color: Theme.of(context).colorScheme.primary),
      Divider(
        color: Theme.of(context).colorScheme.primary,
        indent: 20,
        endIndent: 20,
      ),
      ElevatedButton(
        onPressed: () {
          if (settingsBox.get("hapticFeedback", defaultValue: true))
            HapticFeedback.mediumImpact();
          openLink(
            "https://forms.office.com/Pages/ResponsePage.aspx?id=pM_2PxXn20i44Qhnufn7o91DYUQ6lW9MsGLk8aV9AgNUNlFXTDUwUEgwVzJQNUVYRjdMQVdJNkxSMS4u&origin=QRCode",
          );
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateColor.resolveWith(
            (_) => currentColourScheme.primary,
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          minimumSize: WidgetStateProperty.all(Size(170, 60)),
          elevation: WidgetStateProperty.resolveWith<double>((states) {
            if (states.contains(WidgetState.pressed)) {
              return 0; // pressed (flat)
            }
            return 8; // normal
          }),
        ),
        child: Text(
          'Dino Feedback Form',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Text(
      //   'Something wrong with the app?\nHave an idea for another feature?',
      //   textAlign: TextAlign.center,
      //   style: TextStyle(
      //     color: Colors.white,
      //     fontSize: 20,
      //     fontWeight: FontWeight.w400,
      //   ),
      // ),
      ElevatedButton(
        onPressed: () {
          if (settingsBox.get("hapticFeedback", defaultValue: true))
            HapticFeedback.mediumImpact();
          openLink("https://forms.gle/mc7dDUUe1d5iCwes9");
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateColor.resolveWith(
            (_) => currentColourScheme.primary,
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          minimumSize: WidgetStateProperty.all(Size(170, 60)),
          elevation: WidgetStateProperty.resolveWith<double>((states) {
            if (states.contains(WidgetState.pressed)) {
              return 0; // pressed (flat)
            }
            return 8; // normal
          }),
        ),
        child: Text(
          'Anonymous App Feedback Form',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Divider(
      //   color: Theme.of(context).colorScheme.primary,
      //   indent: 20,
      //   endIndent: 20,
      // ),

      ElevatedButton(
        onPressed: () {
          if (settingsBox.get("hapticFeedback", defaultValue: true))
            HapticFeedback.mediumImpact();
          openLink("https://linktr.ee/alexanderpiscioneri");
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateColor.resolveWith(
            (_) => currentColourScheme.primary,
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          minimumSize: WidgetStateProperty.all(Size(170, 60)),
          elevation: WidgetStateProperty.resolveWith<double>((states) {
            if (states.contains(WidgetState.pressed)) {
              return 0; // pressed (flat)
            }
            return 8; // normal
          }),
        ),
        child: Text(
          'Reach Out To Me Directly',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Text(
      //   'All feedback is always welcome.',
      //   textAlign: TextAlign.center,
      //   style: TextStyle(
      //     color: Colors.white,
      //     fontSize: 20,
      //     fontWeight: FontWeight.w400,
      //   ),
      // ),
      Divider(
        color: Theme.of(context).colorScheme.primary,
        indent: 20,
        endIndent: 20,
      ),
      
    ];
  }

  StandardSwitchListTile settingsSwitchListTile(
    String title,
    String variableName,
    bool defaultValue,
  ) {
    return StandardSwitchListTile(
      title: title,
      value: settingsBox.get(variableName, defaultValue: defaultValue),
      onChanged: (value) {
        settingsBox.put(variableName, value);
        setState(() {
          //enableNotifications = value;
        });
        if (settingsBox.get("hapticFeedback", defaultValue: true))
          HapticFeedback.mediumImpact();
      },
      activeColour: Theme.of(context).colorScheme.primary,
    );
  }
}
