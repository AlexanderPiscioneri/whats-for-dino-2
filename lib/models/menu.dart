class Menu {
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final List<Week> weeks;
  final List<DayMenuException> exceptions;

  Menu({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.weeks,
    required this.exceptions,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      name: json['name'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      weeks:
          (json['weeks'] as List<dynamic>)
              .map((w) => Week.fromJson(w))
              .toList(),
      exceptions:
          (json['exceptions'] as List<dynamic>? ?? [])
              .map((e) => DayMenuException.fromJson(e))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "startDate": startDate.toIso8601String(),
      "endDate": endDate.toIso8601String(),
      "weeks": weeks.map((w) => w.toJson()).toList(),
      "exceptions": exceptions.map((e) => e.toJson()).toList(),
    };
  }
}

class DayMenuException {
  final String dayDate; // dd/MM/yyyy
  final String meal; // "breakfast" | "brunch" | "lunch" | "dinner"
  final List<String> mealItems;

  final String notifTitle;
  final String notifBody;

  DayMenuException({
    required this.dayDate,
    required this.meal,
    required this.mealItems,
    required this.notifTitle,
    required this.notifBody,
  });

  factory DayMenuException.fromJson(Map<String, dynamic> json) {
    return DayMenuException(
      dayDate: json['dayDate'] ?? '',
      meal: json['meal'] ?? '',
      mealItems:
          (json['mealItems'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
      notifTitle: json['notifTitle'] ?? '',
      notifBody: json['notifBody'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "dayDate": dayDate,
      "meal": meal,
      "mealItems": mealItems,
      "notifTitle": notifTitle,
      "notifBody": notifBody,
    };
  }

  /// Apply this exception to a DayMenu
  void applyTo(DayMenu dayMenu) {
    switch (meal.toLowerCase()) {
      case 'breakfast':
        dayMenu.breakfast = [...mealItems];
        break;

      case 'brunch':
        dayMenu.brunch = [...mealItems];
        break;

      case 'lunch':
        dayMenu.lunch = [...mealItems];
        break;

      case 'dinner':
        dayMenu.dinner = [...mealItems];
        break;

      case 'early dinner':
        dayMenu.dinner = [...mealItems];
        dayMenu.hasEarlyDinner = true;
        break;
    }
  }
}

class Week {
  final int weekNumber;
  final List<DayMenu> days;

  Week({required this.weekNumber, required this.days});

  factory Week.fromJson(Map<String, dynamic> json) {
    return Week(
      weekNumber: json['weekNumber'],
      days:
          (json['days'] as List<dynamic>)
              .map((d) => DayMenu.fromJson(d))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "weekNumber": weekNumber,
      "days": days.map((d) => d.toJson()).toList(),
    };
  }
}

class DayMenu {
  String dayName;
  String dayDate = "";
  List<String> breakfast;
  List<String>? brunch; // empty Mon–Fri
  List<String> lunch;
  List<String> dinner;
  bool hasEarlyDinner;

  DayMenu({
    required this.dayName,
    required this.dayDate,
    required this.breakfast,
    this.brunch,
    required this.lunch,
    required this.dinner,
    this.hasEarlyDinner = false, // default to false
  });

  DayMenu copy() {
    return DayMenu(
      dayName: dayName,
      dayDate: dayDate,
      breakfast: [...breakfast],
      brunch: brunch == null ? null : [...brunch!],
      lunch: [...lunch],
      dinner: [...dinner],
      hasEarlyDinner: hasEarlyDinner, // <-- copy the flag
    );
  }

  factory DayMenu.fromJson(Map<String, dynamic> json) {
    return DayMenu(
      dayName: json['dayName'] ?? '',
      dayDate: json['dayDate'] ?? '',
      breakfast: _parseMeal(json['breakfast']),
      brunch:
          json.containsKey("brunch") && json["brunch"] != null
              ? _parseMeal(json['brunch'])
              : null,
      lunch: _parseMeal(json['lunch']),
      dinner: _parseMeal(json['dinner']),
      hasEarlyDinner: json['hasEarlyDinner'] ?? false, // <-- parse from JSON
    );
  }

Map<String, dynamic> toJson() {
  return {
    "dayName": dayName,
    "dayDate": dayDate,
    "breakfast": breakfast,
    if (brunch != null) "brunch": brunch,
    "lunch": lunch,
    "dinner": dinner,
    "hasEarlyDinner": hasEarlyDinner,
  };
}

static List<String> _parseMeal(dynamic data) {
  if (data == null) return [];
  return (data as List<dynamic>)
      .map((item) => item.toString())
      .toList();
}

}

class MenuItem {
  final String name;

  MenuItem({required this.name});

  MenuItem copy() => MenuItem(name: name);

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {"name": name};
  }
}

class Meal {
  final String name;
  final double rating;

  Meal({required this.name, required this.rating});

  Meal copy() => Meal(name: name, rating: rating);

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      name: json['name'] ?? '',
      rating: (json['rating'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {"name": name, "rating": rating};
  }
}