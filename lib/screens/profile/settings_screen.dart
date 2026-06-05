import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final authService = AuthService();
  bool _isLoading = false;

  Future<void> _deleteAccount() async {
    // Langkah 1: Konfirmasi pertama
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Hapus Akun?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Tindakan ini TIDAK DAPAT DIBATALKAN.\n\n'
          'Seluruh data akun kamu termasuk catatan dan riwayat aktivitas akan dihapus secara permanen.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Lanjutkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await authService.deleteAccount();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Header gradient
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8B5CF6), Color(0xFFD4C4FC)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // AppBar Kustom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).cardColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Pengaturan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).cardColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Bagian Notifikasi ─────────────────────────────
                        _buildSectionHeader('Notifikasi'),
                        _buildSettingsCard(children: [
                          _buildSwitchTile(
                            icon: Icons.notifications_outlined,
                            title: 'Notifikasi Planner',
                            subtitle: 'Terima pengingat dari catatan & tugas',
                            value: true, // TODO: sambungkan ke SharedPreferences
                            onChanged: (v) {},
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildSwitchTile(
                            icon: Icons.campaign_outlined,
                            title: 'Notifikasi Aplikasi',
                            subtitle: 'Info pembaruan & pengumuman penting',
                            value: false,
                            onChanged: (v) {},
                          ),
                        ]),

                        const SizedBox(height: 20),

                        // ── Bagian Tampilan ───────────────────────────────
                        _buildSectionHeader('Tampilan'),
                        _buildSettingsCard(children: [
                          _buildNavTile(
                            icon: Icons.language_outlined,
                            title: 'Bahasa',
                            trailing: 'Indonesia',
                            onTap: () {},
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildNavTile(
                            icon: Icons.color_lens_outlined,
                            title: 'Tema',
                            trailing: 'Terang',
                            onTap: () {},
                          ),
                        ]),

                        const SizedBox(height: 20),

                        // ── Bagian Keamanan Akun ──────────────────────────
                        _buildSectionHeader('Akun & Keamanan'),
                        _buildSettingsCard(children: [
                          _buildNavTile(
                            icon: Icons.lock_outline_rounded,
                            title: 'Ubah Kata Sandi',
                            onTap: () async {
                              final user = authService.currentUser;
                              if (user?.email == null) return;
                              setState(() => _isLoading = true);
                              try {
                                await authService.sendPasswordReset(email: user!.email!);
                                setState(() => _isLoading = false);
                                if (mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: Text('Email Terkirim ✅'),
                                      content: Text('Link reset sandi telah dikirim ke ${user.email}. Cek kotak masuk kamu.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text('OK', style: TextStyle(color: AppColors.primaryPurple)),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() => _isLoading = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildNavTile(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Kebijakan Privasi',
                            onTap: () {},
                          ),
                        ]),

                        const SizedBox(height: 20),

                        // ── Bagian Zona Bahaya ────────────────────────────
                        _buildSectionHeader('Zona Bahaya', color: Colors.red.shade700),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.shade100, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.delete_forever_rounded, color: Colors.red, size: 22),
                            ),
                            title: Text(
                              'Hapus Akun',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              'Hapus akun dan semua data secara permanen',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            trailing: Icon(Icons.chevron_right_rounded, color: Colors.red),
                            onTap: _deleteAccount,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color ?? AppColors.primaryPurple,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryPurple.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primaryPurple, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Switch(
        value: value,
        activeColor: AppColors.primaryPurple,
        activeTrackColor: AppColors.primaryPurple.withOpacity(0.3),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryPurple.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primaryPurple, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) ...[
            Text(trailing, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(width: 4),
          ],
          Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}
