import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/user_profile.dart';

class LocalStorageService {
  static const String _keyCachedProfile = 'cached_user_profile';

  static Future<void> saveCachedProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCachedProfile, profile.toJson());
  }

  static Future<UserProfile?> getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyCachedProfile);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        return UserProfile.fromJson(jsonStr);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Future<void> clearCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCachedProfile);
  }
}
