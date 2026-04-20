import 'dart:convert';
import '../config/api_config.dart';
import '../models/vehiculo.dart';
import 'api_service.dart';

class VehiculoService {
  static Future<List<Vehiculo>> getMisVehiculos() async {
    try {
      final response = await ApiService.get(ApiConfig.misVehiculosUrl, withAuth: true);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Vehiculo.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Vehiculo?> getVehiculo(int id) async {
    try {
      final response = await ApiService.get(ApiConfig.vehiculoUrl(id), withAuth: true);
      
      if (response.statusCode == 200) {
        return Vehiculo.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> crearVehiculo(VehiculoCreate vehiculo) async {
    try {
      final response = await ApiService.post(
        ApiConfig.vehiculosUrl,
        vehiculo.toJson(),
        withAuth: true,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': Vehiculo.fromJson(jsonDecode(response.body))};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['detail'] ?? 'Error al crear vehículo'};
      }
    } catch (e) {
      return {'success': false, 'error': 'No se pudo conectar al servidor'};
    }
  }

  static Future<Map<String, dynamic>> actualizarVehiculo(int id, VehiculoUpdate vehiculo) async {
    try {
      final response = await ApiService.put(
        ApiConfig.vehiculoUrl(id),
        vehiculo.toJson(),
        withAuth: true,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': Vehiculo.fromJson(jsonDecode(response.body))};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['detail'] ?? 'Error al actualizar vehículo'};
      }
    } catch (e) {
      return {'success': false, 'error': 'No se pudo conectar al servidor'};
    }
  }

  static Future<Map<String, dynamic>> eliminarVehiculo(int id) async {
    try {
      final response = await ApiService.delete(
        ApiConfig.vehiculoUrl(id),
        withAuth: true,
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['detail'] ?? 'Error al eliminar vehículo'};
      }
    } catch (e) {
      return {'success': false, 'error': 'No se pudo conectar al servidor'};
    }
  }
}
