import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'notificacion_local_service.dart';

class TecnicoWebSocketService {
  static TecnicoWebSocketService? _instance;
  WebSocketChannel? _channel;
  StreamController<NotificacionPush>? _notificationController;
  int? _tecnicoId;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  final NotificacionLocalService _notifLocal = NotificacionLocalService();

  factory TecnicoWebSocketService() {
    _instance ??= TecnicoWebSocketService._internal();
    return _instance!;
  }

  TecnicoWebSocketService._internal();

  Stream<NotificacionPush> get notificationStream {
    _notificationController ??= StreamController<NotificacionPush>.broadcast();
    return _notificationController!.stream;
  }

  bool get isConnected => _isConnected;

  Future<void> connect(int tecnicoId, String token) async {
    if (_isConnected && _tecnicoId == tecnicoId) return;
    
    _tecnicoId = tecnicoId;
    await _connectWebSocket(token);
  }

  Future<void> _connectWebSocket(String token) async {
    try {
      final uri = Uri.parse('${ApiConfig.wsUrl}?tecnico_id=$_tecnicoId');
      _channel = WebSocketChannel.connect(uri);
      
      _channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data);
            _handleMessage(message);
          } catch (e) {
            debugPrint('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          _isConnected = false;
          _scheduleReconnect();
        },
      );

      _channel!.sink.add(jsonEncode({
        'type': 'subscribe_tecnico',
        'tecnico_id': _tecnicoId,
      }));

      _isConnected = true;
      _startPingTimer();
    } catch (e) {
      debugPrint('Error connecting to WebSocket: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void _handleMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    debugPrint('WebSocket message received: $type');
    
    String titulo = 'Notificación';
    final incidenteId = message['incidente_id'] as int? ?? 0;
    final mensaje = message['mensaje'] ?? '';

    switch (type) {
      case 'nuevo_incidente_asignado':
        titulo = 'Nuevo incidente asignado';
        _notifLocal.mostrarNotificacion(
          id: incidenteId + 100000,
          titulo: titulo,
          cuerpo: mensaje,
        );
        break;
      case 'incidente_cancelado':
        titulo = 'Incidente cancelado';
        _notifLocal.mostrarNotificacion(
          id: incidenteId + 200000,
          titulo: titulo,
          cuerpo: mensaje,
        );
        break;
      case 'cambio_estado':
        final nuevoEstado = message['estado'] ?? '';
        debugPrint('Cambio de estado: $nuevoEstado');
        break;
      default:
        debugPrint('Unknown message type: $type');
    }

    final notificacion = NotificacionPush(
      type: type ?? 'unknown',
      titulo: titulo,
      mensaje: mensaje,
      data: message,
    );

    _notificationController?.add(notificacion);
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({'type': 'ping'}));
        } catch (e) {
          debugPrint('Error sending ping: $e');
        }
      }
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_tecnicoId != null && !_isConnected) {
        _connectWebSocket('');
      }
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _tecnicoId = null;
  }
}

class NotificacionPush {
  final String type;
  final String titulo;
  final String mensaje;
  final Map<String, dynamic> data;

  NotificacionPush({
    required this.type,
    required this.titulo,
    required this.mensaje,
    required this.data,
  });
}