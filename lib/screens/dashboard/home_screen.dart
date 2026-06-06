import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../services/auth_service.dart';
import '../../features/dashboard/data/weather_provider.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import 'widgets/home_carousel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final authService = AuthService();

  /// Mengembalikan ikon Material berdasarkan kondisi cuaca dari OpenWeatherMap
  IconData _getWeatherIcon(String condition) {
    switch (condition) {
      case 'clear':
        return Icons.wb_sunny_rounded;
      case 'clouds':
        return Icons.cloud_rounded;
      case 'rain':
      case 'drizzle':
        return Icons.umbrella_rounded;
      case 'thunderstorm':
        return Icons.flash_on_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      case 'mist':
      case 'haze':
      case 'fog':
        return Icons.water_rounded;
      default:
        return Icons.cloud_outlined;
    }
  }

  Color _getWeatherIconColor(String condition) {
    switch (condition) {
      case 'clear':
        return Colors.orange;
      case 'rain':
      case 'drizzle':
        return Colors.blue;
      case 'thunderstorm':
        return Colors.deepPurple;
      case 'snow':
        return Colors.lightBlue;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildThemeToggle(AppThemeMode current, ThemeNotifier notifier) {
    const modes = [AppThemeMode.light, AppThemeMode.dark, AppThemeMode.auto];
    const icons = [
      Icons.light_mode_rounded,
      Icons.dark_mode_rounded,
      Icons.brightness_auto_rounded,
    ];
    final idx = modes.indexOf(current);

    const double toggleHeight = 44;
    const double toggleWidth = 120;
    const double thumbSize = 36;
    const double padding = 4;
    final double step = (toggleWidth - thumbSize - padding * 2) / 2;

    return SizedBox(
      width: toggleWidth,
      height: toggleHeight,
      child: GestureDetector(
        onTap: () => notifier.setMode(modes[(idx + 1) % 3]),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withOpacity(0.15),
            borderRadius: BorderRadius.circular(toggleHeight / 2),
            border: Border.all(
              color: AppColors.primaryPurple.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Icons background (tap targets)
              Row(
                children: List.generate(3, (i) {
                  final selected = i == idx;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => notifier.setMode(modes[i]),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Icon(
                          icons[i],
                          size: 16,
                          color: selected
                              ? Colors.transparent // hidden behind thumb
                              : AppColors.primaryPurple.withOpacity(0.5),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              // Sliding white thumb with icon
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: padding + idx * step,
                top: (toggleHeight - thumbSize) / 2,
                child: Container(
                  width: thumbSize,
                  height: thumbSize,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icons[idx],
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherBadge() {
    final weatherState = ref.watch(weatherProvider);

    // Saat loading
    if (weatherState.isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const SizedBox(
          width: 60,
          height: 20,
          child: Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    // Saat error (tidak ada internet / API key salah)
    if (weatherState.error != null || weatherState.data == null) {
      return GestureDetector(
        onTap: () => ref.read(weatherProvider.notifier).fetchWeather(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.grey, size: 16),
              SizedBox(width: 4),
              Text('Offline', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    // Saat data cuaca berhasil dimuat
    final weather = weatherState.data!;
    return GestureDetector(
      onTap: () => ref.read(weatherProvider.notifier).fetchWeather(),
      onLongPress: () {
        // Tampilkan Pop-up untuk ganti kota
        final TextEditingController cityController = TextEditingController(text: weather.cityName);
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Ganti Kota'),
              content: TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan nama kota...',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    ref.read(weatherProvider.notifier).setCity(cityController.text);
                    Navigator.pop(context);
                  },
                  child: Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getWeatherIcon(weather.icon),
              color: _getWeatherIconColor(weather.icon),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              '${weather.temperature.toStringAsFixed(0)}°C',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    String displayName = user?.displayName ?? 'User';
    if (displayName.length > 10) {
      displayName = '${displayName.substring(0, 8)}...';
    }
    final weatherState = ref.watch(weatherProvider);
    final cityName = weatherState.data?.cityName ?? 'Jakarta';
    final profileImagePath = ref.watch(profileImageProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      endDrawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            bottomLeft: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            // ── Header Profil Premium ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      image: DecorationImage(
                      image: profileImagePath != null
                          ? (kIsWeb
                              ? NetworkImage(profileImagePath) // Di Web, path berbentuk Blob URL (bisa dibaca NetworkImage)
                              : (profileImagePath.startsWith('https://')
                                  ? NetworkImage(profileImagePath)
                                  : FileImage(File(profileImagePath)))) as ImageProvider
                          : const NetworkImage('https://i.pravatar.cc/150?img=11'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Menu Items ─────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _DrawerMenuItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Profil Saya',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  // ── Toggle Dark / Light / Auto Mode ──────────────────
                  Consumer(
                    builder: (context, ref, _) {
                      final appMode = ref.watch(themeProvider);
                      final notifier = ref.read(themeProvider.notifier);

                      IconData icon;
                      String label;
                      if (appMode == AppThemeMode.auto) {
                        icon = Icons.brightness_auto_rounded;
                        label = 'Mode Otomatis';
                      } else if (appMode == AppThemeMode.dark) {
                        icon = Icons.dark_mode_rounded;
                        label = 'Mode Gelap';
                      } else {
                        icon = Icons.light_mode_rounded;
                        label = 'Mode Terang';
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPurple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(icon, color: AppColors.primaryPurple, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildThemeToggle(appMode, notifier),
                            if (appMode == AppThemeMode.auto)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Terang pukul 06.00–17.59  • Gelap pukul 18.00–05.59',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Tombol Logout di bawah ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text('Konfirmasi Keluar'),
                      content: Text('Apakah kamu yakin ingin keluar dari akun SaveStep?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Batal'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Keluar'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    navigator.pop(); // Tutup profil sheet/drawer
                    await authService.logout();
                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Keluar dari Akun',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.35, 1.0],
            colors: [
              const Color(0xFF8B5CF6), // Purple at top
              Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF2A2145) 
                  : const Color(0xFFD4C4FC), // Transition
              Theme.of(context).scaffoldBackgroundColor, // Background color
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang,',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          displayName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Builder(
                      builder: (context) {
                        return GestureDetector(
                          onTap: () => Scaffold.of(context).openEndDrawer(),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              color: Colors.grey.shade300,
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
                        );
                      }
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Time & Weather Widget
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA78BFA), Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final now = DateTime.now();
                            final List<String> hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
                            final List<String> bulan = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
                            
                            final dayName = hari[now.weekday - 1];
                            final dateString = "${now.day} ${bulan[now.month - 1]} ${now.year}";

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dayName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_rounded, color: Colors.white.withOpacity(0.7), size: 14),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        "$dateString • $cityName",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildWeatherBadge(),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Carousel
              const Expanded(
                child: HomeCarousel(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget menu item untuk Drawer — reusable dan elegan
class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primaryPurple, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.withOpacity(0.8), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

