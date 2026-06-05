import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider untuk menyimpan & membaca path foto profil user secara global.
/// Semua layar (Home, Profile, dll) cukup watch provider ini.
class ProfileImageNotifier extends Notifier<String?> {
  static const _key = 'profile_image_path';

  @override
  String? build() {
    // Muat dari SharedPreferences saat pertama kali
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_key);
    state = path;
  }

  Future<void> setImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, path);
    state = path;
  }

  Future<void> clearImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = null;
  }
}

final profileImageProvider =
    NotifierProvider<ProfileImageNotifier, String?>(() {
  return ProfileImageNotifier();
});
