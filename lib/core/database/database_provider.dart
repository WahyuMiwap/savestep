import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/auth_provider.dart';
import 'database_service.dart';
import 'firestore_service.dart';
import 'local_database_service.dart';

// Provider untuk SharedPreferences (akan diinisialisasi di main.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences belum di-override di main.dart');
});

// Provider utama penyedia layanan Database
// Karena Firebase Firestore belum dikonfigurasi penuh secara server, 
// kita paksa aplikasi menjadi 100% Offline-First menggunakan LocalDatabaseService (SQLite)
// agar tidak terjadi error / data hilang saat menggunakan akun Google.
final databaseProvider = Provider<DatabaseService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final user = ref.watch(authStateProvider).value;
  
  final uid = user?.uid ?? 'guest';
  return LocalDatabaseService(prefs, uid: uid);
});
