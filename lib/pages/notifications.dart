import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:whats_for_dino_2/services/noti_service.dart';
import 'package:whats_for_dino_2/widgets/standard_switch_list_tile.dart';

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          Divider(color: Theme.of(context).colorScheme.primary),
          StandardSwitchListTile(
            title: "Enable Notifications",
            value: notificationsBox.get(
              'enableNotifications',
              defaultValue: false,
            ),
            onChanged: (value) {
              notificationsBox.put('enableNotifications', value);
              if (value == true) {
                NotiService().showNotification(
                  title: "Dinos are green, violets are blue...",
                  body: "I just sent a notification to you!",
                );
                NotiService().refreshNotifications();
              }
              else {
                NotiService().cancelAllNotifications();
              }
              setState(() {
                
              });
            },
            activeColour: Theme.of(context).colorScheme.primary,
          ),
          Divider(color: Theme.of(context).colorScheme.primary),
          if (notificationsBox.get('enableNotifications', defaultValue: false))
            notificationsSwitchListTile("Special Events", 'notifSpecialEvents'),
          if (notificationsBox.get('enableNotifications', defaultValue: false))
            notificationsSwitchListTile(
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
        Divider(
          color: Theme.of(context).colorScheme.primary,
          indent: 20,
          endIndent: 20,
        ),
        Text(
          "Favourite Meal Notification Time",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        Slider(
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor: Theme.of(context).colorScheme.surface,
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
        Divider(
          color: Theme.of(context).colorScheme.primary,
          indent: 20,
          endIndent: 20,
        ),
      ],
    );
  }

  StandardSwitchListTile notificationsSwitchListTile(
    String title,
    String variableName,
  ) {
    return StandardSwitchListTile(
      title: title,
      value: notificationsBox.get(variableName, defaultValue: false),
      onChanged: (value) {
        notificationsBox.put(variableName, value);
        NotiService().refreshNotifications();
        setState(() {

        });
      },
      activeColour: Theme.of(context).colorScheme.primary,
    );
  }
}
