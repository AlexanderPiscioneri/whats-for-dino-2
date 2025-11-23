class Menu {
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final List<Week> weeks;

  Menu({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.weeks,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "startDate": startDate.toIso8601String(),
      "endDate": endDate.toIso8601String(),
      "weeks": weeks.map((w) => w.toJson()).toList(),
    };
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
  final String dayName;
  final List<MealItem> breakfast;
  final List<MealItem>? brunch; // empty Mon–Fri
  final List<MealItem> lunch;
  final List<MealItem> dinner;

  DayMenu({
    required this.dayName,
    required this.breakfast,
    this.brunch,
    required this.lunch,
    required this.dinner,
  });

  factory DayMenu.fromJson(Map<String, dynamic> json) {
    return DayMenu(
      dayName: json['dayName'] ?? '',
      breakfast: _parseMeal(json['breakfast']),

      // Only parse brunch if key exists
      brunch:
          json.containsKey("brunch") && json["brunch"] != null
              ? _parseMeal(json['brunch'])
              : null,

      lunch: _parseMeal(json['lunch']),
      dinner: _parseMeal(json['dinner']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "dayName": dayName,
      "breakfast": breakfast.map((m) => m.toJson()).toList(),
      if (brunch != null) "brunch": brunch!.map((m) => m.toJson()).toList(),
      "lunch": lunch.map((m) => m.toJson()).toList(),
      "dinner": dinner.map((m) => m.toJson()).toList(),
    };
  }

  static List<MealItem> _parseMeal(dynamic data) {
    if (data == null) return [];
    return (data as List<dynamic>)
        .map((item) => MealItem.fromJson(item))
        .toList();
  }
}

class MealItem {
  final String name;
  final double rating;

  MealItem({required this.name, required this.rating});

  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      name: json['name'] ?? '',
      rating: (json['rating'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {"name": name, "rating": rating};
  }
}
