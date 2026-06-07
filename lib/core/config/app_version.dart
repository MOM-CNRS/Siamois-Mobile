import 'package:package_info_plus/package_info_plus.dart';

/// Version affichée dans l’UI (lue depuis `pubspec.yaml` au démarrage).
abstract final class AppVersion {
  static String _label = '';

  static String get label => _label;

  static Future<void> load() async {
    final info = await PackageInfo.fromPlatform();
    _label = 'v${info.version}';
  }
}
