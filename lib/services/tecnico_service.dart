import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/incidente_tecnico.dart';
import 'api_service.dart';

class TecnicoService {
  static Future<IncidenteTecnicoResponse?> getMiIncidente() async {
    try {
      final response = await ApiService.get(
        ApiConfig.tecnicoIncidenteUrl,
        withAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return IncidenteTecnicoResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> actualizarEstado(
    int tecnicoId,
    String nuevoEstado,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.tecnicoActualizarEstadoUrl(tecnicoId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await ApiService.getToken()}',
        },
        body: jsonEncode({'estado': nuevoEstado}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['detail'] ?? 'Error al actualizar estado',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'No se pudo conectar al servidor'};
    }
  }

  static Future<Map<String, dynamic>> actualizarUbicacion(
    int tecnicoId,
    double lat,
    double lng,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.tecnicoActualizarUbicacionUrl(tecnicoId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await ApiService.getToken()}',
        },
        body: jsonEncode({'lat': lat, 'lng': lng}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['detail'] ?? 'Error al actualizar ubicación',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'No se pudo conectar al servidor'};
    }
  }

  static Future<Map<String, dynamic>> toggleDisponibilidad(
    int tecnicoId,
    bool disponible, {
    double? lat,
    double? lng,
  }) async {
    print(lat);
    print(lng);
    try {
      final Map<String, dynamic> body = {'disponible': disponible};
      if (lat != null && lng != null) {
        body['ubicacion_lat'] = lat;
        body['ubicacion_lng'] = lng;
      }

      final response = await http.put(
        Uri.parse(ApiConfig.tecnicoDisponibilidadUrl(tecnicoId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await ApiService.getToken()}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['detail'] ?? 'Error al actualizar disponibilidad',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'No se pudo conectar al servidor'};
    }
  }

  static Future<List<dynamic>> getHistorial() async {
    try {
      final response = await ApiService.get(
        ApiConfig.tecnicoHistorialUrl,
        withAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> crearPagoYFinalizar(
    int incidenteId,
    double monto,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.pagosTecnicoCrearUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await ApiService.getToken()}',
        },
        body: jsonEncode({
          'monto': monto,
          'incidente_id': incidenteId,
          'finalizar': true,
        }),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['detail'] ?? 'Error al crear pago',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'No se pudo conectar al servidor'};
    }
  }
}
