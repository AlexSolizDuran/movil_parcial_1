import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/incidente.dart';
import 'api_service.dart';

class IncidenteService {
  Future<Map<String, String>> get _headers async {
    final token = await ApiService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Incidente>> obtenerMisIncidentes() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse(ApiConfig.misIncidentesUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Incidente.fromJson(json)).toList();
      } else {
        print("CUERPO DEL ERROR 422: ${response.body}");
        throw Exception('Error al obtener incidentes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>?> obtenerIncidenteEnCurso() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse(ApiConfig.incidenteEnCursoUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<Incidente> obtenerIncidente(int id) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse(ApiConfig.incidentesDetailUrl(id)),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Incidente.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al obtener incidente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<IncidenteCompleto> obtenerEstadisticas(int id) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse(ApiConfig.incidenteEstadisticasUrl(id)),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return IncidenteCompleto.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Error al obtener estadísticas: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Incidente> crearIncidente({
    required int clienteId,
    int? vehiculoId,
    required double lat,
    required double lng,
    String? descripcion,
  }) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse(ApiConfig.incidentesUrl),
        headers: headers,
        body: json.encode({
          'cliente_id': clienteId,
          'vehiculo_id': vehiculoId,
          'ubicacion_lat': lat,
          'ubicacion_lng': lng,
          'descripcion_original': descripcion,
        }),
      );

      if (response.statusCode == 200) {
        return Incidente.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al crear incidente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Evidencia> subirEvidencia({
    required int incidenteId,
    File? archivo,
    required String tipo,
    String? contenido,
  }) async {
    try {
      final token = await ApiService.getToken();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.incidenteEvidenciasUrl(incidenteId)),
      );

      request.headers['Authorization'] = 'Bearer $token';

      if (archivo != null) {
        request.files.add(
          await http.MultipartFile.fromPath('archivo', archivo.path),
        );
      }

      request.fields['tipo'] = tipo;

      if (contenido != null) {
        request.fields['contenido'] = contenido;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return Evidencia.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al subir evidencia: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> analizarIncidente(int incidenteId) async {
    try {
      final headers = await _headers;
      final response = await http.put(
        Uri.parse(ApiConfig.incidenteAnalizarUrl(incidenteId)),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al analizar incidente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> asignarIncidente(int incidenteId, int tallerId) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse(ApiConfig.incidenteAsignarUrl(incidenteId)),
        headers: headers,
        body: json.encode({'taller_id': tallerId}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al asignar incidente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<HistoriaIncidente>> obtenerHistorial(int incidenteId) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse(ApiConfig.incidenteHistorialUrl(incidenteId)),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => HistoriaIncidente.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener historial: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> procesarPago({
    required String numeroTarjeta,
    required String cvv,
    required String expira,
    required double monto,
    required String email,
    required String nombreTitular,
    int? asignacionId,
  }) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse(ApiConfig.pagosProcesarUrl),
        headers: headers,
        body: json.encode({
          'numero_tarjeta': numeroTarjeta,
          'cvv': cvv,
          'expira': expira,
          'monto': monto,
          'email': email,
          'nombre_titular': nombreTitular,
          'asignacion_id': asignacionId,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al procesar pago: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
