import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User yang sedang login
  User? get currentUser => _auth.currentUser;

  // Stream untuk memantau perubahan status auth
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // REGISTER - Buat akun baru dengan email, password, dan username
  Future<UserCredential> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Simpan username sebagai displayName
      await credential.user?.updateDisplayName(username.trim());

      // Kirim email verifikasi ke alamat email user
      await credential.user?.sendEmailVerification();

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e.code);
    }
  }

  // LOGIN - Masuk dengan email dan password
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Cek apakah email sudah diverifikasi
      if (credential.user?.emailVerified == false) {
        // Sign out dulu supaya user tidak bisa masuk
        await _auth.signOut();
        throw 'Email belum diverifikasi. Cek inbox email kamu dan klik link verifikasi.';
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e.code);
    }
  }

  // KIRIM ULANG EMAIL VERIFIKASI
  Future<void> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e.code);
    }
  }

  // LOGOUT
  Future<void> logout() async {
    final user = _auth.currentUser;
    final isAnonymous = user?.isAnonymous ?? false;

    // Jika user adalah guest (anon), kita bisa sekalian menghapus akun sementara ini
    // agar tidak menjadi sampah di Firebase (opsional).
    if (isAnonymous) {
      try {
        await user?.delete();
      } catch (_) {}
    }

    await _auth.signOut();
    
    // Hanya disconnect GoogleSignIn jika bukan anonymous
    if (!isAnonymous) {
      try {
        await GoogleSignIn.instance.disconnect();
      } catch (_) {}
    }
  }

  // HAPUS AKUN
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Tidak ada user yang sedang login.';

      // Hapus akun Firebase Auth
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'Demi keamanan, silakan logout dan login kembali sebelum menghapus akun.';
      }
      throw _handleAuthError(e.code);
    }
  }

  // LOGIN SEBAGAI GUEST (ANONYMOUS)
  Future<UserCredential> signInAsGuest() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e.code);
    }
  }

  // LOGIN DENGAN GOOGLE
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Inisialisasi GoogleSignIn (wajib di v7.x)
      await GoogleSignIn.instance.initialize();

      // 2. Trigger flow autentikasi Google
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      // 3. Dapatkan detail autentikasi (idToken) dari GoogleSignInAccount
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      // 4. Buat credential Firebase menggunakan idToken
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 5. Login ke Firebase dengan credential tersebut
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e.code);
    } catch (e) {
      if (e.toString().contains('canceled') || e.toString().contains('cancelled')) {
        throw 'Login dengan Google dibatalkan.';
      }
      throw 'Terjadi kesalahan saat menghubungkan ke Google: $e';
    }
  }

  // FORGOT PASSWORD - Kirim email reset password
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e.code);
    }
  }

  // Convert error code Firebase ke pesan yang user-friendly
  String _handleAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email tidak terdaftar. Silakan daftar terlebih dahulu.';
      case 'wrong-password':
        return 'Password salah. Silakan coba lagi.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan login.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah. Minimal 6 karakter.';
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah. Periksa jaringan kamu.';
      default:
        return 'Terjadi kesalahan: $code';
    }
  }
}
