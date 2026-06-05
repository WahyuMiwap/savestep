import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Hanya ambil angka
    String numbers = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.isEmpty) return newValue.copyWith(text: '');

    // Format ke currency IDR (dengan pemisah ribuan '.')
    final formatter = NumberFormat.decimalPattern('id_ID');
    final double value = double.parse(numbers);
    String newText = formatter.format(value);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
