import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../services/auth_service.dart';

// Menyediakan instance AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Memantau perubahan status login (apakah user login, logout, atau guest)
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Cek apakah user saat ini masuk sebagai Guest (Tamu)
final isGuestProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user?.isAnonymous ?? false;
});
