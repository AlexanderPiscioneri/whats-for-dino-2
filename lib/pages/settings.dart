import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:whats_for_dino_2/theme/theme_provider.dart';
import 'package:whats_for_dino_2/widgets/standard_switch_list_tile.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

final settingsBox = Hive.box('settingsBox');

class _SettingsPageState extends State<SettingsPage> {
  String _appVersionText = "";

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
                },
                activeColour: Theme.of(context).colorScheme.primary,
              ),
              StandardSwitchListTile(
                title: "Show Meal Times",
                value: settingsBox.get("showTimesOnMenu", defaultValue: true),
                onChanged: (value) {
                  settingsBox.put("showTimesOnMenu", value);
                  setState(() {
                    
                  });
                },
                activeColour: Theme.of(context).colorScheme.primary,
              ),
              if (!kIsWeb) StandardSwitchListTile(
                title: "Show Notification Buttons",
                value: settingsBox.get("showNotifButtons", defaultValue: true),
                onChanged: (value) {
                  settingsBox.put("showNotifButtons", value);
                  setState(() {});
                },
                activeColour: Theme.of(context).colorScheme.primary,
              ),
              StandardSwitchListTile(
                title: "Center Meal Text",
                value: settingsBox.get("centerMealText", defaultValue: false),
                onChanged: (value) {
                  settingsBox.put("centerMealText", value);
                  setState(() {});
                },
                activeColour: Theme.of(context).colorScheme.primary,
              ),
              StandardSwitchListTile(
                title: "Show Ratings",
                value: settingsBox.get("showRatings", defaultValue: true),
                onChanged: (value) {
                  settingsBox.put("showRatings", value);
                  setState(() {});
                },
                activeColour: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _appVersionText,
              style: TextStyle(
                color: Colors.white
              ),
            ),
          )
        ],
      ),
    );
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
      },
      activeColour: Theme.of(context).colorScheme.primary,
    );
  }
}
