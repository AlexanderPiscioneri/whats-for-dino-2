import 'package:intl/intl.dart';

class ServerMessage {
  final String id;
  final String title;
  final String text;
  final String type;
  final bool showOnce;
  final String buttonText;
  final Map<String, dynamic> conditions;

  ServerMessage({
    required this.id,
    required this.title,
    required this.text,
    required this.type,
    required this.showOnce,
    required this.buttonText,
    required this.conditions,
  });

  factory ServerMessage.fromJson(Map<String, dynamic> json) {
    return ServerMessage(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Notice',
      text: json['text'] ?? '',
      type: json['type'] ?? 'info',
      showOnce: json['showOnce'] ?? false,
      buttonText: json['buttonText'] ?? 'OK',
      conditions: Map<String, dynamic>.from(json['conditions'] ?? {}),
    );
  }

  bool isActive(DateTime now, String currentVersion) {
    if (conditions.isEmpty) return true;

    final dateFrom = conditions['dateFrom'] as String?;
    final dateTo = conditions['dateTo'] as String?;
    if (dateFrom != null || dateTo != null) {
      final fmt = DateFormat('dd/MM/yyyy');
      if (dateFrom != null) {
        final from = fmt.parse(dateFrom);
        if (now.isBefore(from)) return false;
      }
      if (dateTo != null) {
        final to = fmt.parse(dateTo).add(const Duration(days: 1));
        if (now.isAfter(to)) return false;
      }
    }

    final maxVersion = conditions['maxVersion'] as String?;
    final minVersion = conditions['minVersion'] as String?;
    if (maxVersion != null && _compareVersions(currentVersion, maxVersion) > 0)
      return false;
    if (minVersion != null && _compareVersions(currentVersion, minVersion) < 0)
      return false;

    return true;
  }

  int _compareVersions(String a, String b) {
    final aParts = a.split('.').map(int.parse).toList();
    final bParts = b.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      final diff =
          (aParts.elementAtOrNull(i) ?? 0) - (bParts.elementAtOrNull(i) ?? 0);
      if (diff != 0) return diff;
    }
    return 0;
  }
}
