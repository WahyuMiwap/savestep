import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_provider.dart';

/// Placeholder StorageService — Firebase Storage tidak digunakan.
/// Gambar profil dan tabungan disimpan murni secara lokal (Offline-First).
class StorageService {
  final String uid;
  StorageService(this.uid);
}

/// Provider StorageService — hanya tidak-null jika user login dengan akun nyata.
final storageServiceProvider = Provider<StorageService?>((ref) {
  final userAsync = ref.watch(authStateProvider);
  final user = userAsync.value;

  if (user == null || user.isAnonymous) return null;

  return StorageService(user.uid);
});
