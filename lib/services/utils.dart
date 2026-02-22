import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

Future<String> getInstallId() async {
  final prefs = await SharedPreferences.getInstance();
  var id = prefs.getString('install_id');

  if (id == null) {
    id = const Uuid().v4();
    await prefs.setString('install_id', id);
  }

  return id;
}

Map<String, dynamic>? _cachedDeviceInfo;

Future<Map<String, dynamic>> getDeviceInfo() async {
  if (_cachedDeviceInfo != null) return _cachedDeviceInfo!;

  final plugin = DeviceInfoPlugin();

  if (kIsWeb) {
    _cachedDeviceInfo = {
      'platform': 'web',
    };
  } else if (UniversalPlatform.isAndroid) {
    final info = await plugin.androidInfo;
    _cachedDeviceInfo = {
      'platform': 'android',
      'model': info.model,
      'manufacturer': info.manufacturer,
      'sdk': info.version.sdkInt,
    };
  } else if (UniversalPlatform.isIOS) {
    final info = await plugin.iosInfo;
    _cachedDeviceInfo = {
      'platform': 'ios',
      'model': info.utsname.machine,
      'systemVersion': info.systemVersion,
    };
  } else {
    _cachedDeviceInfo = {
      'platform': 'unknown',
    };
  }

  return _cachedDeviceInfo!;
}

  Future<void> openLink(url) async {
    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $uri');
    }
  }