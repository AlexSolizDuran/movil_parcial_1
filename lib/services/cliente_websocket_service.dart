import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';
import '../models/usuario.dart';

class ClienteWebSocketService {
  static ClienteWebSocketService? _instance;
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _notificationController;
  int? _clienteId;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  factory ClienteWebSocketService() {
    _instance ??= ClienteWebSocketService._internal();
    return _instance!;
  }

  ClienteWebSocketService._internal();

  Stream<Map<String, dynamic>> get notificationStream {
    _notificationController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _notificationController!.stream;
  }

  bool get isConnected => _isConnected;

  Future<void> connect(int clienteId, String token) async {
    if (_isConnected && _clienteId == clienteId) return;
    
    _clienteId = clienteId;
    await _connectWebSocket(token);
  }

  Future<void> _connectWebSocket(String token) async {
    try {
      final uri = Uri.parse('${ApiConfig.wsUrl}?cliente_id=$_clienteId');
      _channel = WebSocketChannel.connect(uri);
      
      _channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data);
            _handleMessage(message);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
          _scheduleReconnect();
        },
      );

      _channel!.sink.add(jsonEncode({
        'type': 'subscribe_cliente',
        'cliente_id': _clienteId,
      }));

      _isConnected = true;
      _startPingTimer();
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void _handleMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    print('WebSocket message received: $type');
    
    _notificationController?.add(message);
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({'type': 'ping'}));
        } catch (e) {
          print('Error sending ping: $e');
        }
      }
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_clienteId != null && !_isConnected) {
        _connectWebSocket('');
      }
    });
  }

  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _clienteId = null;
  }
}