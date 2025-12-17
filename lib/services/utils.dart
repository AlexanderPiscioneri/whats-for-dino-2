import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

Future<String> getInstallId() async {
  final prefs = await SharedPreferences.getInstance();
  var id = prefs.getString('install_id');

  if (id == null) {
    id = const Uuid().v4();
    await prefs.setString('install_id', id);
  }

  return id;
}