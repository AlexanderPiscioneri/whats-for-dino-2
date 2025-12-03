import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
          notificationsSwitchListTile(
            "Enable Notifications",
            'enableNotifications',
          ),
          Divider(color: Theme.of(context).colorScheme.primary),
          if (notificationsBox.get('enableNotifications', defaultValue: false))
            notificationsSwitchListTile(
              "Different Dino Times",
              'notifDifferentDinoTimes',
            ),
          if (notificationsBox.get('enableNotifications', defaultValue: false))
            notificationsSwitchListTile("Special Events", 'notifSpecialEvent'),
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
        setState(() {
          //enableNotifications = value;
        });
      },
      activeColour: Theme.of(context).colorScheme.primary,
    );

    //   return SwitchListTile(
    //     splashRadius: 0,
    //     title: Text(
    //       title,
    //       style: TextStyle(
    //         fontSize: 22,
    //         fontWeight: FontWeight.w400,
    //         color: Colors.white,
    //       ),
    //     ),
    //     value: notificationsBox.get(variableName, defaultValue: false),
    //     activeColor: Theme.of(context).colorScheme.primary,
    //     trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    //     inactiveTrackColor: Colors.grey[700],
    //     thumbColor: WidgetStateProperty.all<Color>(Colors.white),
    //     inactiveThumbColor: Colors.white,
    //     onChanged: (value) {
    //       notificationsBox.put(variableName, value);
    //       setState(() {
    //         //enableNotifications = value;
    //       });
    //     },
    //   );
  }
}
