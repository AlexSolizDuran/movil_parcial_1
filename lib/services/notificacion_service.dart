import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'api_service.dart';

class NotificacionService {
  static final NotificacionService _instance = NotificacionService._internal();
  factory NotificacionService() => _instance;
  NotificacionService._internal();

  final _controladorStream = StreamController<Notificacion>.broadcast();
  Stream<Notificacion> get onNotificacion => _controladorStream.stream;

  Timer? _pollingTimer;
  int? _ultimoIncidenteId;
  String? _ultimoEstado;

  Future<Map<String, String>> get _headers async {
    final token = await ApiService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  void iniciarEscucha() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _verificarCambios();
    });
    _verificarCambios();
  }

  void detenerEscucha() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _verificarCambios() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse(ApiConfig.incidenteEnCursoUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['tiene_incidente'] == true) {
          final incidente = data['incidente'];
          final incidenteId = incidente['id'];
          final estado = incidente['estado'];

          if (_ultimoIncidenteId != null &&
              _ultimoIncidenteId == incidenteId &&
              _ultimoEstado != estado) {
            _controladorStream.add(
              Notificacion(
                tipo: 'cambio_estado',
                titulo: 'Estado actualizado',
                cuerpo: 'El incidente ahora está: ${_getLabelEstado(estado)}',
                data: data,
              ),
            );
          }

          if (_ultimoIncidenteId == null && incidenteId != null) {
            _controladorStream.add(
              Notificacion(
                tipo: 'nuevo_incidente',
                titulo: 'Técnico asignado',
                cuerpo: 'Un técnico ha aceptado tu solicitud de asistencia',
                data: data,
              ),
            );
          }

          _ultimoIncidenteId = incidenteId;
          _ultimoEstado = estado;
        }
      }
    } catch (e) {
      debugPrint('Error en polling de notificaciones: $e');
    }
  }

  String _getLabelEstado(String estado) {
    switch (estado) {
      case 'asignado':
        return 'asignado';
      case 'en_camino':
        return 'en camino';
      case 'en_sitio':
        return 'en taller';
      case 'finalizado':
        return 'finalizado';
      default:
        return estado;
    }
  }
}

class Notificacion {
  final String tipo;
  final String titulo;
  final String cuerpo;
  final Map<String, dynamic> data;

  Notificacion({
    required this.tipo,
    required this.titulo,
    required this.cuerpo,
    required this.data,
  });
}
