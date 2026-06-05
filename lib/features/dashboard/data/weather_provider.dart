import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/weather_service.dart';
import '../../../core/database/database_provider.dart';

// Provider untuk instance WeatherService
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

// State class untuk menyimpan data cuaca + status loading/error
class WeatherState {
  final WeatherModel? data;
  final bool isLoading;
  final String? error;

  const WeatherState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  WeatherState copyWith({
    WeatherModel? data,
    bool? isLoading,
    String? error,
  }) {
    return WeatherState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// ViewModel (Notifier) untuk cuaca
class WeatherNotifier extends Notifier<WeatherState> {
  @override
  WeatherState build() {
    // Langsung fetch saat pertama kali dibuat
    Future.microtask(() => fetchWeather());
    return const WeatherState();
  }

  Future<void> fetchWeather({String? customCity}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      // Baca kota dari memori lokal, kalau kosong default ke 'Jakarta'
      final city = customCity ?? prefs.getString('weather_city') ?? 'Jakarta';

      final service = ref.read(weatherServiceProvider);
      final weather = await service.getWeatherByCity(city);
      state = state.copyWith(data: weather, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // Fungsi untuk mengganti dan menyimpan kota permanen
  Future<void> setCity(String newCity) async {
    if (newCity.trim().isEmpty) return;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('weather_city', newCity.trim());
    await fetchWeather(customCity: newCity.trim());
  }
}

// Provider utama yang digunakan oleh UI
final weatherProvider = NotifierProvider<WeatherNotifier, WeatherState>(() {
  return WeatherNotifier();
});
