import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Provides a stable, unique identifier for this app install.
///
/// The id is generated once (UUID v4), persisted in SharedPreferences,
/// and reused for every subsequent login/API call so the backend can
/// recognize returning devices. This works identically across
/// Android, iOS, Web, and Windows without needing extra platform
/// permissions (unlike reading native device identifiers).
class DeviceIdService {
  DeviceIdService._();

  static const _prefsKey = 'device_id';
  static String? _cachedId;

  static Future<String> getDeviceId() async {
    if (_cachedId != null) return _cachedId!;

    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_prefsKey);

    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_prefsKey, id);
    }

    _cachedId = id;
    return id;
  }
}