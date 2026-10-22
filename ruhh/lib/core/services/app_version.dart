import 'package:package_info_plus/package_info_plus.dart';

/// Installed app version ("1.0.31+32"), sent to the server for min-version checks.
class AppVersion {
  static String? _override;
  static String? _cached;

  /// Tests can pin the version.
  static set debugOverride(String? v) => _override = v;

  static Future<String> current() async {
    if (_override != null) return _override!;
    if (_cached != null) return _cached!;
    try {
      final info = await PackageInfo.fromPlatform();
      _cached = '${info.version}+${info.buildNumber}';
    } catch (_) {
      _cached = '0.0.0';
    }
    return _cached!;
  }
}
