import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/usuario.dart';
import 'api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await ApiService.setToken(data['access_token']);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['detail'] ?? 'Error de autenticación'};
      }
    } catch (e) {
      return {'success': false, 'error': 'No se pudo conectar al servidor'};
    }
  }

  static Future<Map<String, dynamic>> register(UsuarioRegister usuario) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(usuario.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['detail'] ?? 'Error al registrar'};
      }
    } catch (e) {
      return {'success': false, 'error': 'No se pudo conectar al servidor'};
    }
  }

  static Future<Usuario?> getCurrentUser() async {
    try {
      final response = await ApiService.get(ApiConfig.meUrl, withAuth: true);
      
      if (response.statusCode == 200) {
        return Usuario.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateProfile(int usuarioId, UsuarioUpdate data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.usuariosUrl}/$usuarioId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data.toJson()),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': Usuario.fromJson(jsonDecode(response.body))};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['detail'] ?? 'Error al actualizar'};
      }
    } catch (e) {
      return {'success': false, 'error': 'No se pudo conectar al servidor'};
    }
  }

  static Future<void> logout() async {
    await ApiService.clearToken();
  }
}
