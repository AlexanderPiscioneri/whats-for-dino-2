import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:whats_for_dino_2/main.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

final notificationsBox = Hive.box('notificationsBox');

class _NotificationsPageState extends State<NotificationsPage> {
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColour,
      body: Column(
        children: [
          Divider( color: mainColour,),
          standardSwitchListTile("Enable Notifications", 'enableNotifications'),
          Divider( color: mainColour,),
          if (notificationsBox.get('enableNotifications', defaultValue: false)) standardSwitchListTile("Different Dino Times", 'notifDifferentDinoTimes'),
          if (notificationsBox.get('enableNotifications', defaultValue: false)) standardSwitchListTile("Special Events", 'notifSpecialEvent'),
          if (notificationsBox.get('enableNotifications', defaultValue: false)) standardSwitchListTile("Favourite Meals", 'notifFavouriteMeals'),
          if (notificationsBox.get('enableNotifications', defaultValue: false) 
          && notificationsBox.get('notifFavouriteMeals', defaultValue: false)) favMealReminderTime(),
        ],
      ),
    );
  }

  Slider favMealReminderTime() {
    return Slider(
      value: 0,
      onChanged: (value) {

      },
    );
  }

  SwitchListTile standardSwitchListTile(String title, String variableName) {
    return SwitchListTile(
          splashRadius: 0,
          title: Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
          value: notificationsBox.get(variableName, defaultValue: false),
          activeColor: mainColour,
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          inactiveTrackColor: Colors.grey[700],
          thumbColor: WidgetStateProperty.all<Color>(Colors.white),
          inactiveThumbColor: Colors.white,
          onChanged: (value) {
            notificationsBox.put(variableName, value);
            setState(() {
              //enableNotifications = value;
            });
          },
        );
  }
}