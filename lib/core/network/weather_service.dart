import 'package:dio/dio.dart';

class WeatherModel {
  final double temperature;
  final String description;
  final String icon; // kondisi: 'clear', 'clouds', 'rain', 'thunderstorm', 'snow', 'mist'
  final String cityName;
  final double feelsLike;
  final int humidity;

  WeatherModel({
    required this.temperature,
    required this.description,
    required this.icon,
    required this.cityName,
    required this.feelsLike,
    required this.humidity,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;

    return WeatherModel(
      temperature: (main['temp'] as num).toDouble(),
      description: weather['description'] as String,
      icon: (weather['main'] as String).toLowerCase(), // 'Clear', 'Clouds', 'Rain', dll
      cityName: json['name'] as String,
      feelsLike: (main['feels_like'] as num).toDouble(),
      humidity: (main['humidity'] as num).toInt(),
    );
  }
}

class WeatherService {
  final Dio _dio = Dio();
  
  // ⚠️  GANTI DENGAN API KEY OPENWEATHERMAP KAMU
  static const String _apiKey = '674e5bdb6ea49c70b234c570bf96aaf8';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<WeatherModel> getWeatherByCity(String city) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'q': city,
          'appid': _apiKey,
          'units': 'metric', // Celsius
          'lang': 'id', // Deskripsi bahasa Indonesia
        },
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      return WeatherModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw 'Tidak ada koneksi internet. Menggunakan data terakhir.';
      } else if (e.response?.statusCode == 401) {
        throw 'API Key tidak valid.';
      } else if (e.response?.statusCode == 404) {
        throw 'Kota tidak ditemukan.';
      }
      throw 'Gagal mengambil data cuaca: ${e.message}';
    }
  }
}
