import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';
import 'auth_service.dart';
import 'notificacion_local_service.dart';

class NotificacionPush {
  final String type;
  final String titulo;
  final String mensaje;
  final Map<String, dynamic>? data;

  NotificacionPush({
    required this.type,
    required this.titulo,
    required this.mensaje,
    this.data,
  });
}

class ClienteNotificacionService {
  static ClienteNotificacionService? _instance;
  WebSocketChannel? _socket;
  StreamSubscription? _socketSubscription;
  final _controller = StreamController<NotificacionPush>.broadcast();
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _isConnecting = false;
  int _retryCount = 0;
  static const int _maxRetries = 5;

  factory ClienteNotificacionService() {
    _instance ??= ClienteNotificacionService._internal();
    return _instance!;
  }

  ClienteNotificacionService._internal();

  Stream<NotificacionPush> get onNotificacion => _controller.stream;

  Future<void> connect() async {
    if (_isConnecting) return;

    final user = await AuthService.getCurrentUser();
    if (user == null) return;

    _isConnecting = true;

    try {
      final uri = Uri.parse('${ApiConfig.wsUrlFinal}?cliente_id=${user.id}');
      _socket = IOWebSocketChannel.connect(uri);

      await _socket!.ready;

      _socketSubscription = _socket!.stream.listen(
        (data) {
          try {
            if (data is String) {
              final message = jsonDecode(data);
              _handleMessage(message);
            }
          } catch (e) {
            debugPrint('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _isConnecting = false;
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          _isConnecting = false;
          _scheduleReconnect();
        },
      );

      _socket!.sink.add(jsonEncode({'type': 'subscribe_cliente', 'cliente_id': user.id}));

      _startPingTimer();
      _retryCount = 0;
    } catch (e) {
      debugPrint('Error connecting to WebSocket: $e');
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void _handleMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    
    if (type == 'ping' || type == 'pong' || type == null) {
      return;
    }
    
    String titulo = 'Notificación';
    String mensaje = message['mensaje'] ?? '';
    final incidenteId = message['incidente_id'] as int? ?? 0;
    final notifLocal = NotificacionLocalService();

    switch (type) {
      case 'taller_rechazo':
        titulo = 'Taller no disponible';
        notifLocal.mostrarNotificacionRechazo(
          incidenteId: incidenteId,
          mensaje: mensaje,
        );
        break;
      case 'taller_expirado':
        titulo = 'Tiempo de espera agotado';
        notifLocal.mostrarNotificacion(
          id: incidenteId + 20000,
          titulo: titulo,
          cuerpo: mensaje,
        );
        break;
      case 'sin_talleres':
        titulo = 'Sin talleres disponibles';
        notifLocal.mostrarNotificacion(
          id: incidenteId + 50000,
          titulo: titulo,
          cuerpo: mensaje,
        );
        break;
      case 'incidente_asignado':
        titulo = 'Taller encontrado';
        final tallerNombre = message['taller_nombre'] ?? 'un taller';
        notifLocal.mostrarNotificacionAsignado(
          incidenteId: incidenteId,
          tallerNombre: tallerNombre,
        );
        break;
      case 'cambio_estado':
        titulo = 'Estado actualizado';
        final nuevoEstado = message['estado'] ?? '';
        notifLocal.mostrarNotificacionCambioEstado(
          incidenteId: incidenteId,
          nuevoEstado: nuevoEstado,
        );
        break;
      case 'analisis_ia_completo':
        titulo = 'Análisis completado';
        final especialidad = message['especialidad_ia'] ?? '';
        notifLocal.mostrarNotificacionAnalisis(
          incidenteId: incidenteId,
          especialidad: especialidad,
        );
        break;
      case 'requiere_mas_evidencia':
        titulo = 'Información requerida';
        final mensajeSolicitud = message['mensaje_solicitud'] ?? message['mensaje'] ?? 'Necesitamos más información sobre tu incidente';
        notifLocal.mostrarNotificacion(
          id: incidenteId + 60000,
          titulo: titulo,
          cuerpo: mensajeSolicitud,
          payload: 'requiere_info_$incidenteId',
        );
        break;
      default:
        return;
    }

    final notificacion = NotificacionPush(
      type: type,
      titulo: titulo,
      mensaje: mensaje,
      data: message,
    );

    _controller.add(notificacion);
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_socket != null) {
        try {
          _socket!.sink.add(jsonEncode({'type': 'ping'}));
        } catch (e) {
          debugPrint('Error sending ping: $e');
        }
      }
    });
  }

  void _scheduleReconnect() {
    if (_retryCount >= _maxRetries) return;

_reconnectTimer?.cancel();
    final delaySeconds = (5 * (_retryCount + 1)).clamp(5, 30);
    final delay = Duration(seconds: delaySeconds);
    _retryCount++;

    _reconnectTimer = Timer(delay, () {
      connect();
    });
  }

  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _socketSubscription?.cancel();
    _socket?.sink.close();
    _socket = null;
    _isConnecting = false;
    _retryCount = 0;
  }
}