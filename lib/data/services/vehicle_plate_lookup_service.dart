import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

class VehiclePlateInfo {
  final String plate;
  final String? brand;
  final String? model;
  final String? color;
  final String? year;
  final String? renavam;

  const VehiclePlateInfo({
    required this.plate,
    this.brand,
    this.model,
    this.color,
    this.year,
    this.renavam,
  });
}

class VehiclePlateLookupResult {
  final bool success;
  final VehiclePlateInfo? data;
  final String? error;

  const VehiclePlateLookupResult._({
    required this.success,
    this.data,
    this.error,
  });

  factory VehiclePlateLookupResult.ok(VehiclePlateInfo data) =>
      VehiclePlateLookupResult._(success: true, data: data);

  factory VehiclePlateLookupResult.fail(String message) =>
      VehiclePlateLookupResult._(success: false, error: message);
}

class VehiclePlateLookupService {
  static const String _fallbackToken = '057de178a8dae878d0be02055a8ec978';

  String _sanitizePlate(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
  }

  String? _readText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  bool _isApiError(dynamic raw) {
    if (raw == null) return false;
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    final text = raw.toString().trim().toLowerCase();
    return text == 'true' || text == '1';
  }

  Future<VehiclePlateLookupResult> lookup(String plateInput) async {
    final cleanPlate = _sanitizePlate(plateInput);
    if (cleanPlate.length != 7) {
      return VehiclePlateLookupResult.fail(
        'Placa inválida. Deve conter 7 caracteres.',
      );
    }

    final token =
        (dotenv.env['WDAPI_TOKEN'] ?? dotenv.env['VEHICLE_PLATE_API_TOKEN'])
                ?.trim()
                .isNotEmpty ==
            true
        ? (dotenv.env['WDAPI_TOKEN'] ?? dotenv.env['VEHICLE_PLATE_API_TOKEN'])!
              .trim()
        : _fallbackToken;

    if (token.isEmpty) {
      return VehiclePlateLookupResult.fail(
        'Token de consulta de placa não configurado.',
      );
    }

    final url = Uri.parse('https://wdapi2.com.br/consulta/$cleanPlate/$token');

    try {
      final response = await http.get(url).timeout(AppConstants.queryTimeout);
      final payload = jsonDecode(response.body);

      if (payload is! Map<String, dynamic>) {
        return VehiclePlateLookupResult.fail(
          'Resposta inválida da consulta de placa.',
        );
      }

      if (_isApiError(payload['error']) || _isApiError(payload['erro'])) {
        return VehiclePlateLookupResult.fail(
          _readText(payload['message']) ??
              'Veículo não encontrado na base de dados.',
        );
      }

      final year = _readText(payload['ano']);
      final yearModel = _readText(payload['anoModelo']);
      final formattedYear = (year != null && yearModel != null)
          ? '$year/$yearModel'
          : (year ?? yearModel);

      return VehiclePlateLookupResult.ok(
        VehiclePlateInfo(
          plate: _readText(payload['placa']) ?? cleanPlate,
          brand: _readText(payload['marca']),
          model: _readText(payload['modelo']),
          color: _readText(payload['cor']),
          year: formattedYear,
          renavam: _readText(payload['renavam']),
        ),
      );
    } catch (_) {
      return VehiclePlateLookupResult.fail(
        'Erro de conexão ao consultar placa.',
      );
    }
  }
}

final vehiclePlateLookupServiceProvider = Provider<VehiclePlateLookupService>(
  (ref) => VehiclePlateLookupService(),
);
