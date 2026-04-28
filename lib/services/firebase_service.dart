import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_service.dart';
import 'notificacion_local_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late final FirebaseMessaging _messaging;
  final NotificacionLocalService _notifLocal = NotificacionLocalService();

  Future<void> inicializar() async {
    try {
      if (kDebugMode) {
        print('Inicializando Firebase...');
      }
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;
      await configurarFirebaseMessaging();
      if (kDebugMode) {
        print('Firebase inicializado correctamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase no disponible, continuando sin notificaciones push: $e');
      }
    }
  }

  Future<void> configurarFirebaseMessaging() async {
    // Solicitar permisos
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('Firebase Messaging Permission: ${settings.authorizationStatus}');
    }

    // Obtener token FCM
    final fcmToken = await _messaging.getToken();
    if (kDebugMode) {
      print('FCM Token: $fcmToken');
    }

    // Enviar token al backend si existe usuario
    await _enviarTokenAlBackend(fcmToken);

    // Configurar handler para notificaciones cuando la app está abierta
    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        print('Notificación recibida en primer plano: ${message.notification?.title}');
      }
      _mostrarNotificacionLocal(message);
    });

    // Configurar handler para notificaciones cuando la app está en segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (kDebugMode) {
        print('Notificación tocada (segundo plano): ${message.notification?.title}');
      }
    });

    // Configurar handler para notificaciones cuando la app está cerrada
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      if (kDebugMode) {
        print('Notificación tocada (app cerrada): ${message.notification?.title}');
      }
    }

    // Suscribirse a temas si es necesario
    // await _messaging.subscribeToTopic('notificaciones');
  }

  Future<void> _enviarTokenAlBackend(String? token) async {
    if (token == null || token.isEmpty) return;

    try {
      // Obtener usuario actual
      final response = await ApiService.get(ApiConfig.meUrl, withAuth: true);
      if (response.statusCode != 200) return;

      // Obtener token de acceso
      final accessToken = await ApiService.getToken();
      if (accessToken == null) return;

      final httpResponse = await http.put(
        Uri.parse('${ApiConfig.apiUrl}/usuarios/notificacion/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: jsonEncode({'fcm_token': token}),
      );

      if (httpResponse.statusCode == 200) {
        if (kDebugMode) {
          print('Token FCM enviado al backend exitosamente');
        }
      } else {
        if (kDebugMode) {
          print('Error al enviar token FCM: ${httpResponse.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al enviar token FCM al backend: $e');
      }
    }
  }

  void _mostrarNotificacionLocal(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final tipo = message.data['type'] ?? 'general';
    final incidenteId = int.tryParse(message.data['incidente_id'] ?? '0') ?? 0;

    switch (tipo) {
      case 'nuevo_incidente_asignado':
      case 'incidente_asignado':
        _notifLocal.mostrarNotificacionAsignado(
          incidenteId: incidenteId,
          tallerNombre: message.data['taller_nombre'] ?? 'Taller',
        );
        break;
      case 'analisis_ia_completo':
        _notifLocal.mostrarNotificacionAnalisis(
          incidenteId: incidenteId,
          especialidad: message.data['especialidad_ia'] ?? '',
        );
        break;
      case 'taller_rechazo':
      case 'taller_expirado':
        _notifLocal.mostrarNotificacionRechazo(
          incidenteId: incidenteId,
          mensaje: notification.body ?? 'El taller no puede atenderte',
        );
        break;
      case 'cambio_estado':
        _notifLocal.mostrarNotificacionCambioEstado(
          incidenteId: incidenteId,
          nuevoEstado: message.data['estado'] ?? '',
        );
        break;
      default:
        _notifLocal.mostrarNotificacion(
          id: DateTime.now().millisecondsSinceEpoch,
          titulo: notification.title ?? 'Notificación',
          cuerpo: notification.body ?? '',
        );
    }
  }

  Future<String?> obtenerToken() async {
    return await _messaging.getToken();
  }

  Future<void> refreshToken() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _enviarTokenAlBackend(token);
    }
  }
}