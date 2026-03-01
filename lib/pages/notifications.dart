import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
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
            onChanged: (value) async {
              final granted =
                  await NotiService().requestNotificationPermission();
              if (value == true && granted == true) {
                notificationsBox.put('enableNotifications', true);
                NotiService().showNotification(
                  title: "Dinos are green, violets are blue...",
                  body: "I just sent a notification to you!",
                );
                NotiService().refreshNotifications();
              } else if (value == true && granted == false) {
                _showNotificationPopup();
                notificationsBox.put('enableNotifications', false);
                NotiService().cancelAllNotifications();
              }
              else {
                notificationsBox.put('enableNotifications', false);
                NotiService().cancelAllNotifications();
              }
              setState(() {});
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

  void _showNotificationPopup() {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.primary,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          "'Allow Notifications' is Off",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: const Text(
          "Notifications are currently disabled for WFD2 in your settings.\n\n"
          "To receive notifications for favourite meals and special events, "
          "enable notifications in your device settings.",
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
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: const Text("Dismiss"),
          ),

          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await openAppSettings();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: const Text(
              "Open Settings",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
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
        setState(() {});
      },
      activeColour: Theme.of(context).colorScheme.primary,
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
          onChangeEnd: (value) {
            NotiService().refreshNotifications();
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
}
