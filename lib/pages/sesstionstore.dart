import 'package:get_storage/get_storage.dart';

class SessionStore {
  static final _box = GetStorage();
  static const _keyAuth = 'auth';
  static const _keyProfile = 'profile';

  static Future<void> saveAuth({
    required String role,
    required int userId,
    required String fullname,
    required String phoneId,
  }) async {
    await _box.write(_keyAuth, {
      'role': role,
      'userId': userId,
      'fullname': fullname,
      'phoneId': phoneId,
    });
  }

  static Map<String, dynamic>? getAuth() {
    final data = _box.read(_keyAuth);
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  static Future<void> clearAuth() => _box.remove(_keyAuth);
}
