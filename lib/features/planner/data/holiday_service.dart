import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../domain/models/note_model.dart';

class HolidayService {
  final Dio _dio = Dio();

  Future<List<NoteModel>> fetchIndonesianHolidays(int year) async {
    try {
      final response = await _dio.get('https://date.nager.at/api/v3/PublicHolidays/$year/ID');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) {
          final dateString = json['date'] as String;
          final name = json['localName'] as String;
          
          return NoteModel(
            title: name,
            date: DateTime.parse(dateString),
            category: 'Semua', // Kategori default
            type: 'holiday',
            isCompleted: false,
          );
        }).toList();
      }
    } catch (e) {
      // Abaikan error jaringan agar tidak merusak app
      debugPrint('Gagal mengambil tanggal merah: $e');
    }
    return [];
  }
}
