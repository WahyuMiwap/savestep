import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/database/database_provider.dart';
import 'core/notifications/notification_service.dart';
import 'core/providers/theme_provider.dart';
import 'screens/auth/splash_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await NotificationService().init();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(themeProvider); // watch STATE bukan notifier
    final hour = DateTime.now().hour;
    final ThemeMode themeMode;
    switch (appMode) {
      case AppThemeMode.light:
        themeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        themeMode = ThemeMode.dark;
        break;
      case AppThemeMode.auto:
        themeMode = (hour >= 6 && hour < 18) ? ThemeMode.light : ThemeMode.dark;
        break;
    }

    return MaterialApp(
      title: 'SaveStep',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.1),
          ),
          child: child!,
        );
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      locale: const Locale('id', 'ID'),
      themeMode: themeMode,
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F3FF),
      ),
      darkTheme: ThemeData(
        fontFamily: 'Poppins',
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
          surface: const Color(0xFF231E38), // Card color
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF141221), // Sangat dark purple
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF141221),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardColor: const Color(0xFF231E38),
        cardTheme: CardThemeData(
          color: const Color(0xFF231E38),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        dialogBackgroundColor: const Color(0xFF231E38),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF231E38),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}