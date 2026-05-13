import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whats_for_dino_2/services/noti_service.dart';
import 'package:whats_for_dino_2/services/utils.dart';
import 'package:whats_for_dino_2/widgets/standard_switch_list_tile.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

final notificationsBox = Hive.box('notificationsBox');

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    ColorScheme currentColourScheme = Theme.of(context).colorScheme;

    if (kIsWeb) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Only available in the mobile app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Divider(
                color: Theme.of(context).colorScheme.primary,
                indent: 20,
                endIndent: 20,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                  child: SvgPicture.asset(
                    'assets/misc/iOS_QR.svg',
                    colorFilter: ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed:
                      () => openLink(
                        "https://apps.apple.com/au/app/whats-for-dino-2/id6758697602",
                      ),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateColor.resolveWith(
                      (_) => currentColourScheme.primary,
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    minimumSize: WidgetStateProperty.all(Size(170, 60)),
                    elevation: WidgetStateProperty.resolveWith<double>((
                      states,
                    ) {
                      if (states.contains(WidgetState.pressed)) {
                        return 0; // pressed (flat)
                      }
                      return 8; // normal
                    }),
                  ),
                  child: Text(
                    'iOS App Store',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Divider(
                color: Theme.of(context).colorScheme.primary,
                indent: 20,
                endIndent: 20,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                  child: SvgPicture.asset(
                    'assets/misc/Android_QR.svg',
                    colorFilter: ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed:
                      () => openLink(
                        "https://play.google.com/store/apps/details?id=com.AlexanderPiscioneri.WhatsForDino2",
                      ),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateColor.resolveWith(
                      (_) => currentColourScheme.primary,
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    minimumSize: WidgetStateProperty.all(Size(170, 60)),
                    elevation: WidgetStateProperty.resolveWith<double>((
                      states,
                    ) {
                      if (states.contains(WidgetState.pressed)) {
                        return 0; // pressed (flat)
                      }
                      return 8; // normal
                    }),
                  ),
                  child: Text(
                    'Android Google Play',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
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
                } else {
                  notificationsBox.put('enableNotifications', false);
                  NotiService().cancelAllNotifications();
                }
                setState(() {});
              },
              activeColour: Theme.of(context).colorScheme.primary,
            ),
            Divider(color: Theme.of(context).colorScheme.primary),
            if (notificationsBox.get(
              'enableNotifications',
              defaultValue: false,
            ))
              notificationsSwitchListTile(
                "Special Events",
                'notifSpecialEvents',
              ),
            if (notificationsBox.get(
              'enableNotifications',
              defaultValue: false,
            ))
              notificationsSwitchListTile("Specified Meals", 'notifMeals'),
            if (notificationsBox.get(
                  'enableNotifications',
                  defaultValue: false,
                ) &&
                notificationsBox.get('notifMeals', defaultValue: false))
              favMealReminderTime(),
          ],
        ),
      );
    }
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
      'notifMealTime',
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
          "Notification Time for Meals",
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
            notificationsBox.put('notifMealTime', value);
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
