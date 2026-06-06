import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/profile_provider.dart';

import '../../services/auth_service.dart';
import '../../features/planner/data/planner_provider.dart';
import '../../features/dashboard/data/weather_provider.dart';
import '../auth/login_screen.dart';
import '../../core/database/sync_service.dart';
import '../../features/savings/data/savings_provider.dart';
import '../../features/finance/data/finance_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final authService = AuthService();
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = authService.currentUser;
    _nameController.text = user?.displayName ?? 'User';
  }

  Future<void> _pickAndCropImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        final cropper = ImageCropper();
        final croppedFile = await cropper.cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Potong Foto Profil',
              toolbarColor: AppColors.primaryPurple,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Potong Foto Profil',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
            WebUiSettings(
              context: context,
              presentStyle: WebPresentStyle.dialog,
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() => _isLoading = true);
          try {
            // Simpan gambar secara lokal saja (Offline-First)
            String finalPath = croppedFile.path;
            await ref.read(profileImageProvider.notifier).setImage(finalPath);
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final newName = _nameController.text.trim();

    // Validasi username
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username tidak boleh kosong'), backgroundColor: Colors.red),
      );
      return;
    }
    if (newName.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username minimal 3 karakter'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (newName.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username maksimal 10 karakter'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(newName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username hanya boleh huruf, angka, dan underscore (_)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = authService.currentUser;
      await user?.updateDisplayName(newName);
      await user?.reload();

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    final user = authService.currentUser;
    // Pre-fill with user's email if available
    final emailCtrl = TextEditingController(text: user?.email ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.security_rounded, color: AppColors.primaryPurple, size: 24),
            SizedBox(width: 10),
            Text('Ubah Kata Sandi', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan email akunmu. Kami akan mengirimkan link untuk mengatur ulang kata sandi.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Alamat Email',
                hintText: 'contoh@email.com',
                labelStyle: const TextStyle(color: AppColors.primaryPurple),
                prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryPurple),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryPurple),
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              await _sendPasswordReset(email);
            },
            child: Text('Kirim Link Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPasswordReset(String email) async {
    setState(() => _isLoading = true);
    try {
      await authService.sendPasswordReset(email: email);
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.mark_email_read_rounded, color: Colors.green, size: 24),
                SizedBox(width: 10),
                Text('Email Terkirim!'),
              ],
            ),
            content: Text(
              'Link untuk mengatur ulang kata sandi telah dikirim ke $email.\n\nSilakan cek kotak masuk atau folder spam kamu.',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleBackup() async {
    final syncService = ref.read(syncServiceProvider);
    if (syncService == null) return;
    
    setState(() => _isLoading = true);
    try {
      // Tambahkan timeout 7 detik
      await syncService.backupToCloud().timeout(const Duration(seconds: 7), onTimeout: () {
        throw 'Koneksi ke server terlalu lama (Timeout). Pastikan internet Anda stabil.';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup ke Cloud berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    final syncService = ref.read(syncServiceProvider);
    if (syncService == null) return;
    
    // Konfirmasi dulu
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pulihkan Data?'),
        content: const Text('Data lokal Anda saat ini akan ditimpa dengan data dari Cloud Firestore. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryPurple),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pulihkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      // Tambahkan timeout 7 detik
      await syncService.restoreFromCloud().timeout(const Duration(seconds: 7), onTimeout: () {
        throw 'Koneksi ke server terlalu lama (Timeout). Pastikan internet Anda stabil.';
      });
      
      // Refresh state semua provider agar UI terupdate
      ref.invalidate(savingsProvider);
      ref.invalidate(plannerProvider);
      ref.invalidate(financeProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pemulihan dari Cloud berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulihkan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _editCity(String currentCity) {
    final tc = TextEditingController(text: currentCity);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ubah Kota Cuaca Default'),
        content: TextField(
          controller: tc,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nama Kota...',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final newCity = tc.text.trim();
              if (newCity.isNotEmpty) {
                ref.read(weatherProvider.notifier).setCity(newCity);
              }
              Navigator.pop(ctx);
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pilih Foto Profil',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: AppColors.primaryPurple),
              title: Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickAndCropImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: AppColors.primaryPurple),
              title: Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickAndCropImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final email = user?.email ?? 'Tidak ada email';
    final currentDisplayName = user?.displayName ?? 'User';
    String displayUserName = currentDisplayName;
    if (displayUserName.length > 10) {
      displayUserName = '${displayUserName.substring(0, 8)}...';
    }
    final profileImagePath = ref.watch(profileImageProvider);

    // Ambil data statistik Weather
    final weatherState = ref.watch(weatherProvider);
    final cityPref = weatherState.data?.cityName ?? 'Jakarta';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Gradient premium
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.35, 1.0],
                colors: [
                  const Color(0xFF8B5CF6),
                  Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xFF2A2145) 
                      : const Color(0xFFD4C4FC),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // App Bar Kustom
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).cardColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'Profil Saya',
                          style: TextStyle(
                            color: Theme.of(context).cardColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 48), // Spacer penyeimbang
                      ],
                    ),
                  ),

                  // Avatar & Edit Profile Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar dengan efek glow & Border premium
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Theme.of(context).cardColor, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryPurple.withOpacity(0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: profileImagePath != null
                                        ? (kIsWeb
                                            ? NetworkImage(profileImagePath)
                                            : (profileImagePath.startsWith('https://')
                                                ? NetworkImage(profileImagePath)
                                                : FileImage(File(profileImagePath)))) as ImageProvider
                                        : const NetworkImage('https://i.pravatar.cc/150?img=11'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPurple,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  color: Theme.of(context).cardColor,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Form Edit Nama / Nama Biasa
                        if (_isEditing) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameController,
                                  autofocus: true,
                                  maxLength: 10,
                                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) {
                                    return Text(
                                      '$currentLength/10',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: currentLength > 8 ? Colors.orange : Colors.grey,
                                      ),
                                    );
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    hintText: 'min. 3 · maks. 10 karakter',
                                    labelStyle: const TextStyle(color: AppColors.primaryPurple),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    helperText: 'Huruf, angka, dan underscore (_)',
                                    helperStyle: TextStyle(fontSize: 11, color: Colors.grey),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.check_circle, color: Colors.green, size: 36),
                                onPressed: _updateProfile,
                              ),
                              IconButton(
                                icon: Icon(Icons.cancel, color: Colors.red, size: 36),
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                    _nameController.text = currentDisplayName;
                                  });
                                },
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                displayUserName,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(() => _isEditing = true),
                                child: Icon(
                                  Icons.edit_rounded,
                                  color: AppColors.primaryPurple,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Kota Cuaca Default (Editable)
                  GestureDetector(
                    onTap: () => _editCity(cityPref),
                    child: _buildStatCard(
                      icon: Icons.wb_sunny_rounded,
                      title: 'Kota Cuaca Default (Ketuk untuk ubah)',
                      value: cityPref,
                      color: Colors.orange,
                      isWide: true,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Menu Tindakan & Keamanan
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Hanya tampilkan Ubah Kata Sandi jika bukan akun Guest
                        if (user?.isAnonymous == false) ...[
                          _buildMenuTile(
                            icon: Icons.security_rounded,
                            title: 'Ubah Kata Sandi',
                            subtitle: 'Kirim link reset sandi ke email kamu',
                            onTap: _showChangePasswordDialog,
                          ),
                          const Divider(height: 1, indent: 60),
                        ],
                        _buildMenuTile(
                          icon: Icons.info_outline_rounded,
                          title: 'Tentang SaveStep',
                          subtitle: 'Versi Aplikasi 1.0.0',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryPurple.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.info_outline_rounded, color: AppColors.primaryPurple, size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text('Tentang SaveStep', style: TextStyle(fontSize: 16)),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SaveStep adalah aplikasi manajemen keuangan pribadi yang membantu kamu mencapai target tabungan, mencatat pengeluaran, merencanakan kegiatan harian, serta mendapatkan pengingat cerdas — semua dalam satu genggaman.',
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Divider(color: Colors.grey.shade200),
                                    const SizedBox(height: 8),
                                    _aboutRow(Icons.tag_rounded, 'Versi', '1.0.0'),
                                    const SizedBox(height: 6),
                                    _aboutRow(Icons.devices_rounded, 'Platform', 'Android & Web'),
                                    const SizedBox(height: 6),
                                    _aboutRow(Icons.code_rounded, 'Teknologi', 'Flutter + Firebase'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text('Tutup', style: TextStyle(color: AppColors.primaryPurple)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Sinkronisasi Cloud (Bukan Guest) ───────────────────
                  if (user?.isAnonymous == false) ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                Icon(Icons.cloud_sync_rounded, color: AppColors.primaryPurple, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Sinkronisasi Cloud',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildMenuTile(
                            icon: Icons.cloud_upload_rounded,
                            title: 'Backup ke Cloud',
                            subtitle: 'Simpan data lokal Anda ke server secara aman.',
                            onTap: _handleBackup,
                          ),
                          const Divider(height: 1, indent: 60),
                          _buildMenuTile(
                            icon: Icons.cloud_download_rounded,
                            title: 'Pulihkan dari Cloud',
                            subtitle: 'Tarik data dari server untuk memulihkan perangkat ini.',
                            onTap: _handleRestore,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Tombol Hapus Akun Estetik
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.delete_forever_rounded, color: Colors.red),
                      label: Text(
                        'Hapus Akun',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: Colors.red.withOpacity(0.04),
                      ),
                      onPressed: () async {
                        // Dialog Konfirmasi Hapus Akun
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Konfirmasi Hapus Akun'),
                            content: Text('Apakah Anda yakin ingin MENGHAPUS akun SaveStep Anda? Tindakan ini tidak dapat dibatalkan dan semua data Anda akan hilang.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Batal'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('Hapus Akun'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            await authService.deleteAccount();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 48), // Padding bawah
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.25),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryPurple),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isWide = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                Text(
                  value,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryPurple.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryPurple, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _aboutRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color)),
      ],
    );
  }
}
