import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/auth_provider.dart';
import 'database_provider.dart';
import 'firestore_service.dart';
import 'local_database_service.dart';

class SyncService {
  final LocalDatabaseService localDb;
  final FirestoreService firestoreDb;
  final SharedPreferences prefs;
  final String uid;

  SyncService(this.localDb, this.firestoreDb, this.prefs, this.uid);

  static const _collections = ['savings_goals', 'transactions'];

  // Mengirim semua data lokal ke Cloud Firestore (Backup)
  Future<void> backupToCloud() async {
    for (final collection in _collections) {
      final localData = await localDb.readAll(collection);
      final cloudData = await firestoreDb.readAll(collection);
      
      final localIds = localData.map((e) => e['id']).toSet();
      
      // 1. Hapus data di Cloud yang tidak ada di lokal (Mirroring)
      for (final cloudItem in cloudData) {
        final cloudId = cloudItem['id'];
        if (cloudId != null && !localIds.contains(cloudId)) {
          await firestoreDb.delete(collection, cloudId);
        }
      }

      // 2. Upload data lokal ke Cloud
      for (final item in localData) {
        final id = item['id'];
        if (id != null) {
          // Kecualikan imagePath agar tidak ditimpa/diupload ke cloud
          final Map<String, dynamic> cloudItem = Map.from(item);
          cloudItem.remove('imagePath');
          await firestoreDb.create(collection, id, cloudItem);
        }
      }
    }
    
    // 2. Backup Catatan (Planner) dari SharedPreferences
    final notesKey = 'planner_${uid}_notes';
    final catKey = 'planner_${uid}_categories';
    final notesData = prefs.getString(notesKey);
    final catData = prefs.getString(catKey);
    
    await firestoreDb.create('shared_prefs', 'planner', {
      'notes': notesData ?? '[]',
      'categories': catData ?? '[]'
    });
  }

  // Mengambil semua data dari Cloud Firestore ke Lokal (Restore)
  Future<void> restoreFromCloud() async {
    // 1. Restore koleksi database (Tabungan & Keuangan)
    for (final collection in _collections) {
      final cloudData = await firestoreDb.readAll(collection);
      final localData = await localDb.readAll(collection);
      
      final cloudIds = cloudData.map((e) => e['id']).toSet();
      
      // 1. Hapus data lokal yang tidak ada di Cloud (Mirroring)
      for (final localItem in localData) {
        final localId = localItem['id'];
        if (localId != null && !cloudIds.contains(localId)) {
          await localDb.delete(collection, localId);
        }
      }

      // 2. Download data dari Cloud ke lokal
      for (final item in cloudData) {
        final id = item['id'];
        if (id != null) {
          // Pertahankan imagePath lokal jika ada, jangan ditimpa dari cloud
          final existingLocal = await localDb.read(collection, id);
          if (existingLocal != null && existingLocal['imagePath'] != null) {
            item['imagePath'] = existingLocal['imagePath'];
          }
          await localDb.delete(collection, id);
          await localDb.create(collection, id, item);
        }
      }
    }
    
    // 2. Restore Catatan dari SharedPreferences
    final plannerData = await firestoreDb.read('shared_prefs', 'planner');
    if (plannerData != null) {
      final notesKey = 'planner_${uid}_notes';
      final catKey = 'planner_${uid}_categories';
      if (plannerData['notes'] != null) {
        await prefs.setString(notesKey, plannerData['notes']);
      }
      if (plannerData['categories'] != null) {
        await prefs.setString(catKey, plannerData['categories']);
      }
    }
  }
}

// Provider untuk SyncService. Hanya aktif jika user login selain Guest.
final syncServiceProvider = Provider<SyncService?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null || user.isAnonymous) return null;

  final prefs = ref.watch(sharedPreferencesProvider);
  final localDb = LocalDatabaseService(prefs, uid: user.uid);
  final firestoreDb = FirestoreService(user.uid);

  return SyncService(localDb, firestoreDb, prefs, user.uid);
});
