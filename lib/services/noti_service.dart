import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:whats_for_dino_2/models/menu.dart';
import 'package:whats_for_dino_2/pages/favourites.dart';
import 'package:whats_for_dino_2/services/menu_cache.dart';

class NotiService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initNotification() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    // init timezone handling
    tz.initializeTimeZones();
    final TimezoneInfo tzInfo = await FlutterTimezone.getLocalTimezone();
    final String currentTimeZone = tzInfo.identifier;
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    // Android initialization
    const initSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    await notificationsPlugin.initialize(initSettings);

    // Android 13+ permission request
    if (!kIsWeb && Platform.isAndroid) {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    }

    _isInitialized = true;
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel_id',
        'Daily Notifications',
        channelDescription: 'Daily Notification Channel',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    if (!_isInitialized) await initNotification();
    await notificationsPlugin.show(id, title, body, notificationDetails());
  }

  Future<void> scheduleNotification({
    int id = 1,
    required String title,
    required String body,
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
  }) async {
    // Get the current date/time in device's local timezone
    // final now = tz.TZDateTime.now(tz.local);

    // Create a date/time for today at the specified hour/min
    var scheduledDate = tz.TZDateTime(tz.local, year, month, day, hour, minute);

    // Schedule the notification
    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails(),

      // Android specific: Allow notification while device is in low-power mode
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,

      // Make notification repeat DAILY at same time
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
  }

  Future<void> scheduleFavouritesNotifications() async {
    // debugPrint("scheduling notifications");

    if (!_isInitialized) await initNotification();

    final dayMenus = getDayMenuCache();
    final foodItems = getFoodItemsCache();
    final notificationsBox = Hive.box('notificationsBox');

    int counter = 0;

    for (final foodItem in foodItems.where((f) => f.isFavourite)) {
      for (final dayMenu in dayMenus) {
        final DateTime dayDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(dayMenu.dayDate);

        final meals = {
          'Breakfast': dayMenu.breakfast,
          if (dayMenu.brunch != null) 'Brunch': dayMenu.brunch!,
          'Lunch': dayMenu.lunch,
          'Dinner': dayMenu.dinner,
          'Early Dinner': dayMenu.dinner,
        };

        for (final entry in meals.entries) {
          final mealType = entry.key;
          final mealList = entry.value;

          if (!mealList.any((meal) => meal.name == foodItem.name)) continue;

          final scheduledDate = DateTime(
                dayDate.year,
                dayDate.month,
                dayDate.day,
              )
              .add(mealToStartOffset(mealType))
              .add(
                Duration(
                  minutes:
                      ((notificationsBox.get(
                                'notifFavMealTime',
                                defaultValue: 0.0,
                              )
                              as double)
                          .round()),
                ),
              );

          await scheduleNotification(
            id:
                foodItem.hashCode ^
                dayMenu.dayDate.hashCode ^
                mealType.hashCode,
            title: "Favourite Meal",
            body: "${foodItem.name} for $mealType!",
            year: scheduledDate.year,
            month: scheduledDate.month,
            day: scheduledDate.day,
            hour: scheduledDate.hour,
            minute: scheduledDate.minute,
          );

          if (++counter % 10 == 0) {
            await Future.delayed(Duration.zero);
          }
        }
      }
    }

    // debugPrint("done");
  }

  Future<void> scheduleSpecialEventsNotifications() async {
    // debugPrint("scheduling special event notifications");

    if (!_isInitialized) await initNotification();

    final dayMenus = getDayMenuCache();
    // final notificationsBox = Hive.box('notificationsBox');

    final Map<String, DayMenu> menusByDate = {
      for (final d in dayMenus) d.dayDate: d,
    };

    final menus = MenuCache.menus;

    int counter = 0;

    for (final menu in menus) {
      for (final exception in menu.exceptions) {
        final dayMenu = menusByDate[exception.dayDate];
        if (dayMenu == null) continue;

        final DateTime dayDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(exception.dayDate);

        final mealType = _normaliseMealName(exception.meal);
        final scheduledDate = DateTime(
          dayDate.year,
          dayDate.month,
          dayDate.day,
        ).add(mealToStartOffset(mealType)).add(Duration(minutes: (-30)));

        await scheduleNotification(
          id:
              exception.hashCode ^
              exception.dayDate.hashCode ^
              exception.meal.hashCode,
          title: exception.notifTitle,
          body: exception.notifBody,
          year: scheduledDate.year,
          month: scheduledDate.month,
          day: scheduledDate.day,
          hour: scheduledDate.hour,
          minute: scheduledDate.minute,
        );

        if (++counter % 10 == 0) {
          await Future.delayed(Duration.zero);
        }
      }
    }

    // debugPrint("done");
  }

  Future<void> refreshNotifications() async {
    final notificationsBox = Hive.box('notificationsBox');

    if (!_isInitialized) await initNotification();

    await cancelAllNotifications();
    await Future.delayed(Duration.zero);

    if (notificationsBox.get('notifSpecialEvents', defaultValue: false)) {
      await scheduleSpecialEventsNotifications();
    }

    await Future.delayed(Duration.zero);

    if (notificationsBox.get('notifFavouriteMeals', defaultValue: false)) {
      await scheduleFavouritesNotifications();
    }
  }
}

Duration mealToStartOffset(String meal) {
  switch (meal) {
    case "Breakfast":
      return Duration(hours: 7, minutes: 30);
    case "Brunch":
      return Duration(hours: 10);
    case "Lunch":
      return Duration(hours: 12);
    case "Dinner":
      return Duration(hours: 17);
    case "Early Dinner":
      return Duration(hours: 16, minutes: 30);
    default:
      return Duration(hours: 0);
  }
}

String _normaliseMealName(String meal) {
  switch (meal.toLowerCase()) {
    case 'breakfast':
      return 'Breakfast';
    case 'brunch':
      return 'Brunch';
    case 'lunch':
      return 'Lunch';
    case 'dinner':
      return 'Dinner';
    case 'early dinner':
      return 'Early Dinner';
    default:
      return meal;
  }
}
