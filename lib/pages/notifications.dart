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
          Divider(color: mainColour),
          standardSwitchListTile("Enable Notifications", 'enableNotifications'),
          Divider(color: mainColour),
          if (notificationsBox.get('enableNotifications', defaultValue: false))
            standardSwitchListTile(
              "Different Dino Times",
              'notifDifferentDinoTimes',
            ),
          if (notificationsBox.get('enableNotifications', defaultValue: false))
            standardSwitchListTile("Special Events", 'notifSpecialEvent'),
          if (notificationsBox.get('enableNotifications', defaultValue: false))
            standardSwitchListTile(
              "Favourite Menu Items",
              'notifFavouriteMeals',
            ),
          if (notificationsBox.get(
                'enableNotifications',
                defaultValue: false,
              ) &&
              notificationsBox.get('notifFavouriteMeals', defaultValue: false))
            favMealReminderTime(),
        ],
      ),
    );
  }

  Widget favMealReminderTime() {
    double currentValue = notificationsBox.get(
      'notifFavMealTime',
      defaultValue: 0.0,
    );

    String sliderLabel;
    if (currentValue == 0) {
      sliderLabel = "When Dino opens";
    } else if (currentValue > 0) {
      sliderLabel = '${currentValue.toInt()} minutes AFTER Dino opens';
    } else {
      sliderLabel = '${-currentValue.toInt()} minutes BEFORE Dino opens';
    }

    return Column(
      children: [
        Divider(color: mainColour, indent: 20, endIndent: 20,),
        Text(
          "Favourite Meal Notification Time",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        Slider(
          activeColor: mainColour,
          min: -90,
          value: currentValue,
          max: 90,
          divisions: 6,
          onChanged: (value) {
            notificationsBox.put('notifFavMealTime', value);
            setState(() {});
          },
        ),

        Padding(
          padding: const EdgeInsets.only(top: 0),
          child: Text(
            sliderLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        Divider(color: mainColour, indent: 20, endIndent: 20,),
      ],
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
