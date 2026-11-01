import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SystemInfo {
  const SystemInfo({
    required this.applicationVersion,
    required this.flutterVersion,
    required this.dartVersion,
    required this.operatingSystem,
    required this.operatingSystemVersion,
  });

  final String applicationVersion;
  final String flutterVersion;
  final String dartVersion;
  final String operatingSystem;
  final String operatingSystemVersion;
}

class SystemInfoService {
  const SystemInfoService();

  Future<SystemInfo> load() async {
    final package = await PackageInfo.fromPlatform();
    final device = await DeviceInfoPlugin().deviceInfo;
    final data = device.data;
    return SystemInfo(
      applicationVersion: '${package.version}+${package.buildNumber}',
      flutterVersion: FlutterVersion.version ?? 'Not reported',
      dartVersion: FlutterVersion.dartVersion ?? 'Not reported',
      operatingSystem: kIsWeb ? 'Web' : defaultTargetPlatform.name,
      operatingSystemVersion: _firstValue(data, const [
        'prettyName',
        'displayVersion',
        'version',
        'systemVersion',
        'version.release',
        'browserName',
        'userAgent',
      ]),
    );
  }

  String _firstValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return 'Not reported';
  }
}
