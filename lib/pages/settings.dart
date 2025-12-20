import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
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
            title: "Show Times On Menu",
            value: settingsBox.get("showTimesOnMenu", defaultValue: true),
            onChanged: (value) {
              settingsBox.put("showTimesOnMenu", value);
              setState(() {
                
              });
            },
            activeColour: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  StandardSwitchListTile settingsSwitchListTile(
    String title,
    String variableName,
  ) {
    return StandardSwitchListTile(
      title: title,
      value: settingsBox.get(variableName, defaultValue: false),
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
