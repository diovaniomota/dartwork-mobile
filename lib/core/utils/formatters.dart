import 'package:intl/intl.dart';

final _currencyFormat = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);

final _dateFormatBR = DateFormat('dd/MM/yyyy', 'pt_BR');
final _dateTimeFormatBR = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

String formatCurrency(num? value) {
  if (value == null) return 'R\$ 0,00';
  return _currencyFormat.format(value);
}

String formatDateBR(DateTime? date) {
  if (date == null) return 'Nao informado';
  return _dateFormatBR.format(date);
}

String formatDateTimeBR(DateTime? date) {
  if (date == null) return 'Nao informado';
  return _dateTimeFormatBR.format(date);
}

String formatDateString(String? value) {
  if (value == null || value.isEmpty) return 'Nao informado';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return 'Nao informado';
  return _dateFormatBR.format(parsed);
}

String formatCpfCnpj(String? value) {
  if (value == null) return '';
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length == 11) {
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
  }
  if (digits.length == 14) {
    return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12)}';
  }
  return value;
}

String formatPhone(String? value) {
  if (value == null) return '';
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length == 11) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
  }
  if (digits.length == 10) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
  }
  return value;
}

String formatPlate(String? value) {
  if (value == null) return '';
  final upper = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  if (upper.length == 7) {
    return '${upper.substring(0, 3)}-${upper.substring(3)}';
  }
  return value.toUpperCase();
}
